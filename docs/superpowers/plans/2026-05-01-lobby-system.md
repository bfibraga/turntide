# Lobby System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a lobby system with game browser, matchmaking, and lobby management for the MTG game server and client, following TDD.

**Architecture:** Add a `LobbyRegistry` component to the server, new `InLobby` and `InGame` (stub) server states, extend protobuf messages, and add `LobbyBrowser` and `InLobby` client states with scenes. The `Authenticated` state becomes a lobby browser.

**Tech Stack:** Go (server), Godot/GDScript (client), Protobuf (shared), gorilla/websocket, sqlc (SQLite), Cobra (fetcher CLI)

---

## File Structure

### New files to create

| File | Responsibility |
|------|-----------------|
| `server/internal/server/components/lobby_registry.go` | LobbyRegistry: create, join, leave, list lobbies, manage lobby state |
| `server/internal/server/components/lobby_registry_test.go` | TDD tests for LobbyRegistry |
| `server/internal/server/states/in_lobby.go` | InLobby state: handle lobby-scoped messages |
| `server/internal/server/states/in_lobby_test.go` | TDD tests for InLobby state |
| `server/internal/server/states/in_game.go` | InGame stub state |
| `server/internal/server/states/in_game_test.go` | TDD tests for InGame stub |
| `client/states/lobby/browser.gd` | LobbyBrowser client state (extends State) |
| `client/states/lobby/in_lobby.gd` | InLobby client state (extends SceneHolderState) |
| `client/tests/lobby_browser_test.gd` | Tests for LobbyBrowser state |
| `client/tests/in_lobby_test.gd` | Tests for InLobby state |
| `client/scenes/lobby_browser.tscn` | Lobby browser scene |
| `client/scenes/lobby_room.tscn` | Lobby room scene |

### Files to modify

| File | Change |
|------|--------|
| `shared/packets.proto` | Add lobby message types to Packet oneof |
| `server/internal/server/hub.go` | Add `Lobbies *components.LobbyRegistry` to Hub struct |
| `server/internal/server/states/authenticated.go` | Convert to lobby browser: handle create/join/list requests |
| `server/internal/server/states/authenticated_test.go` | Update tests for new authenticated behavior |
| `server/internal/server/clients/websocket.go` | Add `BroadcastToLobby` method |
| `client/scripts/network/packets/factory.gd` | Add lobby packet factory methods |
| `client/scripts/network/network.gd` | Add lobby packet wrapper classes |
| `client/states/scene_state_machine.gd` | Add lobby states as children (if needed) |

---

### Task 1: Extend Protobuf Messages

**Files:**
- Modify: `shared/packets.proto`

- [ ] **Step 1: Write the updated proto file**

Add the following message types and update the `Packet` oneof.

```protobuf
syntax = "proto3";

package shared;

option go_package = "/pkg/packets";

message PingMessage {
  uint64 timestamp = 1;
}

message ChatMessage {
  string msg = 1;
}

message IdMessage {
  uint64 id = 1;
}

message LoginRequestMessage {
  string username = 1;
  string password = 2;
}

message RegisterRequestMessage {
  string username = 1;
  string password = 2;
}

message OkResponseMessage {
}

message DenyResponseMessage {
  string reason = 2;
}

// Lobby messages
message LobbyCreateRequest {
  string name = 1;
  string format = 2;
  int32 max_players = 3;
  bool is_private = 4;
  optional string password = 5;
}

message LobbyJoinRequest {
  uint64 lobby_id = 1;
  optional string password = 2;
}

message LobbyLeaveRequest {}

message LobbyReadyRequest {
  bool ready = 1;
}

message LobbyStartRequest {}

message LobbyListRequest {}

message LobbyListResponse {
  repeated LobbyInfo lobbies = 1;
}

message LobbyInfo {
  uint64 id = 1;
  string name = 2;
  string format = 3;
  int32 current_players = 4;
  int32 max_players = 5;
  string host_username = 6;
  bool is_private = 7;
}

message LobbyJoinedResponse {
  uint64 lobby_id = 1;
  string lobby_name = 2;
  string host_username = 3;
  repeated LobbyPlayer players = 4;
}

message LobbyPlayer {
  uint64 client_id = 1;
  string username = 2;
  bool ready = 3;
}

message LobbyPlayerJoined {
  LobbyPlayer player = 1;
}

message LobbyPlayerLeft {
  uint64 client_id = 1;
}

message LobbyPlayerReady {
  uint64 client_id = 1;
  bool ready = 2;
}

message LobbyGameStart {}

message Packet {
  uint64 sender_id = 1;
  oneof msg {
    PingMessage ping = 2;
    ChatMessage chat = 3;
    IdMessage id = 4;
    LoginRequestMessage login_request = 5;
    RegisterRequestMessage register_request = 6;
    OkResponseMessage ok_response = 7;
    DenyResponseMessage deny_response = 8;
    // Lobby messages
    LobbyCreateRequest lobby_create_request = 9;
    LobbyJoinRequest lobby_join_request = 10;
    LobbyLeaveRequest lobby_leave_request = 11;
    LobbyReadyRequest lobby_ready_request = 12;
    LobbyStartRequest lobby_start_request = 13;
    LobbyListRequest lobby_list_request = 14;
    LobbyListResponse lobby_list_response = 15;
    LobbyJoinedResponse lobby_joined_response = 16;
    LobbyPlayerJoined lobby_player_joined = 17;
    LobbyPlayerLeft lobby_player_left = 18;
    LobbyPlayerReady lobby_player_ready = 19;
    LobbyGameStart lobby_game_start = 20;
  }
}
```

