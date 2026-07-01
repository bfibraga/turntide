package states

import (
	"cmp"
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/objects"
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
		i.logger.Error("lobby not found on enter", "lobby_id", i.lobbyID)
		return
	}

	i.logger.Info("entered in lobby", "client_id", i.client.Id(), "lobby_id", i.lobbyID)

	playersSlice := objects.FromMapToSharedSlice(lobby.Players).
		Sort(func(a, b *components.LobbyPlayer) int {
			return cmp.Compare(a.Username, b.Username)
		})
	playerLobbySlice := objects.MapSlice(playersSlice, func(i int, p *components.LobbyPlayer) *packets.LobbyPlayerData {
		return packets.NewLobbyPlayerData(p.ClientID, p.Username, p.Ready)
	})

	joinPkt := packets.NewJoinedLobbyResponse(
		lobby.ID, lobby.Name, lobby.HostUsername,
		playerLobbySlice.Items(),
	)

	i.client.SocketSend(joinPkt)
	i.client.BroadcastToLobby(lobby.ID, joinPkt)
}

func (i *InLobby) HandleMessage(senderId uint64, message packets.Msg) {
	switch message := message.(type) {
	/*case *packets.Packet_LobbyLeaveRequest:
		i.handleLeave(senderId)
	case *packets.Packet_LobbyReadyRequest:
		i.handleReady(senderId, message)
	case *packets.Packet_LobbyStartRequest:
		i.handleStart(senderId)
	case *packets.Packet_LobbyGameStart:
		i.handleGameStart()*/
	case *packets.Packet_JoinedLobbyResponse:
		i.handleJoinedLobbyResponse(senderId, message)
	case *packets.Packet_LeaveLobbyRequest:
		i.handleLeaveLobbyRequest(senderId, message)
	case *packets.Packet_LeftLobbyResponse:
		i.handleLeftLobbyResponse(senderId, message)
	case *packets.Packet_Chat:
		i.handleLobbyChat(senderId, message)
	default:
		HandleMessage(i.client, senderId, message)
	}
}

func (i *InLobby) handleLobbyChat(senderId uint64, message *packets.Packet_Chat) {
	if senderId == i.client.Id() {
		i.client.BroadcastToLobby(i.lobbyID, message)
	} else {
		i.client.SocketSendAs(senderId, message)
	}
}

func (i *InLobby) handleJoinedLobbyResponse(senderId uint64, message *packets.Packet_JoinedLobbyResponse) {
	if senderId == i.client.Id() {
		i.client.BroadcastToLobby(i.lobbyID, message)
	} else {
		i.client.SocketSendAs(senderId, message)
	}
}

func (i *InLobby) handleLeaveLobbyRequest(senderId uint64, message *packets.Packet_LeaveLobbyRequest) {
	clientId := i.client.Id()

	_, err := i.lobbyReg.LeaveLobby(clientId)
	if err != nil {
		i.logger.Error("failed to leave lobby", "error", err)
		i.client.SocketSend(packets.NewDenyResponse(err.Error()))
		return
	}
	leftPkt := packets.NewLeftLobbyResponse(clientId)

	i.client.SocketSend(leftPkt)
	i.client.BroadcastToLobby(i.lobbyID, leftPkt)

	i.client.SetState(NewAuthenticated(i.logger, i.username, i.lobbyReg))
}

func (i *InLobby) handleLeftLobbyResponse(senderId uint64, message *packets.Packet_LeftLobbyResponse) {
	if senderId == i.client.Id() {
		i.client.BroadcastToLobby(i.lobbyID, message)
	} else {
		i.client.SocketSendAs(senderId, message)
	}
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

func (i *InLobby) OnExit() {
	//i.client.SocketSend(packet)
}
