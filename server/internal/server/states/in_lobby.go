package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
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
}

func (i *InLobby) OnEnter() {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		i.logger.Error("lobby not found on enter")
		return
	}

	var players []*packets.LobbyPlayerData
	for _, p := range lobby.Players {
		players = append(players, &packets.LobbyPlayerData{
			ClientId: p.ClientID,
			Username: p.Username,
			IsReady:  p.Ready,
		})
	}
}

func (i *InLobby) HandleMessage(senderId uint64, message packets.Msg) {
	/*switch message := message.(type) {
	case *packets.Packet_LobbyLeaveRequest:
		i.handleLeave(senderId)
	case *packets.Packet_LobbyReadyRequest:
		i.handleReady(senderId, message)
	case *packets.Packet_LobbyStartRequest:
		i.handleStart(senderId)
	case *packets.Packet_LobbyGameStart:
		i.handleGameStart()
	case *packets.Packet_LobbyPlayerJoined:
		i.handleLobbyPlayerJoined(senderId, message)
	case *packets.Packet_Chat:
		i.handleChat(senderId, message)
	default:
		//i.broadcastToLobby(message)
	}*/
}

/*func (i *InLobby) handleChat(senderId uint64, message *packets.Packet_Chat) {
	if senderId == i.client.Id() {
		i.broadcastToLobby(message)
	} else {
		i.client.SocketSendAs(senderId, message)
	}
}

func (i *InLobby) handleLobbyPlayerJoined(senderId uint64, message *packets.Packet_LobbyPlayerJoined) {
	if senderId == i.client.Id() {
		i.broadcastToLobby(message)
	} else {
		i.client.SocketSendAs(senderId, message)
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

func (i *InLobby) handleReady(senderId uint64, message *packets.Packet_LobbyReadyRequest) {
	msg := message.LobbyReadyRequest
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
}*/

func (i *InLobby) broadcastToLobby(msg packets.Msg) {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		return
	}

	for clientID := range lobby.Players {
		if clientID == i.client.Id() {
			continue
		}
		i.client.SocketSendAs(i.client.Id(), msg)
	}
}

func (i *InLobby) OnExit() {
	if i.client == nil || i.lobbyReg == nil {
		return
	}

	// Ensure the client is removed from the lobby when leaving the state
	// This covers disconnections and explicit transitions away from InLobby.
	//i.client.SocketSend(packets.NewLobbyLeaveRequest())
}
