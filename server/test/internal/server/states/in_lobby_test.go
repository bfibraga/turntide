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

func TestInLobbyOnEnter(t *testing.T) {
	t.Run("success", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
		lobbyReg.JoinLobby(lobby.ID, 2, "player2", "")

		client := clients.NewFakeClient(1)
		inLobby := states.NewInLobby(nil, lobbyReg, client, lobby.ID, "host")

		inLobby.OnEnter()

		if client.SentPacketCount() != 1 {
			t.Fatalf("expected 1 message, got %d", client.SentPacketCount())
		}
		if _, ok := client.SentMsgs[0].(*packets.Packet_LobbyJoinedResponse); !ok {
			t.Error("expected LobbyJoinedResponse")
		}
	})

	t.Run("lobby not found", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		client := clients.NewFakeClient(1)
		inLobby := states.NewInLobby(slog.Default(), lobbyReg, client, 999, "host")

		inLobby.OnEnter()

		// Should not send any messages when lobby not found
		if client.SentPacketCount() != 0 {
			t.Errorf("expected 0 messages, got %d", client.SentPacketCount())
		}
	})
}

func TestInLobbyLeave(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID

	client := clients.NewFakeClient(1)
	inLobby := states.NewInLobby(nil, lobbyReg, client, lobbyID, "host")

	// Shorten TTL for test so the lobby is removed quickly when last player leaves
	lobbyReg.SetTTL(10 * time.Millisecond)

	// Simulate leave request
	inLobby.HandleMessage(1, packets.NewLobbyLeaveRequest())

	// Wait for timer to fire and remove the empty lobby
	time.Sleep(50 * time.Millisecond)

	// Lobby should be removed (host left and it was the only player)
	_, ok := lobbyReg.FindLobby(lobbyID)
	if ok {
		t.Error("expected lobby to be removed after host leaves")
	}

	// Client should transition to Authenticated state
	if client.GetState() == nil {
		t.Fatal("expected state to be set")
	}
	if client.GetState().Name() != "Authenticated" {
		t.Errorf("expected Authenticated state, got %s", client.GetState().Name())
	}
}

func TestInLobbyLeaveError(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID

	client := clients.NewFakeClient(1)
	inLobby := states.NewInLobby(slog.Default(), lobbyReg, client, lobbyID, "host")

	// Try to leave with a different player ID (should error)
	inLobby.HandleMessage(999, packets.NewLobbyLeaveRequest())

	// Lobby should still have the original player
	lobby, ok := lobbyReg.FindLobby(lobbyID)
	if !ok {
		t.Fatal("expected lobby to still exist")
	}
	if len(lobby.Players) != 1 {
		t.Errorf("expected 1 player, got %d", len(lobby.Players))
	}
}

func TestInLobbyReady(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID
	lobbyReg.JoinLobby(lobbyID, 2, "player2", "")

	client := clients.NewFakeClient(1)
	inLobby := states.NewInLobby(nil, lobbyReg, client, lobbyID, "host")

	inLobby.HandleMessage(1, packets.NewLobbyPlayerReady(1, true))

	lobby, _ = lobbyReg.FindLobby(lobbyID)
	if !lobby.Players[1].Ready {
		t.Error("expected player 1 to be ready")
	}
}

func TestInLobbyReadyError(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID

	client := clients.NewFakeClient(1)
	inLobby := states.NewInLobby(slog.Default(), lobbyReg, client, lobbyID, "host")

	// Try to set ready for non-existent player
	inLobby.HandleMessage(999, packets.NewLobbyPlayerReady(999, true))

	// Should not change any player's ready state
	lobby, _ = lobbyReg.FindLobby(lobbyID)
	for _, p := range lobby.Players {
		if p.Ready {
			t.Error("expected no players to be ready")
		}
	}
}

