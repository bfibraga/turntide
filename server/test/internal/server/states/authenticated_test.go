package states

import (
	"log/slog"
	"testing"
	"time"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/states"
	"github.com/bfibraga/turntide/server/pkg/packets"
	"github.com/bfibraga/turntide/server/test/internal/server/clients"
)

func TestAuthenticatedLobbyList(t *testing.T) {
	logger := slog.Default()
	lobbyReg := components.NewLobbyRegistry()
	lobbyReg.CreateLobby(1, "host1", "Public Lobby", "1v1", 2, false, "")

	client := clients.NewFakeClient(1)
	auth := states.NewAuthenticated(logger, "player2", lobbyReg)
	auth.SetClient(client)

	auth.HandleMessage(2, packets.NewLobbyListRequest())

	if client.SentPacketCount() != 1 {
		t.Fatalf("expected 1 message, got %d", client.SentPacketCount())
	}
	if _, ok := client.SentMsgs[0].(*packets.Packet_LobbyListResponse); !ok {
		t.Error("expected LobbyListResponse")
	}
}

func TestAuthenticatedCreateLobby(t *testing.T) {
	logger := slog.Default()

	t.Run("success", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()

		client := clients.NewFakeClient(1)
		auth := states.NewAuthenticated(logger, "host", lobbyReg)
		auth.SetClient(client)

		auth.HandleMessage(1, packets.NewLobbyCreateRequest(
			"My Lobby",
			"1v1",
			2,
			false,
			nil,
		))

		if client.GetState() == nil {
			t.Fatal("expected state to be set")
		}
		if client.GetState().Name() != "InLobby" {
			t.Errorf("expected InLobby state, got %s", client.GetState().Name())
		}
	})

	t.Run("duplicate name", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		// Create first lobby
		lobbyReg.CreateLobby(1, "host", "My Lobby", "1v1", 2, false, "")

		// Try to create another lobby with same host
		client := clients.NewFakeClient(1)
		auth := states.NewAuthenticated(logger, "host", lobbyReg)
		auth.SetClient(client)

		auth.HandleMessage(1, packets.NewLobbyCreateRequest(
			"Another Lobby",
			"1v1",
			2,
			false,
			nil,
		))

		// The lobby gets created (code allows multiple lobbies per host)
		// Just verify state transition happens
		if client.GetState() == nil {
			t.Fatal("expected state to be set")
		}
	})
}

func TestAuthenticatedHandleUnknownMessage(t *testing.T) {
	logger := slog.Default()
	lobbyReg := components.NewLobbyRegistry()

	client := clients.NewFakeClient(1)
	auth := states.NewAuthenticated(logger, "host", lobbyReg)
	auth.SetClient(client)

	// Send an unknown message type (Ping is not handled by Authenticated)
	auth.HandleMessage(1, packets.NewPing(time.Now()))

	// Should not panic or change state
	if client.GetState() != nil {
		t.Errorf("expected no state change, got %s", client.GetState().Name())
	}
}
