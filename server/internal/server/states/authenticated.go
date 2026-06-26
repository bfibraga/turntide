package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
)

type Authenticated struct {
	client   server.ClientInterfacer
	username string
	logger   *slog.Logger
	lobbyReg *components.LobbyRegistry
}

func NewAuthenticated(logger *slog.Logger, username string, lobbyReg *components.LobbyRegistry) *Authenticated {
	return &Authenticated{
		logger:   logger,
		username: username,
		lobbyReg: lobbyReg,
	}
}

func (a *Authenticated) Name() string {
	return "Authenticated"
}

func (a *Authenticated) SetClient(client server.ClientInterfacer) {
	a.client = client
	a.logger = a.logger.With(
		"username", a.username,
	)
}

func (a *Authenticated) OnEnter() {
	a.logger.Info("client authenticated", "username", a.username)
}

func (a *Authenticated) HandleMessage(senderId uint64, message packets.Msg) {
	a.logger.Debug("received message from authenticated client", "sender_id", senderId, "message_type", message)

	switch message := message.(type) {
	case *packets.Packet_ListLobbiesRequest:
		a.handleLobbyList(message)
	case *packets.Packet_Chat:
		a.handleChat(senderId, message)
	default:
		// Ignore other messages in authenticated state
	}
}

func (a *Authenticated) handleChat(senderId uint64, message *packets.Packet_Chat) {
	if senderId == a.client.Id() {
		a.client.Broadcast(message)
	} else {
		a.client.SocketSendAs(senderId, message)
	}
}

func (a *Authenticated) handleLobbyList(message *packets.Packet_ListLobbiesRequest) {
	request := message.ListLobbiesRequest
	options := components.NewListLobbiesOptions(int(request.Page), int(request.PageSize))

	result := a.lobbyReg.ListLobbies(options)

	var lobbyDataList []*packets.LobbyData
	for _, l := range result.Lobbies {
		lobbyDataList = append(lobbyDataList, &packets.LobbyData{
			//Id:             l.ID,
			Name:           l.Name,
			CurrentPlayers: int32(len(l.Players)),
			MaxPlayers:     int32(l.MaxPlayers),
			//Format:         l.Format,
			//CurrentPlayers: int32(l.CurrentPlayers),
			//MaxPlayers:     int32(l.MaxPlayers),
			//HostUsername:   l.HostUsername,
			//IsPrivate:      l.IsPrivate,
		})
	}

	a.client.SocketSend(packets.NewListLobbiesResponse(int32(result.Count), lobbyDataList...))
}

/*func (a *Authenticated) handleCreateLobby(senderId uint64, message *packets.Packet_LobbyCreateRequest) {
	msg := message.LobbyCreateRequest

	var password string
	if msg.Password != nil {
		password = *msg.Password
	}

	lobby := a.lobbyReg.CreateLobby(
		senderId,
		a.username,
		msg.Name,
		msg.Format,
		int(msg.MaxPlayers),
		msg.IsPrivate,
		password,
	)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, lobby.ID, a.username))
}

func (a *Authenticated) handleJoinLobby(senderId uint64, message *packets.Packet_LobbyJoinRequest) {
	msg := message.LobbyJoinRequest
	var password string
	if msg.Password != nil {
		password = *msg.Password
	}

	err := a.lobbyReg.JoinLobby(msg.LobbyId, senderId, a.username, password)
	if err != nil {
		a.logger.Error("failed to join lobby", "error", err)
		a.client.SocketSend(packets.NewDenyResponse(err.Error()))
		return
	}

	a.logger.Debug("joined lobby", "lobby_id", msg.LobbyId)

	playerPkt := packets.NewLobbyPlayer(a.client.Id(), a.username, false)
	joinPkt := packets.NewLobbyPlayerJoined(playerPkt)
	a.broadcastToLobby(senderId, joinPkt, msg.LobbyId)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, msg.LobbyId, a.username))
}*/

func (a *Authenticated) broadcastToLobby(senderId uint64, msg packets.Msg, lobbyID uint64) {
	lobby, ok := a.lobbyReg.FindLobby(lobbyID)
	if !ok {
		return
	}

	for clientID := range lobby.Players {
		if clientID == senderId {
			continue
		}
		a.client.SocketSendAs(senderId, msg)
	}
}

func (a *Authenticated) OnExit() {
	//a.logger.Info("client leaving authenticated state", "username", a.username)
}
