package components

import (
	"testing"

	"github.com/bfibraga/turntide/server/pkg/packets"
)

type mockLobbyClient struct {
	id uint64
}

func (m *mockLobbyClient) Id() uint64 { return m.id }
func (m *mockLobbyClient) ProcessPacket(senderId uint64, message packets.Msg) {}
func (m *mockLobbyClient) Initialize(id uint64)                             {}
func (m *mockLobbyClient) SocketSend(message packets.Msg)                    {}
func (m *mockLobbyClient) SocketSendAs(senderId uint64, message packets.Msg) {}
func (m *mockLobbyClient) PassToPeer(message packets.Msg, peerId uint64)     {}
func (m *mockLobbyClient) Broadcast(message packets.Msg)                    {}
func (m *mockLobbyClient) ReadPump()                                        {}
func (m *mockLobbyClient) WritePump()                                       {}
func (m *mockLobbyClient) SetState(state ClientStateHandler)                {}
func (m *mockLobbyClient) Close()                                           {}

func TestCreateLobby(t *testing.T) {
	reg := NewLobbyRegistry()
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
	reg := NewLobbyRegistry()
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
	reg := NewLobbyRegistry()
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
}

func TestJoinPrivateLobbyNoPassword(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Private", "1v1", 2, true, "secret")
	lobbyID := lobby.ID

	err := reg.JoinLobby(lobbyID, 2, "player2", "")
	if err == nil {
		t.Error("expected error when joining private lobby without password")
	}
}

func TestJoinPrivateLobbyWrongPassword(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Private", "1v1", 2, true, "secret")
	lobbyID := lobby.ID

	err := reg.JoinLobby(lobbyID, 2, "player2", "wrong")
	if err == nil {
		t.Error("expected error when joining with wrong password")
	}
}

func TestJoinPrivateLobbyCorrectPassword(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Private", "1v1", 2, true, "secret")
	lobbyID := lobby.ID

	err := reg.JoinLobby(lobbyID, 2, "player2", "secret")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestLeaveLobby(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")

	reg.LeaveLobby(2)
	lobby, _ = reg.FindLobby(lobbyID)
	if len(lobby.Players) != 1 {
		t.Errorf("expected 1 player after leave, got %d", len(lobby.Players))
	}
}

func TestLeaveLobbyRemovesEmpty(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID

	reg.LeaveLobby(1)
	_, ok := reg.FindLobby(lobbyID)
	if ok {
		t.Error("expected lobby to be removed when empty")
	}
}

func TestSetReady(t *testing.T) {
	reg := NewLobbyRegistry()
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

func TestStartGameNotHost(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")
	reg.SetReady(1, true)
	reg.SetReady(2, true)

	err := reg.StartGame(lobbyID, 2) // not host
	if err == nil {
		t.Error("expected error when non-host tries to start game")
	}
}

func TestStartGameNotAllReady(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")
	reg.SetReady(1, true)
	// player2 not ready

	err := reg.StartGame(lobbyID, 1) // host
	if err == nil {
		t.Error("expected error when not all players are ready")
	}
}

func TestStartGameSuccess(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Test", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")
	reg.SetReady(1, true)
	reg.SetReady(2, true)

	err := reg.StartGame(lobbyID, 1)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	lobby, _ = reg.FindLobby(lobbyID)
	if lobby.State != LobbyInGame {
		t.Error("expected lobby state to be InGame")
	}
}

func TestGetLobbyByClient(t *testing.T) {
	reg := NewLobbyRegistry()
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

func TestLobbyFull(t *testing.T) {
	reg := NewLobbyRegistry()
	lobby := reg.CreateLobby(1, "host", "Full", "1v1", 2, false, "")
	lobbyID := lobby.ID
	reg.JoinLobby(lobbyID, 2, "player2", "")

	err := reg.JoinLobby(lobbyID, 3, "player3", "")
	if err == nil {
		t.Error("expected error when lobby is full")
	}
}