- [ ] **Step 2: Regenerate protobuf bindings**

Run: `make proto`
Expected: No errors, `server/pkg/packets/packets.pb.go` updated with new message types

- [ ] **Step 3: Commit**

```bash
git add shared/packets.proto server/pkg/packets/packets.pb.go
git commit -m "feat: add lobby message types to protobuf definitions"
```

---

### Task 2: Create LobbyRegistry Component (TDD)

**Files:**
- Create: `server/internal/server/components/lobby_registry.go`
- Create: `server/internal/server/components/lobby_registry_test.go`

- [ ] **Step 1: Write failing tests for LobbyRegistry**

```go
// server/internal/server/components/lobby_registry_test.go
package components

import (
	"sync"
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/components/ -run "TestCreateLobby|TestListPublicLobbies|TestJoinLobby|TestJoinPrivateLobbyNoPassword|TestJoinPrivateLobbyWrongPassword|TestJoinPrivateLobbyCorrectPassword|TestLeaveLobby|TestLeaveLobbyRemovesEmpty|TestSetReady|TestStartGameNotHost|TestStartGameNotAllReady|TestStartGameSuccess|TestGetLobbyByClient|TestLobbyFull" -v`
Expected: FAIL — `NewLobbyRegistry`, `CreateLobby`, etc. not defined

- [ ] **Step 3: Write minimal implementation**

```go
// server/internal/server/components/lobby_registry.go
package components

import (
	"crypto/sha256"
	"fmt"
	"sync"

	"github.com/bfibraga/turntide/server/internal/server/objects"
)

type LobbyState int

const (
	LobbyWaiting LobbyState = iota
	LobbyReady
	LobbyInGame
)

type LobbyPlayer struct {
	ClientID uint64
	Username string
	Ready    bool
}

type Lobby struct {
	ID           uint64
	Name         string
	Format       string
	MaxPlayers   int
	IsPrivate    bool
	PasswordHash string
	HostID       uint64
	HostUsername string
	Players      map[uint64]*LobbyPlayer
	State        LobbyState
}

type LobbyRegistry struct {
	lobbies      *objects.SharedCollection[*Lobby]
	clientToLobby sync.Map // map[uint64]uint64  (clientID → lobbyID)
	mu            sync.RWMutex
}

func NewLobbyRegistry() *LobbyRegistry {
	return &LobbyRegistry{
		lobbies: objects.NewSharedCollection[*Lobby](),
	}
}

func hashPassword(password string) string {
	h := sha256.Sum256([]byte(password))
	return fmt.Sprintf("%x", h)
}

func (r *LobbyRegistry) CreateLobby(hostID uint64, hostUsername, name, format string, maxPlayers int, isPrivate bool, password string) *Lobby {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby := &Lobby{
		Name:         name,
		Format:       format,
		MaxPlayers:   maxPlayers,
		IsPrivate:    isPrivate,
		HostID:       hostID,
		HostUsername: hostUsername,
		Players:      make(map[uint64]*LobbyPlayer),
		State:        LobbyWaiting,
	}

	if password != "" {
		lobby.PasswordHash = hashPassword(password)
	}

	id := r.lobbies.Add(lobby)
	lobby.ID = id

	// Add host as first player
	lobby.Players[hostID] = &LobbyPlayer{
		ClientID: hostID,
		Username: hostUsername,
		Ready:    false,
	}
	r.clientToLobby.Store(hostID, id)

	return lobby
}

type LobbyInfo struct {
	ID           uint64
	Name         string
	Format       string
	CurrentPlayers int
	MaxPlayers   int
	HostUsername string
	IsPrivate    bool
}

func (r *LobbyRegistry) ListPublicLobbies() []LobbyInfo {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []LobbyInfo
	r.lobbies.ForEach(func(_ uint64, lobby *Lobby) {
		if !lobby.IsPrivate {
			result = append(result, LobbyInfo{
				ID:            lobby.ID,
				Name:          lobby.Name,
				Format:        lobby.Format,
				CurrentPlayers: len(lobby.Players),
				MaxPlayers:    lobby.MaxPlayers,
				HostUsername:  lobby.HostUsername,
				IsPrivate:     lobby.IsPrivate,
			})
		}
	})
	return result
}

func (r *LobbyRegistry) FindLobby(id uint64) (*Lobby, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.lobbies.Get(id)
}

func (r *LobbyRegistry) JoinLobby(lobbyID uint64, clientID uint64, username string, password string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return fmt.Errorf("lobby not found")
	}

	if len(lobby.Players) >= lobby.MaxPlayers {
		return fmt.Errorf("lobby is full")
	}

	if lobby.PasswordHash != "" {
		if password == "" {
			return fmt.Errorf("password required")
		}
		if hashPassword(password) != lobby.PasswordHash {
			return fmt.Errorf("invalid password")
		}
	}

	lobby.Players[clientID] = &LobbyPlayer{
		ClientID: clientID,
		Username: username,
		Ready:    false,
	}
	r.clientToLobby.Store(clientID, lobbyID)
	return nil
}

func (r *LobbyRegistry) LeaveLobby(clientID uint64) (*Lobby, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	val, ok := r.clientToLobby.Load(clientID)
	if !ok {
		return nil, fmt.Errorf("client not in any lobby")
	}
	lobbyID := val.(uint64)

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		r.clientToLobby.Delete(clientID)
		return nil, fmt.Errorf("lobby not found")
	}

	delete(lobby.Players, clientID)
	r.clientToLobby.Delete(clientID)

	// If lobby is empty, remove it
	if len(lobby.Players) == 0 {
		r.lobbies.Delete(lobbyID)
		return nil, nil
	}

	// If host left, assign new host
	if lobby.HostID == clientID {
		for cid := range lobby.Players {
			lobby.HostID = cid
			break
		}
	}

	return lobby, nil
}

func (r *LobbyRegistry) SetReady(clientID uint64, ready bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	val, ok := r.clientToLobby.Load(clientID)
	if !ok {
		return fmt.Errorf("client not in any lobby")
	}
	lobbyID := val.(uint64)

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return fmt.Errorf("lobby not found")
	}

	player, ok := lobby.Players[clientID]
	if !ok {
		return fmt.Errorf("player not found in lobby")
	}
	player.Ready = ready
	return nil
}

func (r *LobbyRegistry) StartGame(lobbyID uint64, requestedBy uint64) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return fmt.Errorf("lobby not found")
	}

	// Only host can start
	if lobby.HostID != requestedBy {
		return fmt.Errorf("only host can start the game")
	}

	// Check all players are ready
	for _, p := range lobby.Players {
		if !p.Ready {
			return fmt.Errorf("not all players are ready")
		}
	}

	lobby.State = LobbyInGame
	return nil
}

func (r *LobbyRegistry) GetLobbyByClient(clientID uint64) (*Lobby, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	val, ok := r.clientToLobby.Load(clientID)
	if !ok {
		return nil, false
	}
	lobbyID := val.(uint64)
	return r.lobbies.Get(lobbyID)
}

func (r *LobbyRegistry) RemoveLobby(id uint64) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.lobbies.Delete(id)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/components/ -run "TestCreateLobby|TestListPublicLobbies|TestJoinLobby|TestJoinPrivateLobbyNoPassword|TestJoinPrivateLobbyWrongPassword|TestJoinPrivateLobbyCorrectPassword|TestLeaveLobby|TestLeaveLobbyRemovesEmpty|TestSetReady|TestStartGameNotHost|TestStartGameNotAllReady|TestStartGameSuccess|TestGetLobbyByClient|TestLobbyFull" -v`
Expected: All PASS

