package states

import (
	"context"
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/core/pkg/repository"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/lobby"
	"github.com/bfibraga/turntide/core/pkg/objects"
)

type Authenticated struct {
	client   server.ClientInterfacer
	username string
	logger   *slog.Logger
	lobbySvc *lobby.Service
}

func NewAuthenticated(logger *slog.Logger, username string, lobbySvc *lobby.Service) *Authenticated {
	return &Authenticated{
		logger:   logger,
		username: username,
		lobbySvc: lobbySvc,
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

	options := &repository.ListLobbiesOptions{
		Page:     int(request.Page),
		PageSize: int(request.PageSize),
		Name:     &request.Name,
		Format:   &request.Format,
		State:    repository.ConvertToLobbyState(int(request.State)),
	}

	result := a.lobbySvc.ListLobbies(context.Background(), options)

	lobbySlice := objects.FromArrayToSharedSlice(result.Lobbies)
	lobbyDataSlice := objects.MapSlice(lobbySlice, func(i int, l *repository.Lobby) *packets.LobbyData {
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

	lobby := &repository.Lobby{
		HostID:       senderId,
		HostUsername: a.username,
		Name:         request.Name,
		Format:       request.Format,
		MaxPlayers:   max(int(request.MaxPlayers), 2),
		IsPrivate:    request.IsPrivate,
		Players:      make(map[uint64]*repository.LobbyPlayer),
		State:        repository.LobbyWaiting,
	}

	lobby, err := a.lobbySvc.AddLobby(context.Background(), lobby, request.Password)
	if err != nil {
		a.logger.Error("error on creating lobby", "error", err)
		a.client.SocketSend(packets.NewDenyResponse(err.Error()))
		return
	}

	a.logger.Info("created lobby", "lobby_id", lobby.ID)

	a.client.SetState(NewInLobby(a.logger, a.lobbySvc, a.client, lobby.ID, a.username))
}

func (a *Authenticated) handleJoinLobby(senderId uint64, message *packets.Packet_JoinLobbyRequest) {
	request := message.JoinLobbyRequest

	err := a.lobbySvc.JoinLobby(context.Background(), request.LobbyId, senderId, a.username, request.Password)
	if err != nil {
		a.logger.Error("failed to join lobby", "error", err)
		a.client.SocketSend(packets.NewDenyResponse(err.Error()))
		return
	}

	a.logger.Debug("joined lobby", "lobby_id", request.LobbyId)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbySvc, a.client, request.LobbyId, a.username))
}

func (a *Authenticated) OnExit() {
	//a.logger.Info("client leaving authenticated state", "username", a.username)
}
