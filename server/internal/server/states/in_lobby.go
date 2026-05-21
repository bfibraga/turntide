package states

import (
	"fmt"
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/core/pkg/packets"
)

type InLobby struct {
	client   server.ClientInterfacer
	lobbyReg *components.LobbyRegistry
	logger   *slog.Logger
	lobbyID  uint64
	username string
}

func NewInLobby(
	logger *slog.Logger,
	lobbyReg *components.LobbyRegistry,
	client server.ClientInterfacer,
	lobbyID uint64,
	username string,
) *InLobby {
	return &InLobby{
		logger:   logger,
		lobbyReg: lobbyReg,
		client:   client,
		lobbyID:  lobbyID,
		username: username,
	}
}

func (i *InLobby) Name() string {
	return "InLobby"
}

func (i *InLobby) SetClient(client server.ClientInterfacer) {
	i.client = client
	i.logger = i.logger.With(
		"client_id", i.client.Id(),
		"lobby_id", i.lobbyID,
	)
}

func (i *InLobby) OnEnter() {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		i.logger.Error("lobby not found on enter")
		return
	}

	var players []*packets.LobbyPlayer
	for _, p := range lobby.Players {
		players = append(players, &packets.LobbyPlayer{
			ClientId: p.ClientID,
			Username: p.Username,
			Ready:    p.Ready,
		})
	}

	i.client.SocketSend(packets.NewLobbyJoinedResponse(
		i.lobbyID,
		lobby.Name,
		lobby.HostUsername,
		players,
	))

	i.broadcastToLobby(packets.NewLobbyPlayerJoined(packets.NewLobbyPlayer(i.username, i.client.Id(), false)))
}

func (i *InLobby) HandleMessage(senderId uint64, message packets.Msg) {
	switch msg := message.(type) {
	case *packets.Packet_LobbyLeaveRequest:
		i.handleLeave(senderId)
	case *packets.Packet_LobbyReadyRequest:
		i.handleReady(senderId, msg.LobbyReadyRequest)
	case *packets.Packet_LobbyStartRequest:
		i.handleStart(senderId)
	case *packets.Packet_LobbyGameStart:
		i.handleGameStart()
	case *packets.Packet_LobbyPlayerJoined:
		// do nothing
	default:
		//i.broadcastToLobby(message)
	}
}

func (i *InLobby) handleLeave(senderId uint64) {
	_, err := i.lobbyReg.LeaveLobby(senderId)
	if err != nil {
		i.logger.Error("failed to leave lobby", "error", err)
		return
	}

	i.broadcastToLobby(packets.NewLobbyPlayerLeft(senderId))

	// Clear client state
	i.client.SetState(NewAuthenticated(i.logger, i.username, i.lobbyReg))
}

func (i *InLobby) handleReady(senderId uint64, msg *packets.LobbyReadyRequest) {
	isReady := msg.Ready

	if err := i.lobbyReg.SetReady(senderId, isReady); err != nil {
		i.logger.Error("failed to set ready", "error", err)
		return
	}

	i.broadcastToLobby(packets.NewLobbyPlayerReady(senderId, isReady))
}

func (i *InLobby) handleStart(senderId uint64) {
	if err := i.lobbyReg.StartGame(i.lobbyID, senderId); err != nil {
		i.logger.Error("failed to start game", "error", err)
		return
	}

	i.broadcastToLobby(&packets.Packet_LobbyGameStart{
		LobbyGameStart: &packets.LobbyGameStart{},
	})

	i.client.SetState(NewInGame(i.logger, i.lobbyID))
}

func (i *InLobby) handleGameStart() {
	i.client.SetState(NewInGame(i.logger, i.lobbyID))
}

func (i *InLobby) handlePlayerJoined(player *packets.LobbyPlayer) {
	msg := fmt.Sprintf("player %s joined in lobby %d", player.GetUsername(), i.lobbyID)
	i.logger.Info(msg)
}

func (i *InLobby) broadcastToLobby(msg packets.Msg) {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		return
	}

	for clientID := range lobby.Players {
		if clientID == i.client.Id() {
			continue
		}
		i.client.PassToPeer(msg, clientID)
	}
}

func (i *InLobby) OnExit() {
	if i.client == nil || i.lobbyReg == nil {
		return
	}

	if i.logger != nil {
		i.logger.Debug("exiting InLobby state")
	}

	// Ensure the client is removed from the lobby when leaving the state
	// This covers disconnections and explicit transitions away from InLobby.
	if _, err := i.lobbyReg.LeaveLobby(i.client.Id()); err != nil {
		if i.logger != nil {
			i.logger.Error("failed to leave lobby on exit", "error", err)
		}
	}
}
