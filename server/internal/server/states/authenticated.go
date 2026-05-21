/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
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
		"client_id", a.client.Id(),
		"username", a.username,
	)
}

func (a *Authenticated) OnEnter() {
	a.logger.Info("client authenticated", "username", a.username)
}

func (a *Authenticated) HandleMessage(senderId uint64, message packets.Msg) {
	a.logger.Debug("received message from authenticated client", "sender_id", senderId, "message_type", message)

	switch message := message.(type) {
	case *packets.Packet_LobbyListRequest:
		a.handleLobbyList()
	case *packets.Packet_LobbyCreateRequest:
		a.handleCreateLobby(senderId, message)
	case *packets.Packet_LobbyJoinRequest:
		a.handleJoinLobby(senderId, message)
	case *packets.Packet_LobbyLeaveRequest:
		// a.handleLeaveLobby(senderId, message)
	case *packets.Packet_LobbyPlayerJoined:
		// a.handleLobbyPlayerJoined(senderId, message)
	case *packets.Packet_Chat:
		// a.handleChat(senderId, message)
	default:
		// Ignore other messages in authenticated state
	}
}

func (a *Authenticated) handleLobbyList() {
	lobbies := a.lobbyReg.ListPublicLobbies()

	var lobbyInfos []*packets.LobbyInfo
	for _, l := range lobbies {
		lobbyInfos = append(lobbyInfos, &packets.LobbyInfo{
			Id:             l.ID,
			Name:           l.Name,
			Format:         l.Format,
			CurrentPlayers: int32(l.CurrentPlayers),
			MaxPlayers:     int32(l.MaxPlayers),
			HostUsername:   l.HostUsername,
			IsPrivate:      l.IsPrivate,
		})
	}

	a.client.SocketSend(packets.NewLobbyListResponse(lobbyInfos))
}

func (a *Authenticated) handleCreateLobby(senderId uint64, message *packets.Packet_LobbyCreateRequest) {
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

	playerPkt := packets.NewLobbyPlayer(a.username, senderId, false)
	joinPkt := packets.NewLobbyPlayerJoined(playerPkt)
	a.broadcastToLobby(senderId, joinPkt, msg.LobbyId)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, msg.LobbyId, a.username))
}

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
