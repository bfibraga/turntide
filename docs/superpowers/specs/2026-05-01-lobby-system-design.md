# Lobby System Design Spec

Date: 2026-05-01

## Overview

Add a lobby system to the MTG game server and client, enabling players to create lobbies, browse available ones, join/leave, ready up, and start games. Supports variable-size lobbies and both public and private lobby types. The InGame state is a stub for now — this spec covers the lobby → game handoff only.

## Design Decisions

| Decision | Choice |
|----------|--------|
| Scope | Game browser + matchmaking with variable-size lobbies |
| Lobby lifecycle | Host-controlled (replay or close after game) |
| Lobby privacy | Public + Private (invite-only via lobby ID) |
| Ready system | All players must ready, host starts game |
| InGame scope | Stub state, lobby → game handoff only |
| Architecture | New `LobbyRegistry` component, `InLobby` + `InGame` states |

## Server-Side Architecture

### Hub Changes

Add `Lobbies *components.LobbyRegistry` to the `Hub` struct.

The Hub's `Run()` loop does NOT need a new broadcast channel for lobbies — lobby-scoped message routing is handled inside the `InLobby` state itself, keeping the Hub simple.

### New Component: LobbyRegistry

File: `server/internal/server/components/lobby_registry.go`

```
type Lobby struct {
    ID           uint64
    Name         string
    Format       string
    MaxPlayers   int
    IsPrivate    bool
    Password     string  // hashed, empty = no password
    HostID       uint64
    HostUsername string
    Players      map[uint64]*LobbyPlayer  // clientID → player
    State        LobbyState               // waiting, ready, in_game
}

type LobbyPlayer struct {
    ClientID uint64
    Username string
    Ready    bool
}

type LobbyState int
const (
    LobbyWaiting LobbyState = iota
    LobbyReady
    LobbyInGame
)

type LobbyRegistry struct {
    lobbies      *objects.SharedCollection[*Lobby]
    clientToLobby map[uint64]uint64  // clientID → lobbyID
    mu            sync.RWMutex
}
```

Key methods:

- `CreateLobby(hostID, hostUsername, name, format, maxPlayers, isPrivate, password) *Lobby`
- `FindLobby(id) (*Lobby, bool)`
- `ListPublicLobbies() []*LobbyInfo`
- `JoinLobby(lobbyID, clientID, username, password) error`
- `LeaveLobby(clientID) (*Lobby, error)` — returns lobby so caller can check if empty
- `SetReady(clientID, ready) error`
- `StartGame(lobbyID, requestedBy) error` — checks all ready, host-only
- `RemoveLobby(id)` — cleanup when game ends or lobby empty
- `GetLobbyByClient(clientID) (*Lobby, bool)`

### State Machine Flow

```
Connected → Authenticated → InLobby → InGame (stub)
```

### Authenticated State Changes

File: `server/internal/server/states/authenticated.go`

After login, `Authenticated` becomes a **lobby browser** state:

- `HandleMessage()` only accepts `LobbyCreateRequest`, `LobbyJoinRequest`, `LobbyListRequest`
- `LobbyListRequest` → respond with `LobbyListResponse` from `lobbyReg.ListPublicLobbies()`
- `LobbyCreateRequest` → create lobby, auto-join, transition client to `InLobby`
- `LobbyJoinRequest` → join lobby, transition client to `InLobby`

### New State: InLobby

File: `server/internal/server/states/in_lobby.go`

```
type InLobby struct {
    client      server.ClientInterfacer
    lobbyReg    *components.LobbyRegistry
    logger      *slog.Logger
    lobbyID     uint64
    username    string
}
```

Behavior:

- `OnEnter()`: Send `LobbyJoinedResponse` to client with full lobby info (players, host, etc.)
- `HandleMessage()`:
  - `LobbyLeaveRequest` → leave lobby, transition to `Authenticated`
  - `LobbyReadyRequest` → call `lobbyReg.SetReady(clientId, ready)`, broadcast `LobbyPlayerReady` to lobby peers
  - `LobbyStartRequest` → call `lobbyReg.StartGame(lobbyID, clientId)`, if all ready broadcast `LobbyGameStart` to all lobby clients, then each client transitions to `InGame`
  - Any other message → broadcast to lobby peers only via lobby registry lookup
- `OnExit()`: If lobby still exists, call `lobbyReg.LeaveLobby(clientId)` to clean up

Helper for lobby-scoped broadcast (added to `ClientInterfacer` or done via `LobbyRegistry`):

```
func (c *WebSocketClient) BroadcastToLobby(lobbyID uint64, msg packets.Msg) {
    if lobby, ok := c.hub.Lobbies.GetLobby(lobbyID); ok {
        for clientID := range lobby.Players {
            if peer, exists := c.hub.Registry.Get(clientID); exists {
                peer.ProcessPacket(c.id, msg)
            }
        }
    }
}
```

### New State: InGame (Stub)

File: `server/internal/server/states/in_game.go`

```
type InGame struct {
    client   server.ClientInterfacer
    logger   *slog.Logger
    gameID   uint64
}
```

Behavior (stub):

- `OnEnter()`: Log "client entered game", send a placeholder `GameInit` message
- `HandleMessage()`: Log received messages (no-op for now, future: route to game engine)
- `OnExit()`: Log "client left game"

## Protobuf Messages

