package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server"
)

type InGame struct {
	client server.ClientInterfacer
	logger *slog.Logger
	gameID uint64
}

func NewInGame(logger *slog.Logger, gameID uint64) *InGame {
	return &InGame{
		logger: logger,
		gameID: gameID,
	}
}

func (i *InGame) Name() string {
	return "InGame"
}

func (i *InGame) SetClient(client server.ClientInterfacer) {
	i.client = client
	i.logger = i.logger.With(
		"client_id", i.client.Id(),
		"game_id", i.gameID,
	)
}

func (i *InGame) OnEnter() {
	i.logger.Info("client entered game (stub)")
}

func (i *InGame) HandleMessage(senderId uint64, message packets.Msg) {
	i.logger.Debug("received message in InGame state (stub)", "sender_id", senderId, "message_type", message)
}

func (i *InGame) OnExit() {
	i.logger.Info("client left game (stub)")
}