func TestInLobbyStartError(t *testing.T) {
	logger := slog.Default()

	t.Run("not host", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
		lobbyID := lobby.ID
		lobbyReg.JoinLobby(lobbyID, 2, "player2", "")
		lobbyReg.SetReady(1, true)
		lobbyReg.SetReady(2, true)

		client := clients.NewFakeClient(2)
		inLobby := states.NewInLobby(logger, lobbyReg, client, lobbyID, "player2")

		inLobby.HandleMessage(2, packets.NewLobbyStartRequest())

		// Should not transition to InGame
		if client.GetState() != nil {
			t.Errorf("expected no state change, got %s", client.GetState().Name())
		}
	})

	t.Run("not all ready", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
		lobbyID := lobby.ID
		lobbyReg.JoinLobby(lobbyID, 2, "player2", "")
		lobbyReg.SetReady(1, true)
		// player2 not ready
		lobbyReg.SetReady(2, false)

		client := clients.NewFakeClient(1)
		inLobby := states.NewInLobby(slog.Default(), lobbyReg, client, lobbyID, "host")

		inLobby.HandleMessage(1, packets.NewLobbyStartRequest())

		// Should not transition to InGame
		if client.GetState() != nil {
			t.Errorf("expected no state change, got %s", client.GetState().Name())
		}
	})
}

func TestInLobbyGameStart(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID
	lobbyReg.JoinLobby(lobbyID, 2, "player2", "")
	lobbyReg.SetReady(1, true)
	lobbyReg.SetReady(2, true)

	client := clients.NewFakeClient(1)
	inLobby := states.NewInLobby(nil, lobbyReg, client, lobbyID, "host")

	// Host requests start
	inLobby.HandleMessage(1, packets.NewLobbyStartRequest())

	// Client should transition to InGame state
	if client.GetState() == nil {
		t.Fatal("expected state to be set")
	}
	if client.GetState().Name() != "InGame" {
		t.Errorf("expected InGame state, got %s", client.GetState().Name())
	}
}

func TestInLobbyOnExit(t *testing.T) {
	t.Run("nil client", func(t *testing.T) {
		// This test verifies OnExit handles nil client gracefully
		// Note: NewInLobby with nil client is not a normal scenario
		// but we test the nil check in OnExit works
		lobbyReg := components.NewLobbyRegistry()
		lobby := lobbyReg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
		lobbyID := lobby.ID

		inLobby := states.NewInLobby(slog.Default(), lobbyReg, nil, lobbyID, "host")
		inLobby.OnExit()

		// Should not panic - the nil client check is after logger.Debug
	})

	t.Run("nil lobby registry", func(t *testing.T) {
		client := clients.NewFakeClient(1)
		inLobby := states.NewInLobby(nil, nil, client, 1, "host")
		inLobby.OnExit()

		// Should not panic
	})

	t.Run("leaves lobby", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		lobby := lobbyReg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
		lobbyID := lobby.ID

		client := clients.NewFakeClient(1)
		inLobby := states.NewInLobby(nil, lobbyReg, client, lobbyID, "host")

		inLobby.OnExit()

		// Client should be removed from lobby
		lobby, ok := lobbyReg.FindLobby(lobbyID)
		if ok {
			if _, exists := lobby.Players[1]; exists {
				t.Error("expected player 1 to be removed from lobby")
			}
		}
	})
}

func TestInLobbyPlayerJoin(t *testing.T) {
	logger := slog.Default()

	t.Run("one player joining", func(t *testing.T) {
		lobbyReg := components.NewLobbyRegistry()
		lobby := lobbyReg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
		lobbyID := lobby.ID

		client := clients.NewFakeClient(2)
		inLobby := states.NewInLobby(logger, lobbyReg, client, lobbyID, "host")

		inLobby.HandleMessage(2, packets.NewLobbyPlayerJoined(
			packets.NewLobbyPlayer(
				"username",
				2,
				false,
			),
		))

		// Client should be added to lobby
		lobby, ok := lobbyReg.FindLobby(lobbyID)
		if !ok {
			t.Error("expected lobby to be found")
		}
		if _, exists := lobby.Players[2]; !exists {
			t.Error("expected player 2 to be added to lobby")
		}
	})
}