- [ ] **Step 5: Run all tests to check regressions**

Run: `make test`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add server/internal/server/components/lobby_registry.go server/internal/server/components/lobby_registry_test.go
git commit -m "feat: add LobbyRegistry component with TDD tests"
```

---

### Task 3: Update Hub to Include LobbyRegistry

**Files:**
- Modify: `server/internal/server/hub.go`

- [ ] **Step 1: Update Hub struct and NewHub**

```go
// server/internal/server/hub.go
package server

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/user"
)

type Hub struct {
	Logger      *slog.Logger
	UserService *user.Service
	Registry    *components.ClientRegistry
	Broker      *components.MessageBroker
	Lobbies     *components.LobbyRegistry
}

func NewHub(logger *slog.Logger, userService *user.Service) *Hub {
	return &Hub{
		Logger:      logger,
		UserService: userService,
		Registry:    components.NewClientRegistry(),
		Broker:      components.NewMessageBroker(),
		Lobbies:     components.NewLobbyRegistry(),
	}
}
// ... rest of file unchanged
```

- [ ] **Step 2: Run tests to verify**

Run: `make test`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add server/internal/server/hub.go
git commit -m "feat: add LobbyRegistry to Hub"
```

---

### Task 4: Add BroadcastToLobby to WebSocketClient

**Files:**
- Modify: `server/internal/server/clients/websocket.go`

- [ ] **Step 1: Add BroadcastToLobby method**

Add after the `Broadcast` method:

```go
func (c *WebSocketClient) BroadcastToLobby(lobbyID uint64, msg packets.Msg) {
	if lobby, ok := c.hub.Lobbies.FindLobby(lobbyID); ok {
		for clientID := range lobby.Players {
			if clientID == c.id {
				continue // don't send to self
			}
			if peer, exists := c.hub.Registry.Get(clientID); exists {
				peer.ProcessPacket(c.id, msg)
			}
		}
	}
}
```

- [ ] **Step 2: Run tests to verify**

Run: `make test`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add server/internal/server/clients/websocket.go
git commit -m "feat: add BroadcastToLobby method to WebSocketClient"
```

---

### Task 5: Create InLobby Server State (TDD)

**Files:**
- Create: `server/internal/server/states/in_lobby.go`
- Create: `server/internal/server/states/in_lobby_test.go`

- [ ] **Step 1: Write failing tests**

```go
// server/internal/server/states/in_lobby_test.go
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
	inLobby := NewInLobby(nil, lobbyReg, nil, lobbyID, "host")
	inLobby.SetClient(client)

	// Simulate leave request
	inLobby.HandleMessage(1, &packets.Packet_LobbyLeaveRequest{LobbyLeaveRequest: &packets.LobbyLeaveRequest{}})

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
	inLobby := NewInLobby(nil, lobbyReg, nil, lobbyID, "host")
	inLobby.SetClient(client)

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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/states/ -run "TestInLobby" -v`
Expected: FAIL — `NewInLobby` not defined

- [ ] **Step 3: Write minimal implementation**

```go
// server/internal/server/states/in_lobby.go
package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type InLobby struct {
	client      server.ClientInterfacer
	lobbyReg    *components.LobbyRegistry
	logger      *slog.Logger
	lobbyID     uint64
	username    string
}