File: `shared/packets.proto`

```protobuf
syntax = "proto3";

package shared;

option go_package = "/pkg/packets";

// --- Existing messages omitted for brevity ---

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

message LobbyGameStart {
  // Signals all clients in lobby to transition to InGame state
}
```

Add to `Packet` oneof:

```protobuf
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

## Client-Side Architecture

### Client State Flow

```
Connected → Login/Register → Authenticated (Lobby Browser) → InLobby → InGame (stub)
```

### New Client States

**LobbyBrowserState** (`client/states/lobby/browser.gd`)

- Extends `State`
- On `enter()`: send `LobbyListRequest`, display lobby list
- UI shows: lobby list (name, format, players, host), Create button, Join button
- Handles `LobbyListResponse`: populate list
- Handles `LobbyJoinedResponse`: transition to `InLobbyState`

**InLobbyState** (`client/states/lobby/in_lobby.gd`)

- Extends `SceneHolderState`, loads `lobby_room.tscn`
- Scene has: player list, chat box, Ready button, Start Game button (host only)
- On `enter()`: display lobby info (name, host, players)
- Handles `LobbyPlayerJoined`, `LobbyPlayerLeft`, `LobbyPlayerReady`: update player list
- Handles `LobbyGameStart`: transition to `InGameState`
- `LobbyLeaveRequest`: transition back to `LobbyBrowserState`

### New Scenes

| Scene | Purpose |
|-------|---------|
| `scenes/lobby_browser.tscn` | List public lobbies, create/join lobby |
| `scenes/lobby_room.tscn` | Current lobby view: player list, chat, ready/start |

### Packet Factory Additions

File: `client/scripts/network/packets/factory.gd`

```gdscript
func new_lobby_create_req(name: String, format: String, max_players: int, is_private: bool, password: String = "") -> packets.Packet:
func new_lobby_join_req(lobby_id: int, password: String = "") -> packets.Packet:
func new_lobby_leave_req() -> packets.Packet:
func new_lobby_ready_req(ready: bool) -> packets.Packet:
func new_lobby_start_req() -> packets.Packet:
func new_lobby_list_req() -> packets.Packet:
```

### Network.gd Additions

File: `client/scripts/network/network.gd`

Add GDScript wrapper classes for all new packet types (`LobbyCreateRequest`, `LobbyJoinedResponse`, `LobbyListResponse`, `LobbyInfo`, `LobbyPlayer`, etc.) matching the proto definitions.

## Data Flow: Creating & Starting a Game

```
Client A (Authenticated)
  → LobbyCreateRequest
  → Server: LobbyRegistry.CreateLobby()
  → Server: client.SetState(InLobby)
  → Client A: transition to InLobbyState, receive LobbyJoinedResponse

Client B (Authenticated)
  → LobbyListRequest → receives LobbyListResponse
  → LobbyJoinRequest(lobby_id)
  → Server: LobbyRegistry.JoinLobby()
  → Server: broadcast LobbyPlayerJoined to lobby peers
  → Client B: transition to InLobbyState
  → Client A: receives LobbyPlayerJoined, updates player list

Client A clicks Ready → LobbyReadyRequest(true)
Client B clicks Ready → LobbyReadyRequest(true)
  → Server: broadcast LobbyPlayerReady to lobby peers

Host (A) clicks Start → LobbyStartRequest
  → Server: LobbyRegistry.StartGame() checks all ready
  → Server: broadcast LobbyGameStart to all lobby clients
  → All clients: transition to InGameState (stub)
```

## Testing Strategy

Follow Test-Driven Development (TDD) for all critical implementations. Write tests before implementation code.

| Component | Test Focus |
|-----------|------------|
| `lobby_registry.go` | Lobby CRUD, join/leave, ready state, start game validation, client-to-lobby mapping |
| `in_lobby.go` | State transitions (enter/exit), message handling, lobby-scoped broadcast |
| `in_game.go` | State transitions (stub), message logging |
| `authenticated.go` (modified) | Lobby browser message handling, create/join/list request routing |
| `websocket.go` (modified) | `BroadcastToLobby` method |

## File Summary

### New files to create

| File | Purpose |
|------|---------|
| `server/internal/server/components/lobby_registry.go` | LobbyRegistry component |
| `server/internal/server/states/in_lobby.go` | InLobby state handler |
| `server/internal/server/states/in_game.go` | InGame stub state |
| `client/states/lobby/browser.gd` | Lobby browser client state |
| `client/states/lobby/in_lobby.gd` | InLobby client state |
| `client/scenes/lobby_browser.tscn` | Lobby browser scene |
| `client/scenes/lobby_room.tscn` | Lobby room scene |

### Files to modify

| File | Change |
|------|--------|
| `shared/packets.proto` | Add lobby message types |
| `server/internal/server/hub.go` | Add `Lobbies *components.LobbyRegistry` to Hub |
| `server/internal/server/states/authenticated.go` | Convert to lobby browser state |
| `server/internal/server/interfaces.go` | Re-export any new interfaces if needed |
| `server/internal/server/clients/websocket.go` | Add `BroadcastToLobby` method |
| `client/scripts/network/packets/factory.gd` | Add lobby packet factory methods |
| `client/scripts/network/network.gd` | Add lobby packet wrapper classes |
| `client/states/scene_state_machine.gd` | Add lobby states as children if needed |
