package states

import (
	"testing"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type mockInLobbyClient struct {
	id        uint64
	sentMsgs  []packets.Msg
	state     server.ClientStateHandler
}

func (m *mockInLobbyClient) Id() uint64 { return m.id }
func (m *mockInLobbyClient) ProcessPacket(senderId uint64, message packets.Msg) {}
func (m *mockInLobbyClient) Initialize(id uint64)                             {}
func (m *mockInLobbyClient) SocketSend(message packets.Msg) {
	m.sentMsgs = append(m.sentMsgs, message)
}
func (m *mockInLobbyClient) SocketSendAs(senderId uint64, message packets.Msg) {}
func (m *mockInLobbyClient) PassToPeer(message packets.Msg, peerId uint64)     {}
func (m *mockInLobbyClient) Broadcast(message packets.Msg)                    {}
func (m *mockInLobbyClient) ReadPump()                                        {}
func (m *mockInLobbyClient) WritePump()                                       {}
func (m *mockInLobbyClient) SetState(state server.ClientStateHandler) {
	m.state = state
}
func (m *mockInLobbyClient) Close() {}

func TestInLobbyOnEnter(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyReg.JoinLobby(lobby.ID, 2, "player2", "")

	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	inLobby := NewInLobby(nil, lobbyReg, client, lobby.ID, "host")

	inLobby.OnEnter()

	if len(client.sentMsgs) != 1 {
		t.Fatalf("expected 1 message, got %d", len(client.sentMsgs))
	}
	if _, ok := client.sentMsgs[0].(*packets.Packet_LobbyJoinedResponse); !ok {
		t.Error("expected LobbyJoinedResponse")
	}
}

func TestInLobbyLeave(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID

	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	inLobby := NewInLobby(nil, lobbyReg, client, lobbyID, "host")

	// Simulate leave request
	inLobby.HandleMessage(1, &packets.Packet_LobbyLeaveRequest{
		LobbyLeaveRequest: &packets.LobbyLeaveRequest{},
	})

	// Lobby should be removed (host left and it was the only player)
	_, ok := lobbyReg.FindLobby(lobbyID)
	if ok {
		t.Error("expected lobby to be removed after host leaves")
	}
}

func TestInLobbyReady(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID
	lobbyReg.JoinLobby(lobbyID, 2, "player2", "")

	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	inLobby := NewInLobby(nil, lobbyReg, client, lobbyID, "host")

	inLobby.HandleMessage(1, &packets.Packet_LobbyReadyRequest{
		LobbyReadyRequest: &packets.LobbyReadyRequest{Ready: true},
	})

	lobby, _ = lobbyReg.FindLobby(lobbyID)
	if !lobby.Players[1].Ready {
		t.Error("expected player 1 to be ready")
	}
}

func TestInLobbyGameStart(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobby := lobbyReg.CreateLobby(1, "host", "Test Lobby", "1v1", 2, false, "")
	lobbyID := lobby.ID
	lobbyReg.JoinLobby(lobbyID, 2, "player2", "")
	lobbyReg.SetReady(1, true)
	lobbyReg.SetReady(2, true)

	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	inLobby := NewInLobby(nil, lobbyReg, client, lobbyID, "host")

	// Host requests start
	inLobby.HandleMessage(1, &packets.Packet_LobbyStartRequest{
		LobbyStartRequest: &packets.LobbyStartRequest{},
	})

	// Client should transition to InGame state
	if client.state == nil {
		t.Fatal("expected state to be set")
	}
	if client.state.Name() != "InGame" {
		t.Errorf("expected InGame state, got %s", client.state.Name())
	}
}
