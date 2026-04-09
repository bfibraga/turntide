package states

import (
	"context"
	"log/slog"
	"time"

	"github.com/bfibraga/turntide/server/internal/objects"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type InGame struct {
	client                 server.ClientInterfacer
	player                 *objects.Player
	cancelPlayerUpdateLoop context.CancelFunc
	logger                 *slog.Logger
}

func NewInGameState(logger *slog.Logger, cancelPlayerUpdateLoop context.CancelFunc) *InGame {
	return &InGame{
		logger:                 logger,
		cancelPlayerUpdateLoop: cancelPlayerUpdateLoop,
	}
}

func (g *InGame) Name() string {
	return "InGame"
}

func (g *InGame) SetClient(client server.ClientInterfacer) {
	g.client = client
	g.logger.With(
		"client_id", client.Id(),
	)
}

func (g *InGame) OnEnter() {
	g.logger.Info("Adding player %s to the shared collection", "name", g.player.Name)
	go g.client.SharedGameObjects().Players.Add(g.player)

	g.player.MouseX = 0
	g.player.MouseY = 0

	g.client.SocketSend(packets.NewPlayer(g.client.Id(), g.player))
}

func (g *InGame) HandleMessage(senderId uint64, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_Player:
		g.handlePlayer(senderId, message)
	}
}

func (g *InGame) handlePlayer(senderId uint64, message *packets.Packet_Player) {
	if senderId == g.client.Id() {
		g.logger.Debug("Received player update from own client, applying smoothing")
		g.applySmoothing(message.Player.MouseX, message.Player.MouseY)
		return
	}
	g.client.SocketSendAs(senderId, message)
}

const smoothingFactor = 0.3

func (g *InGame) applySmoothing(newMouseX, newMouseY float64) {
	g.player.MouseX = g.player.MouseX*(1-smoothingFactor) + newMouseX*smoothingFactor
	g.player.MouseY = g.player.MouseY*(1-smoothingFactor) + newMouseY*smoothingFactor

	updatePacket := packets.NewPlayer(g.client.Id(), g.player)
	g.client.Broadcast(updatePacket)
}

func (g *InGame) OnExit() {
	if g.cancelPlayerUpdateLoop != nil {
		g.cancelPlayerUpdateLoop()
	}

	g.client.SharedGameObjects().Players.Delete(g.client.Id())
}

func (g *InGame) syncPlayer(delta float64) {
	updatePacket := packets.NewPlayer(g.client.Id(), g.player)
	g.client.Broadcast(updatePacket)
	go g.client.SocketSend(updatePacket)
}

func (g *InGame) playerUpdateLoop(ctx context.Context) {
	const delta float64 = 0.05
	ticker := time.NewTicker(
		time.Duration(delta*1000) * time.Millisecond, // 50 miliseconds
	)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			g.syncPlayer(delta)
		case <-ctx.Done():
			return
		}
	}
}
