package components

import (
	"testing"
	"time"

	"github.com/bfibraga/turntide/server/internal/server/components"
)

func TestCreateLobby(t *testing.T) {
	reg := components.NewLobbyRegistry(time.Minute)
	lobby := reg.CreateLobby(1, "testhost", "My Lobby", "1v1", 2, false, "")

	if lobby == nil {
		t.Fatal("expected non-nil lobby")
	}
	if lobby.Name != "My Lobby" {
		t.Errorf("expected My Lobby, got %s", lobby.Name)
	}
	if lobby.HostUsername != "testhost" {
		t.Errorf("expected testhost, got %s", lobby.HostUsername)
	}
	if lobby.MaxPlayers != 2 {
		t.Errorf("expected 2, got %d", lobby.MaxPlayers)
	}
	if lobby.IsPrivate {
		t.Error("expected public lobby")
	}
	if len(lobby.Players) != 1 {
		t.Errorf("expected 1 player (host), got %d", len(lobby.Players))
	}
}

func TestListPublicLobbies(t *testing.T) {
	reg := components.NewLobbyRegistry(time.Minute)
	reg.CreateLobby(1, "host1", "Public Lobby", "1v1", 2, false, "")
	reg.CreateLobby(2, "host2", "Private Lobby", "commander", 4, true, "pass")

	lobbies := reg.ListPublicLobbies()
	if len(lobbies) != 1 {
		t.Errorf("expected 1 public lobby, got %d", len(lobbies))
	}
	if lobbies[0].Name != "Public Lobby" {
		t.Errorf("expected Public Lobby, got %s", lobbies[0].Name)
	}
}

func TestJoinLobby(t *testing.T) {
	t.Run("public lobby", func(t *testing.T) {
		reg := components.NewLobbyRegistry(time.Minute)
		lobby := reg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
		lobbyID := lobby.ID

		err := reg.JoinLobby(lobbyID, 2, "player2", "")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		lobby, _ = reg.FindLobby(lobbyID)
		if len(lobby.Players) != 2 {
			t.Errorf("expected 2 players, got %d", len(lobby.Players))
		}
	})

	t.Run("lobby full", func(t *testing.T) {
		reg := components.NewLobbyRegistry(time.Minute)
		lobby := reg.CreateLobby(1, "host", "Full", "1v1", 2, false, "")
		lobbyID := lobby.ID
		reg.JoinLobby(lobbyID, 2, "player2", "")

		err := reg.JoinLobby(lobbyID, 3, "player3", "")
		if err == nil {
			t.Error("expected error when lobby is full")
		}
	})
}

func TestJoinLobbyPassword(t *testing.T) {
	tests := []struct {
		name      string
		isPrivate bool
		password  string
		joinPass  string
		wantErr   bool
	}{
		{"private no password", true, "secret", "", true},
		{"private wrong password", true, "secret", "wrong", true},
		{"private correct password", true, "secret", "secret", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			reg := components.NewLobbyRegistry(time.Minute)
			lobby := reg.CreateLobby(1, "host", "Private", "1v1", 2, tt.isPrivate, tt.password)
			lobbyID := lobby.ID

			err := reg.JoinLobby(lobbyID, 2, "player2", tt.joinPass)
			if (err != nil) != tt.wantErr {
				t.Errorf("JoinLobby() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestLeaveLobby(t *testing.T) {
	t.Run("normal leave", func(t *testing.T) {
		reg := components.NewLobbyRegistry(time.Minute)
		lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
		lobbyID := lobby.ID
		reg.JoinLobby(lobbyID, 2, "player2", "")

		reg.LeaveLobby(2)
		lobby, _ = reg.FindLobby(lobbyID)
		if len(lobby.Players) != 1 {
			t.Errorf("expected 1 player after leave, got %d", len(lobby.Players))
		}
	})

	t.Run("removes empty lobby", func(t *testing.T) {
		reg := components.NewLobbyRegistry(time.Minute)
		lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
		lobbyID := lobby.ID

		reg.SetTTL(10 * time.Millisecond)
		reg.LeaveLobby(1)

		time.Sleep(50 * time.Millisecond)

		_, ok := reg.FindLobby(lobbyID)
		if ok {
			t.Error("expected lobby to be removed when empty")
		}
	})
}

func TestSetReady(t *testing.T) {
	reg := components.NewLobbyRegistry(time.Minute)
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")

	err := reg.SetReady(2, true)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	lobby, _ = reg.FindLobby(lobbyID)
	for _, p := range lobby.Players {
		if p.ClientID == 2 && !p.Ready {
			t.Error("expected player 2 to be ready")
		}
	}
}

func TestStartGame(t *testing.T) {
	tests := []struct {
		name     string
		starter  uint64
		setReady map[uint64]bool
		wantErr  bool
	}{
		{"not host", 2, map[uint64]bool{1: true, 2: true}, true},
		{"not all ready", 1, map[uint64]bool{1: true}, true},
		{"success", 1, map[uint64]bool{1: true, 2: true}, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			reg := components.NewLobbyRegistry(time.Minute)
			lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
			lobbyID := lobby.ID
			reg.JoinLobby(lobbyID, 2, "player2", "")

			for clientID, ready := range tt.setReady {
				reg.SetReady(clientID, ready)
			}

			err := reg.StartGame(lobbyID, tt.starter)
			if (err != nil) != tt.wantErr {
				t.Errorf("StartGame() error = %v, wantErr %v", err, tt.wantErr)
			}

			if !tt.wantErr {
				lobby, _ = reg.FindLobby(lobbyID)
				if lobby.State != components.LobbyInGame {
					t.Error("expected lobby state to be InGame")
				}
			}
		})
	}
}

func TestGetLobbyByClient(t *testing.T) {
	reg := components.NewLobbyRegistry(time.Minute)
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")

	found, ok := reg.GetLobbyByClient(2)
	if !ok {
		t.Fatal("expected to find lobby for client 2")
	}
	if found.ID != lobbyID {
		t.Errorf("expected lobby ID %d, got %d", lobbyID, found.ID)
	}
}
