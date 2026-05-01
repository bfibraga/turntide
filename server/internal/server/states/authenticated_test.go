package states

import (
	"log/slog"
	"testing"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestAuthenticatedLobbyList(t *testing.T) {
	logger := slog.Default()
	lobbyReg := components.NewLobbyRegistry()
	lobbyReg.CreateLobby(1, "host1", "Public Lobby", "1v1", 2, false, "")

	client := &mockInLobbyClient{id: 2, sentMsgs: []packets.Msg{}}
	auth := NewAuthenticated(logger, "player2", lobbyReg)
	auth.SetClient(client)

	auth.HandleMessage(2, &packets.Packet_LobbyListRequest{
		LobbyListRequest: &packets.LobbyListRequest{},
	})

	if len(client.sentMsgs) != 1 {
		t.Fatalf("expected 1 message, got %d", len(client.sentMsgs))
	}
	if _, ok := client.sentMsgs[0].(*packets.Packet_LobbyListResponse); !ok {
		t.Error("expected LobbyListResponse")
	}
}

func TestAuthenticatedCreateLobby(t *testing.T) {
	logger := slog.Default()
	lobbyReg := components.NewLobbyRegistry()

	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	auth := NewAuthenticated(logger, "host", lobbyReg)
	auth.SetClient(client)

	auth.HandleMessage(1, &packets.Packet_LobbyCreateRequest{
		LobbyCreateRequest: &packets.LobbyCreateRequest{
			Name:       "My Lobby",
			Format:     "1v1",
			MaxPlayers: 2,
			IsPrivate:  false,
		},
	})

	if client.state == nil {
		t.Fatal("expected state to be set")
	}
	if client.state.Name() != "InLobby" {
		t.Errorf("expected InLobby state, got %s", client.state.Name())
	}
}