func NewInLobby(
	logger *slog.Logger,
	lobbyReg *components.LobbyRegistry,
	client server.ClientInterfacer,
	lobbyID uint64,
	username string,
) *InLobby {
	return &InLobby{
		logger:   logger,
		lobbyReg: lobbyReg,
		client:   client,
		lobbyID:  lobbyID,
		username: username,
	}
}

func (i *InLobby) Name() string {
	return "InLobby"
}

func (i *InLobby) SetClient(client server.ClientInterfacer) {
	i.client = client
	i.logger = i.logger.With(
		"client_id", i.client.Id(),
		"lobby_id", i.lobbyID,
	)
}

func (i *InLobby) OnEnter() {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		i.logger.Error("lobby not found on enter")
		return
	}

	// Build player list
	var players []*packets.LobbyPlayer
	for _, p := range lobby.Players {
		players = append(players, &packets.LobbyPlayer{
			ClientId: p.ClientID,
			Username: p.Username,
			Ready:    p.Ready,
		})
	}

	i.client.SocketSend(&packets.Packet_LobbyJoinedResponse{
		LobbyJoinedResponse: &packets.LobbyJoinedResponse{
			LobbyId:      lobby.ID,
			LobbyName:    lobby.Name,
			HostUsername:  lobby.HostUsername,
			Players:       players,
		},
	})
}

func (i *InLobby) HandleMessage(senderId uint64, message packets.Msg) {
	switch msg := message.(type) {
	case *packets.Packet_LobbyLeaveRequest:
		i.handleLeave(senderId)
	case *packets.Packet_LobbyReadyRequest:
		i.handleReady(senderId, msg.LobbyReadyRequest)
	case *packets.Packet_LobbyStartRequest:
		i.handleStart(senderId)
	default:
		// Broadcast other messages to lobby peers
		i.broadcastToLobby(message)
	}
}

func (i *InLobby) handleLeave(senderId uint64) {
	lobby, err := i.lobbyReg.LeaveLobby(senderId)
	if err != nil {
		i.logger.Error("failed to leave lobby", "error", err)
		return
	}
	// If lobby still exists, notify remaining players
	if lobby != nil {
		lobby, _ = i.lobbyReg.FindLobby(lobby.ID)
		if lobby != nil {
			i.broadcastToLobby(&packets.Packet_LobbyPlayerLeft{
				LobbyPlayerLeft: &packets.LobbyPlayerLeft{ClientId: senderId},
			})
		}
	}
	// Transition client to Authenticated
	i.client.SetState(nil) // Will need to transition to Authenticated in practice
}

func (i *InLobby) handleReady(senderId uint64, msg *packets.LobbyReadyRequest) {
	if err := i.lobbyReg.SetReady(senderId, msg.Ready); err != nil {
		i.logger.Error("failed to set ready", "error", err)
		return
	}

	i.broadcastToLobby(&packets.Packet_LobbyPlayerReady{
		LobbyPlayerReady: &packets.LobbyPlayerReady{
			ClientId: senderId,
			Ready:    msg.Ready,
		},
	})
}

func (i *InLobby) handleStart(senderId uint64) {
	if err := i.lobbyReg.StartGame(i.lobbyID, senderId); err != nil {
		i.logger.Error("failed to start game", "error", err)
		return
	}

	// Broadcast game start to all lobby players
	// Each client will receive this and transition to InGame via their own HandleMessage
	i.broadcastToLobby(&packets.Packet_LobbyGameStart{
		LobbyGameStart: &packets.LobbyGameStart{},
	})

	// Transition self to InGame
	i.client.SetState(NewInGame(i.logger, i.lobbyID))
}

func (i *InLobby) broadcastToLobby(msg packets.Msg) {
	if lobby, ok := i.lobbyReg.FindLobby(i.lobbyID); ok {
		for clientID := range lobby.Players {
			if clientID == i.client.Id() {
				continue
			}
			if peer, exists := i.client.(*WebSocketClient); exists {
				if c, ok := peer.hub.Registry.Get(clientID); ok {
					c.ProcessPacket(i.client.Id(), msg)
				}
			}
		}
	}
}

func (i *InLobby) OnExit() {
	i.logger.Debug("exiting InLobby state")
}
```

Note: The `handleStart` and `broadcastToLobby` methods reference `WebSocketClient` directly which creates an import cycle. Fix needed — use the `ClientInterfacer` interface properly. Let me fix the implementation:

```go
// server/internal/server/states/in_lobby.go (fixed)
package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type InLobby struct {
	client      server.ClientInterfacer
	lobbyReg    *components.LobbyRegistry
	logger      *slog.Logger
	lobbyID     uint64
	username    string
}

func NewInLobby(
	logger *slog.Logger,
	lobbyReg *components.LobbyRegistry,
	client server.ClientInterfacer,
	lobbyID uint64,
	username string,
) *InLobby {
	return &InLobby{
		logger:   logger,
		lobbyReg: lobbyReg,
		client:   client,
		lobbyID:  lobbyID,
		username: username,
	}
}

