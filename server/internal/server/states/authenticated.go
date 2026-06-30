package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/objects"
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
	case *packets.Packet_CreateLobbyRequest:
		a.handleCreateLobby(senderId, message)
	case *packets.Packet_JoinLobbyRequest:
		a.handleJoinLobby(senderId, message)
	default:
		HandleMessage(a.client, senderId, message)
	}
}

func (a *Authenticated) handleLobbyList(message *packets.Packet_ListLobbiesRequest) {
	request := message.ListLobbiesRequest

	options := components.NewListLobbiesOptions(
		int(request.Page), int(request.PageSize),
		&request.Name, &request.Format, components.ConvertToLobbyState(int(request.State)),
	)

	result := a.lobbyReg.ListLobbies(options)

	/*lobbyDataList = append(lobbyDataList, &packets.LobbyData{
		//Id:             l.ID,
		Name:           l.Name,
		CurrentPlayers: int32(len(l.Players)),
		MaxPlayers:     int32(l.MaxPlayers),
		//Format:         l.Format,
		//CurrentPlayers: int32(l.CurrentPlayers),
		//MaxPlayers:     int32(l.MaxPlayers),
		//HostUsername:   l.HostUsername,
		//IsPrivate:      l.IsPrivate,
	})*/

	lobbySlice := objects.FromArrayToSharedSlice(result.Lobbies)
	lobbyDataSlice := objects.MapSlice(lobbySlice, func(i int, l *components.Lobby) *packets.LobbyData {
		return packets.NewLobbyDataBuilder().
			WithID(l.ID).
			WithName(l.Name).
			WithCurrentPlayers(int32(len(l.Players))).
			WithMaxPlayers(int32(l.MaxPlayers)).
			Build()
	})

	a.client.SocketSend(packets.NewListLobbiesResponse(
		int32(result.Count), lobbyDataSlice.Items()...,
	))
}

func (a *Authenticated) handleCreateLobby(senderId uint64, message *packets.Packet_CreateLobbyRequest) {
	request := message.CreateLobbyRequest

	/*lobby := a.lobbyReg.CreateLobby(
	senderId,
	a.username,
	request.Name,
	request.Format,
	int(request.MaxPlayers),
	request.IsPrivate,
	request.Password,
	)*/

	lobby := components.NewLobbyBuilder().
		WithHostID(senderId).
		WithHostUsername(a.username).
		WithName(request.Name).
		WithFormat(request.Format).
		WithMaxPlayers(max(int(request.MaxPlayers), 2)).
		WithIsPrivate(request.IsPrivate).
		Build()

	lobby, err := a.lobbyReg.AddLobby(lobby, request.Password)
	if err != nil {
		a.logger.Error("error on creating lobby", "error", err)
		a.client.SocketSend(packets.NewDenyResponse(err.Error()))
		return
	}

	a.logger.Info("created lobby", "lobby_id", lobby.ID)

	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, lobby.ID, a.username))
}

func (a *Authenticated) handleJoinLobby(senderId uint64, message *packets.Packet_JoinLobbyRequest) {
	request := message.JoinLobbyRequest

	err := a.lobbyReg.JoinLobby(request.LobbyId, senderId, a.username, request.Password)
	if err != nil {
		a.logger.Error("failed to join lobby", "error", err)
		a.client.SocketSend(packets.NewDenyResponse(err.Error()))
		return
	}

	a.logger.Debug("joined lobby", "lobby_id", request.LobbyId)

	playerPkt := packets.NewLobbyPlayerData(senderId, a.username, false)
	joinPkt := packets.NewPlayerJoinedResponse(playerPkt)
	a.client.BroadcastToLobby(request.LobbyId, joinPkt)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, request.LobbyId, a.username))
}

func (a *Authenticated) OnExit() {
	//a.logger.Info("client leaving authenticated state", "username", a.username)
}
