package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type InLobby struct {
	client      server.ClientInterfacer
	lobbyReg    *components.LobbyRegistry
	logger      *slog.Logger
	lobbyID     uint64
	username    string
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

	i.client.SocketSend(&packets.Packet_LobbyJoinedResponse{
		LobbyJoinedResponse: &packets.LobbyJoinedResponse{
			LobbyId:      lobby.ID,
			LobbyName:    lobby.Name,
			HostUsername:  lobby.HostUsername,
			Players:       players,
		},
	})
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
	default:
		i.broadcastToLobby(message)
	}
}

func (i *InLobby) handleLeave(senderId uint64) {
	lobby, err := i.lobbyReg.LeaveLobby(senderId)
	if err != nil {
		i.logger.Error("failed to leave lobby", "error", err)
		return
	}

	if lobby != nil {
		i.broadcastToLobby(&packets.Packet_LobbyPlayerLeft{
			LobbyPlayerLeft: &packets.LobbyPlayerLeft{ClientId: senderId},
		})
	}

	i.client.SetState(nil)
}

func (i *InLobby) handleReady(senderId uint64, msg *packets.LobbyReadyRequest) {
	if err := i.lobbyReg.SetReady(senderId, msg.Ready); err != nil {
		i.logger.Error("failed to set ready", "error", err)
		return
	}

	i.broadcastToLobby(&packets.Packet_LobbyPlayerReady{
		LobbyPlayerReady: &packets.LobbyPlayerReady{
			ClientId: senderId,
			Ready:    msg.Ready,
		},
	})
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
	i.logger.Debug("exiting InLobby state")
}