func (i *InLobby) Name() string {
	return "InLobby"
}

func (i *InLobby) SetClient(client server.ClientInterfacer) {
	i.client = client
	i.logger = i.logger.With(
		"client_id", i.client.Id(),
		"lobby_id", i.lobbyID,
	)
}

func (i *InLobby) OnEnter() {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		i.logger.Error("lobby not found on enter")
		return
	}

	var players []*packets.LobbyPlayer
	for _, p := range lobby.Players {
		players = append(players, &packets.LobbyPlayer{
			ClientId: p.ClientID,
			Username: p.Username,
			Ready:    p.Ready,
		})
	}

	i.client.SocketSend(&packets.Packet_LobbyJoinedResponse{
		LobbyJoinedResponse: &packets.LobbyJoinedResponse{
			LobbyId:      lobby.ID,
			LobbyName:    lobby.Name,
			HostUsername:  lobby.HostUsername,
			Players:       players,
		},
	})
}

func (i *InLobby) HandleMessage(senderId uint64, message packets.Msg) {
	switch msg := message.(type) {
	case *packets.Packet_LobbyLeaveRequest:
		i.handleLeave(senderId)
	case *packets.Packet_LobbyReadyRequest:
		i.handleReady(senderId, msg.LobbyReadyRequest)
	case *packets.Packet_LobbyStartRequest:
		i.handleStart(senderId)
	case *packets.Packet_LobbyGameStart:
		i.handleGameStart()
	default:
		i.broadcastToLobby(message)
	}
}

func (i *InLobby) handleGameStart() {
	i.client.SetState(NewInGame(i.logger, i.lobbyID))
}

func (i *InLobby) handleLeave(senderId uint64) {
	lobby, err := i.lobbyReg.LeaveLobby(senderId)
	if err != nil {
		i.logger.Error("failed to leave lobby", "error", err)
		return
	}

	if lobby != nil {
		i.broadcastToLobby(&packets.Packet_LobbyPlayerLeft{
			LobbyPlayerLeft: &packets.LobbyPlayerLeft{ClientId: senderId},
		})
	}

	i.client.SetState(nil)
}

func (i *InLobby) handleReady(senderId uint64, msg *packets.LobbyReadyRequest) {
	if err := i.lobbyReg.SetReady(senderId, msg.Ready); err != nil {
		i.logger.Error("failed to set ready", "error", err)
		return
	}

	i.broadcastToLobby(&packets.Packet_LobbyPlayerReady{
		LobbyPlayerReady: &packets.LobbyPlayerReady{
			ClientId: senderId,
			Ready:    msg.Ready,
		},
	})
}

func (i *InLobby) handleStart(senderId uint64) {
	if err := i.lobbyReg.StartGame(i.lobbyID, senderId); err != nil {
		i.logger.Error("failed to start game", "error", err)
		return
	}

	i.broadcastToLobby(&packets.Packet_LobbyGameStart{
		LobbyGameStart: &packets.LobbyGameStart{},
	})

	lobby, _ := i.lobbyReg.FindLobby(i.lobbyID)
	if lobby != nil {
		for clientID := range lobby.Players {
			if c, exists := i.lobbyReg.FindLobby(i.lobbyID); exists {
				_ = c
			}
		}
	}

	// For now, just send LobbyGameStart and let clients transition
	// Full game state management comes later
}

func (i *InLobby) broadcastToLobby(msg packets.Msg) {
	lobby, ok := i.lobbyReg.FindLobby(i.lobbyID)
	if !ok {
		return
	}

	for clientID := range lobby.Players {
		if clientID == i.client.Id() {
			continue
		}
		i.client.PassToPeer(msg, clientID)
	}
}

func (i *InLobby) OnExit() {
	i.logger.Debug("exiting InLobby state")
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/states/ -run "TestInLobby" -v`
Expected: All PASS

- [ ] **Step 5: Run all tests**

Run: `make test`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add server/internal/server/states/in_lobby.go server/internal/server/states/in_lobby_test.go
git commit -m "feat: add InLobby server state with TDD tests"
```

---

### Task 6: Create InGame Stub Server State (TDD)

**Files:**
- Create: `server/internal/server/states/in_game.go`
- Create: `server/internal/server/states/in_game_test.go`

- [ ] **Step 1: Write failing test**

```go
// server/internal/server/states/in_game_test.go
package states

import (
	"testing"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestInGameOnEnter(t *testing.T) {
	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	inGame := NewInGame(nil, 123)
	inGame.SetClient(client)

	inGame.OnEnter()

	if len(client.sentMsgs) != 1 {
		t.Fatalf("expected 1 message on enter, got %d", len(client.sentMsgs))
	}
}

func TestInGameName(t *testing.T) {
	inGame := NewInGame(nil, 123)
	if inGame.Name() != "InGame" {
		t.Errorf("expected InGame, got %s", inGame.Name())
	}
}

func TestInGameHandleMessage(t *testing.T) {
	inGame := NewInGame(nil, 123)
	// Should not panic, just log
	inGame.HandleMessage(1, &packets.Packet_PingMessage{
		PingMessage: &packets.PingMessage{Timestamp: 12345},
	})
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/states/ -run "TestInGame" -v`
Expected: FAIL — `NewInGame` not defined

- [ ] **Step 3: Write minimal implementation**

```go
// server/internal/server/states/in_game.go
package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type InGame struct {
	client server.ClientInterfacer
	logger *slog.Logger
	gameID uint64
}

func NewInGame(logger *slog.Logger, gameID uint64) *InGame {
	return &InGame{
		logger: logger,
		gameID: gameID,
	}
}

func (i *InGame) Name() string {
	return "InGame"
}

func (i *InGame) SetClient(client server.ClientInterfacer) {
	i.client = client
	i.logger = i.logger.With(
		"client_id", i.client.Id(),
		"game_id", i.gameID,
	)
}

func (i *InGame) OnEnter() {
	i.logger.Info("client entered game (stub)")
	// Send placeholder game init message
	// In the future, this will send full game state
}

func (i *InGame) HandleMessage(senderId uint64, message packets.Msg) {
	i.logger.Debug("received message in InGame state (stub)", "sender_id", senderId, "message_type", message)
	// Stub: log and ignore for now
	// Future: route to game engine
}

func (i *InGame) OnExit() {
	i.logger.Info("client left game (stub)")
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/states/ -run "TestInGame" -v`
Expected: All PASS

- [ ] **Step 5: Run all tests**

Run: `make test`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add server/internal/server/states/in_game.go server/internal/server/states/in_game_test.go
git commit -m "feat: add InGame stub server state with TDD tests"
```

---

### Task 7: Update Authenticated State for Lobby Browser

**Files:**
- Modify: `server/internal/server/states/authenticated.go`
- Create: `server/internal/server/states/authenticated_test.go`

- [ ] **Step 1: Write failing tests for new Authenticated behavior**

```go
// server/internal/server/states/authenticated_test.go
package states

import (
	"testing"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestAuthenticatedLobbyList(t *testing.T) {
	lobbyReg := components.NewLobbyRegistry()
	lobbyReg.CreateLobby(1, "host1", "Public Lobby", "1v1", 2, false, "")

	client := &mockInLobbyClient{id: 2, sentMsgs: []packets.Msg{}}
	auth := NewAuthenticated(nil, "player2")
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
	lobbyReg := components.NewLobbyRegistry()

	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	auth := NewAuthenticated(nil, "host")
	// Need to inject lobbyReg — will need to update Authenticated struct
	auth.SetClient(client)

	// This test will be updated after refactoring Authenticated
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/states/ -run "TestAuthenticated" -v`
Expected: FAIL or needs refactoring

- [ ] **Step 3: Update Authenticated state**

```go
// server/internal/server/states/authenticated.go (updated)
package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type Authenticated struct {
	client      server.ClientInterfacer
	username    string
	logger      *slog.Logger
	lobbyReg    *components.LobbyRegistry
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

	switch msg := message.(type) {
	case *packets.Packet_LobbyListRequest:
		a.handleLobbyList()
	case *packets.Packet_LobbyCreateRequest:
		a.handleCreateLobby(senderId, msg.LobbyCreateRequest)
	case *packets.Packet_LobbyJoinRequest:
		a.handleJoinLobby(senderId, msg.LobbyJoinRequest)
	default:
		// Ignore other messages in authenticated state
	}
}

func (a *Authenticated) handleLobbyList() {
	lobbies := a.lobbyReg.ListPublicLobbies()

	var lobbyInfos []*packets.LobbyInfo
	for _, l := range lobbies {
		lobbyInfos = append(lobbyInfos, &packets.LobbyInfo{
			Id:            l.ID,
			Name:          l.Name,
			Format:        l.Format,
			CurrentPlayers: int32(l.CurrentPlayers),
			MaxPlayers:    int32(l.MaxPlayers),
			HostUsername:  l.HostUsername,
			IsPrivate:     l.IsPrivate,
		})
	}

	a.client.SocketSend(&packets.Packet_LobbyListResponse{
		LobbyListResponse: &packets.LobbyListResponse{
			Lobbies: lobbyInfos,
		},
	})
}

func (a *Authenticated) handleCreateLobby(senderId uint64, msg *packets.LobbyCreateRequest) {
	lobby := a.lobbyReg.CreateLobby(
		senderId,
		a.username,
		msg.Name,
		msg.Format,
		int(msg.MaxPlayers),
		msg.IsPrivate,
		msg.Password,
	)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, lobby.ID, a.username))
}

func (a *Authenticated) handleJoinLobby(senderId uint64, msg *packets.LobbyJoinRequest) {
	var password string
	if msg.Password != nil {
		password = *msg.Password
	}

	err := a.lobbyReg.JoinLobby(msg.LobbyId, senderId, a.username, password)
	if err != nil {
		a.logger.Error("failed to join lobby", "error", err)
		a.client.SocketSend(&packets.Packet_DenyResponseMessage{
			DenyResponse: &packets.DenyResponseMessage{Reason: err.Error()},
		})
		return
	}

	// Get lobby to find host info
	lobby, _ := a.lobbyReg.FindLobby(msg.LobbyId)

	// Transition to InLobby state
	a.client.SetState(NewInLobby(a.logger, a.lobbyReg, a.client, msg.LobbyId, a.username))

	// Notify other players in lobby
	lobby, _ = a.lobbyReg.FindLobby(msg.LobbyId)
	if lobby != nil {
		// Broadcast player joined to others (handled in InLobby.OnEnter)
	}
}

func (a *Authenticated) OnExit() {
	a.logger.Info("client leaving authenticated state", "username", a.username)
}
```

Also update `connected.go` to pass `lobbyReg` to `Authenticated`:

```go
// In connected.go, update NewAuthenticated call:
func (c *Connected) handleLogin(senderId uint64, packet *packets.Packet_LoginRequest) {
	// ... existing login logic ...

	c.client.SocketSend(packets.NewOkResponse())
	// Need access to lobbyReg - will need to update Connected struct too
	c.client.SetState(NewAuthenticated(c.logger, username, nil)) // pass lobbyReg
}
```

This requires updating `Connected` to also have access to `LobbyRegistry`. For brevity, we'll update both `Connected` and `Authenticated` to accept `lobbyReg`.

- [ ] **Step 4: Update Connected state to pass LobbyRegistry**

```go
// server/internal/server/states/connected.go (updated)
package states

import (
	"context"
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/user"
	"github.com/bfibraga/turntide/server/internal/server/validation"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type Connected struct {
	client      server.ClientInterfacer
	userService *user.Service
	logger      *slog.Logger
	lobbyReg    *components.LobbyRegistry
}

func NewConnected(logger *slog.Logger, userService *user.Service, lobbyReg *components.LobbyRegistry) *Connected {
	return &Connected{
		logger:      logger,
		userService: userService,
		lobbyReg:    lobbyReg,
	}
}

// ... update handleLogin and handleRegister to pass lobbyReg:
func (c *Connected) handleLogin(senderId uint64, packet *packets.Packet_LoginRequest) {
	// ... existing logic ...
	c.client.SetState(NewAuthenticated(c.logger, username, c.lobbyReg))
}

func (c *Connected) handleRegister(senderId uint64, packet *packets.Packet_RegisterRequest) {
	// ... existing logic ...
	c.client.SetState(NewAuthenticated(c.logger, username, c.lobbyReg))
}
```

- [ ] **Step 5: Update websocket.go to pass lobbyReg to Connected**

```go
// In server/internal/server/clients/websocket.go, update Initialize:
func (c *WebSocketClient) Initialize(id uint64) {
	c.id = id
	c.logger = c.hub.Logger.With("client_id", id)
	c.SetState(states.NewConnected(c.logger, c.hub.UserService, c.hub.Lobbies))
	c.logger.Debug("Sent ID to client")
}
```

- [ ] **Step 6: Run all tests**

Run: `make test`
Expected: All tests pass (may need to update existing tests in connected_test.go and authenticated_test.go to pass lobbyReg)

- [ ] **Step 7: Commit**

```bash
git add server/internal/server/states/authenticated.go server/internal/server/states/authenticated_test.go server/internal/server/states/connected.go server/internal/server/clients/websocket.go
git commit -m "feat: update Authenticated state to act as lobby browser"
```

---

### Task 8: Update Client Packet Factory and Network

**Files:**
- Modify: `client/scripts/network/packets/factory.gd`
- Modify: `client/scripts/network/network.gd`

- [ ] **Step 1: Add lobby packet factory methods**

```gdscript
# client/scripts/network/packets/factory.gd (additions)
func new_lobby_create_req(name: String, format: String, max_players: int, is_private: bool, password: String = "") -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var msg : packets.LobbyCreateRequest = packet.new_lobby_create_request()
	packet.set_sender_id(Global.client_id)
	msg.set_name(name)
	msg.set_format(format)
	msg.set_max_players(max_players)
	msg.set_is_private(is_private)
	if password != "":
		msg.set_password(password)
	return packet

func new_lobby_join_req(lobby_id: int, password: String = "") -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var msg : packets.LobbyJoinRequest = packet.new_lobby_join_request()
	packet.set_sender_id(Global.client_id)
	msg.set_lobby_id(lobby_id)
	if password != "":
		msg.set_password(password)
	return packet

func new_lobby_leave_req() -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var msg = packet.new_lobby_leave_request()
	packet.set_sender_id(Global.client_id)
	return packet

func new_lobby_ready_req(ready: bool) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var msg = packet.new_lobby_ready_request()
	packet.set_sender_id(Global.client_id)
	msg.set_ready(ready)
	return packet

func new_lobby_start_req() -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var msg = packet.new_lobby_start_request()
	packet.set_sender_id(Global.client_id)
	return packet

func new_lobby_list_req() -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var msg = packet.new_lobby_list_request()
	packet.set_sender_id(Global.client_id)
	return packet
```

- [ ] **Step 2: Add lobby packet wrapper classes to network.gd**

```gdscript
# client/scripts/network/network.gd (additions)
class LobbyCreateRequest extends _packets.LobbyCreateRequest:
	pass

class LobbyJoinRequest extends _packets.LobbyJoinRequest:
	pass

class LobbyLeaveRequest extends _packets.LobbyLeaveRequest:
	pass

class LobbyReadyRequest extends _packets.LobbyReadyRequest:
	pass

class LobbyStartRequest extends _packets.LobbyStartRequest:
	pass

class LobbyListRequest extends _packets.LobbyListRequest:
	pass

class LobbyListResponse extends _packets.LobbyListResponse:
	pass

class LobbyJoinedResponse extends _packets.LobbyJoinedResponse:
	pass

class LobbyPlayer extends _packets.LobbyPlayer:
	pass

class LobbyPlayerJoined extends _packets.LobbyPlayerJoined:
	pass

class LobbyPlayerLeft extends _packets.LobbyPlayerLeft:
	pass

class LobbyPlayerReady extends _packets.LobbyPlayerReady:
	pass

class LobbyGameStart extends _packets.LobbyGameStart:
	pass

class LobbyInfo extends _packets.LobbyInfo:
	pass
```

- [ ] **Step 3: Commit**

```bash
git add client/scripts/network/packets/factory.gd client/scripts/network/network.gd
git commit -m "feat: add lobby packet types to client network layer"
```

---

### Task 9: Create Client LobbyBrowser State

**Files:**
- Create: `client/states/lobby/browser.gd`
- Create: `client/tests/lobby_browser_test.gd`
- Create: `client/scenes/lobby_browser.tscn`

- [ ] **Step 1: Create LobbyBrowserState**

```gdscript
# client/states/lobby/browser.gd
class_name LobbyBrowserState
extends State

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger: Log = Global.logger

static func Name() -> String:
	return "LobbyBrowser"

func enter() -> void:
	logger.info("Entered Lobby Browser")
	# Request lobby list on enter
	var pkt = factory.new_lobby_list_req()
	Global.ws.send(pkt)

func exit() -> void:
	logger.info("Exiting Lobby Browser")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_list_response():
		_handle_lobby_list(packet.get_lobby_list_response())

func _handle_lobby_list(response) -> void:
	logger.info("Received lobby list")
	# TODO: populate UI with response.get_lobbies()
```

- [ ] **Step 2: Create minimal lobby_browser.tscn**

Create a basic scene with:
- A VBoxContainer for lobby list
- A "Create Lobby" button
- A "Join Lobby" button
- Wire up signals to LobbyBrowserState

- [ ] **Step 3: Commit**

```bash
git add client/states/lobby/browser.gd client/scenes/lobby_browser.tscn
git commit -m "feat: add LobbyBrowser client state and scene"
```

---

### Task 10: Create Client InLobby State

**Files:**
- Create: `client/states/lobby/in_lobby.gd`
- Create: `client/tests/in_lobby_test.gd`
- Create: `client/scenes/lobby_room.tscn`

- [ ] **Step 1: Create InLobbyState**

```gdscript
# client/states/lobby/in_lobby.gd
class_name InLobbyState
extends SceneHolderState

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger: Log = Global.logger

static func Name() -> String:
	return "InLobby"

func _init() -> void:
	packed_scene = preload("res://scenes/lobby_room.tscn")

func enter() -> void:
	super.enter()
	logger.info("Entered InLobby")

func exit() -> void:
	super.exit()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_player_joined():
		_handle_player_joined(packet.get_lobby_player_joined())
	elif packet.has_lobby_player_left():
		_handle_player_left(packet.get_lobby_player_left())
	elif packet.has_lobby_player_ready():
		_handle_player_ready(packet.get_lobby_player_ready())
	elif packet.has_lobby_game_start():
		_handle_game_start()

func _handle_player_joined(msg) -> void:
	logger.info("Player joined: %s" % msg.get_player().get_username())

func _handle_player_left(msg) -> void:
	logger.info("Player left: %d" % msg.get_client_id())

func _handle_player_ready(msg) -> void:
	logger.info("Player %d ready: %s" % [msg.get_client_id(), msg.get_ready()])

func _handle_game_start() -> void:
	logger.info("Game starting!")
	Transitioned.emit(self, IngameState.Name())
```

- [ ] **Step 2: Create lobby_room.tscn**

Create a basic scene with:
- Player list (VBoxContainer)
- Chat box
- Ready button
- Start Game button (visible only to host)

- [ ] **Step 3: Commit**

```bash
git add client/states/lobby/in_lobby.gd client/scenes/lobby_room.tscn
git commit -m "feat: add InLobby client state and scene"
```

---

### Task 11: Wire Up State Machine

**Files:**
- Modify: `client/states/scene_state_machine.gd`

- [ ] **Step 1: Add lobby states to scene state machine**

Ensure LobbyBrowserState and InLobbyState are children of the scene_state_machine node in the main scene, or add them programmatically.

- [ ] **Step 2: Update transition flow**

In the client connection flow:
1. `ConnectedState` → `LoginState`/`RegisterState` → `LobbyBrowserState` (after auth success)
2. `LobbyBrowserState` → `InLobbyState` (after join/create)
3. `InLobbyState` → `IngameState` (after game start)

- [ ] **Step 3: Run full build and test**

Run: `make test`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add client/states/scene_state_machine.gd
git commit -m "feat: wire lobby states into client state machine"
```

---

### Task 12: Final Integration Test

- [ ] **Step 1: Run full test suite**

Run: `make test`
Expected: All Go tests pass

- [ ] **Step 2: Build and verify**

Run: `make`
Expected: Build succeeds, no errors

- [ ] **Step 3: Manual testing checklist**

1. Start server: `./shared/resources/bin/server`
2. Start client (Godot)
3. Register/login
4. Verify lobby browser appears
5. Create a lobby
6. Join with second client
7. Both players ready up
8. Host starts game
9. Verify both clients transition to InGame

- [ ] **Step 4: Final commit (if not already committed by tasks above)**

```bash
git add -A
git commit -m "feat: complete lobby system implementation with TDD"
```
