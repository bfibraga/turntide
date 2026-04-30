# Game Lobby Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a multiplayer game lobby system for up to 8 players with URL sharing, casual/ranked modes, and reconnection support.

**Architecture:** Centralized lobby state on server (Go), client via WebSocket (GDScript). Per-lobby mutex for thread safety. Deep link URL scheme for joining.

**Tech Stack:** Go 1.26, SQLite, WebSockets, Protocol Buffers, GDScript (Godot 4.6)

---

## File Structure Overview

```
shared/
└── packets.proto                    # Add lobby messages

server/
├── internal/server/
│   ├── lobby/
│   │   ├── registry.go         # Global lobby registry
│   │   ├── lobby.go        # Lobby model + mutex
│   │   ├── player.go      # LobbyPlayer
│   │   ├── handler.go    # WebSocket message handling
│   │   ├── matchmaking.go # Ranked auto-fill
│   │   └── states.go    # State machine
│   └── db/
│       ├── lobby.sql.go      # SQLC queries
│       └── schema.go      # Table definitions

client/
├── states/lobby/
│   ├── lobby.gd           # Main lobby state
│   ├── lobby_state.gd     # Base state
│   ├── pregame_state.gd  # Pre-game logic
│   └── ingame_state.gd  # In-game logic
├── scripts/lobby/
│   ├── lobby_manager.gd # Lobby operations
│   ├── lobby_handler.gd # Message handling
│   └── url_handler.gd # Deep link parsing
└── scenes/lobby/
    └── lobby.tscn      # Lobby UI
```

---

## Task 1: Protocol Buffer Definitions

**Files:**
- Modify: `shared/packets.proto`
- Generate: `Makefile` target for proto generation

- [ ] **Step 1: Add lobby messages to packets.proto**

```protobuf
// Add after existing messages in shared/packets.proto

enum LobbyType {
  LOBBY_TYPE_CASUAL = 0;
  LOBBY_TYPE_RANKED = 1;
}

enum LobbyVisibility {
  LOBBY_VISIBILITY_PUBLIC = 0;
  LOBBY_VISIBILITY_PRIVATE = 1;
}

enum LobbyState {
  LOBBY_STATE_PRE_GAME = 0;
  LOBBY_STATE_IN_GAME = 1;
  LOBBY_STATE_GAME_OVER = 2;
}

message LobbySettings {
  string lobby_id = 1;
  string name = 2;
  LobbyType lobby_type = 3;
  LobbyVisibility visibility = 4;
  int32 min_players = 5;
  int32 max_players = 6;
  string format = 7;
  bool ready_required = 8;
  int32 afk_timeout = 9;
}

message LobbyPlayerData {
  uint64 user_id = 1;
  string username = 2;
  bool is_ready = 3;
  bool is_host = 4;
  string deck_id = 5;
  bool is_connected = 6;
}

message LobbyStateMessage {
  string lobby_id = 1;
  LobbyState state = 2;
  LobbySettings settings = 3;
  repeated LobbyPlayerData players = 4;
}

enum LobbyAction {
  LOBBY_ACTION_CREATE = 0;
  LOBBY_ACTION_JOIN = 1;
  LOBBY_ACTION_LEAVE = 2;
  LOBBY_ACTION_UPDATE_SETTINGS = 3;
  LOBBY_ACTION_SET_READY = 4;
  LOBBY_ACTION_START_GAME = 5;
  LOBBY_ACTION_REQUEST_RECONNECT = 6;
  LOBBY_ACTION_CHAT = 7;
  LOBBY_ACTION_AUTO_FILL = 8;
  LOBBY_ACTION_PROMOTE_HOST = 9;
}

message LobbyMessage {
  string lobby_id = 1;
  LobbyAction action = 2;
  LobbySettings settings = 3;
  bool ready = 4;
  string chat_message = 5;
  uint64 target_user_id = 6;
}

enum LobbyResponseStatus {
  LOBBY_RESPONSE_SUCCESS = 0;
  LOBBY_RESPONSE_FULL = 1;
  LOBBY_RESPONSE_NOT_FOUND = 2;
  LOBBY_RESPONSE_NOT_HOST = 3;
  LOBBY_RESPONSE_GAME_IN_PROGRESS = 4;
  LOBBY_RESPONSE_ALREADY_IN_LOBBY = 5;
}

message LobbyResponse {
  string lobby_id = 1;
  LobbyResponseStatus status = 2;
  string reason = 3;
  LobbyStateMessage lobby_state = 4;
}
```

- [ ] **Step 2: Generate Go bindings**

Run: `make proto`

Expected: `server/pkg/packets/packets.pb.go` updated with lobby messages

- [ ] **Step 3: Commit**

```bash
git add shared/packets.proto server/pkg/packets/
git commit -m "feat: add lobby protocol buffer messages"
```

---

## Task 2: Database Schema

**Files:**
- Create: `server/internal/server/db/lobby_schema.sql`
- Modify: `server/internal/server/db/db.go`

- [ ] **Step 1: Run schema migration**

```bash
sqlite3 turntide.db <<'EOF'
-- Lobby metadata
CREATE TABLE IF NOT EXISTS lobbies (
    id TEXT PRIMARY KEY,
    host_id INTEGER NOT NULL,
    host_name TEXT,
    name TEXT,
    lobby_type TEXT CHECK(lobby_type IN ('CASUAL', 'RANKED')) DEFAULT 'CASUAL',
    visibility TEXT CHECK(visibility IN ('PUBLIC', 'PRIVATE')) DEFAULT 'PRIVATE',
    min_players INTEGER DEFAULT 2,
    max_players INTEGER DEFAULT 8,
    format TEXT DEFAULT 'standard',
    ready_required BOOLEAN DEFAULT TRUE,
    afk_timeout INTEGER DEFAULT 120,
    state TEXT CHECK(state IN ('PRE_GAME', 'IN_GAME', 'GAME_OVER')) DEFAULT 'PRE_GAME',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Player session in lobby
CREATE TABLE IF NOT EXISTS lobby_players (
    lobby_id TEXT REFERENCES lobbies(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL,
    username TEXT,
    is_ready BOOLEAN DEFAULT FALSE,
    is_host BOOLEAN DEFAULT FALSE,
    deck_id TEXT,
    is_connected BOOLEAN DEFAULT TRUE,
    joined_at INTEGER NOT NULL,
    last_ping INTEGER,
    PRIMARY KEY (lobby_id, user_id)
);

-- Per-format MMR
CREATE TABLE IF NOT EXISTS player_mmr (
    user_id INTEGER NOT NULL,
    format TEXT NOT NULL,
    rating INTEGER DEFAULT 1000,
    games_played INTEGER DEFAULT 0,
    last_match INTEGER,
    PRIMARY KEY (user_id, format)
);

-- Public lobby listing
CREATE TABLE IF NOT EXISTS public_lobbies (
    lobby_id TEXT PRIMARY KEY REFERENCES lobbies(id) ON DELETE CASCADE,
    host_name TEXT,
    player_count INTEGER DEFAULT 0,
    format TEXT,
    updated_at INTEGER NOT NULL
);

-- Match history
CREATE TABLE IF NOT EXISTS matches (
    id TEXT PRIMARY KEY,
    lobby_id TEXT,
    format TEXT,
    winner_user_id INTEGER,
    loser_user_id INTEGER,
    winner_rating_change INTEGER,
    loser_rating_change INTEGER,
    is_ranked BOOLEAN DEFAULT FALSE,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lobby_players_lobby ON lobby_players(lobby_id);
CREATE INDEX IF NOT EXISTS idx_public_lobbies_updated ON public_lobbies(updated_at);
CREATE INDEX IF NOT EXISTS idx_matches_lobby ON matches(lobby_id);
EOF
```

- [ ] **Step 2: Verify tables created**

Run: `sqlite3 turntide.db ".tables"`

Expected: lobbies, lobby_players, player_mmr, public_lobbies, matches

- [ ] **Step 3: Commit**

```bash
git add server/internal/server/db/
git commit -m "feat: add lobby database schema"
```

---

## Task 3: Server Lobby Models

**Files:**
- Create: `server/internal/server/lobby/lobby.go`
- Create: `server/internal/server/lobby/player.go`

- [ ] **Step 1: Create Lobby model**

```go
// server/internal/server/lobby/lobby.go
package lobby

import (
    "sync"
    "time"

    "github.com/bfibraga/turntide/server/internal/server/db"
)

type LobbyType string
type LobbyVisibility string
type LobbyState string

const (
    LobbyTypeCasual    LobbyType = "CASUAL"
    LobbyTypeRanked  LobbyType = "RANKED"
    LobbyVisibilityPublic   LobbyVisibility = "PUBLIC"
    LobbyVisibilityPrivate LobbyVisibility = "PRIVATE"
    LobbyStatePreGame   LobbyState = "PRE_GAME"
    LobbyStateInGame LobbyState = "IN_GAME"
    LobbyStateGameOver LobbyState = "GAME_OVER"
)

type Lobby struct {
    mu sync.Mutex

    ID            string
    HostID        uint64
    HostName      string
    Name         string
    Type         LobbyType
    Visibility   LobbyVisibility
    MinPlayers   int
    MaxPlayers  int
    Format      string
    ReadyRequired bool
    AFKTimeout  int
    State       LobbyState

    Players map[uint64]*Player
    createdAt time.Time
    updatedAt time.Time
}

type LobbySettings struct {
    ID            string
    Name          string
    Type          LobbyType
    Visibility    LobbyVisibility
    MinPlayers    int
    MaxPlayers   int
    Format        string
    ReadyRequired bool
    AFKTimeout    int
}

func NewLobby(hostID uint64, hostName string, settings *LobbySettings) *Lobby {
    if settings.MaxPlayers == 0 {
        settings.MaxPlayers = 8
    }
    if settings.MinPlayers == 0 {
        settings.MinPlayers = 2
    }
    if settings.AFKTimeout == 0 {
        settings.AFKTimeout = 120
    }
    if settings.Format == "" {
        settings.Format = "standard"
    }
    
    now := time.Now()
    return &Lobby{
        ID:            settings.ID,
        HostID:        hostID,
        HostName:      hostName,
        Name:         settings.Name,
        Type:         settings.Type,
        Visibility:   settings.Visibility,
        MinPlayers:   settings.MinPlayers,
        MaxPlayers:  settings.MaxPlayers,
        Format:      settings.Format,
        ReadyRequired: settings.ReadyRequired,
        AFKTimeout:  settings.AFKTimeout,
        State:       LobbyStatePreGame,
        Players:     make(map[uint64]*Player),
        createdAt:   now,
        updatedAt:  now,
    }
}

func (l *Lobby) GetSettings() *LobbySettings {
    return &LobbySettings{
        ID:            l.ID,
        Name:          l.Name,
        Type:         l.Type,
        Visibility:   l.Visibility,
        MinPlayers:   l.MinPlayers,
        MaxPlayers:  l.MaxPlayers,
        Format:      l.Format,
        ReadyRequired: l.ReadyRequired,
        AFKTimeout:  l.AFKTimeout,
    }
}

func (l *Lobby) State() LobbyState {
    l.mu.Lock()
    defer l.mu.Unlock()
    return l.State
}

func (l *Lobby) SetState(state LobbyState) {
    l.mu.Lock()
    defer l.mu.Unlock()
    l.State = state
    l.updatedAt = time.Now()
}

func (l *Lobby) PlayerCount() int {
    l.mu.Lock()
    defer l.mu.Unlock()
    return len(l.Players)
}
```

- [ ] **Step 2: Create Player model**

```go
// server/internal/server/lobby/player.go
package lobby

import (
    "time"
)

type Player struct {
    UserID      uint64
    Username    string
    IsReady     bool
    IsHost     bool
    DeckID     string
    IsConnected bool
    LastPing   time.Time
    JoinedAt   time.Time
}

func NewPlayer(userID uint64, username string, isHost bool) *Player {
    return &Player{
        UserID:      userID,
        Username:    username,
        IsReady:     false,
        IsHost:     isHost,
        IsConnected: true,
        JoinedAt:   time.Now(),
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add server/internal/server/lobby/
git commit -m "feat: add lobby and player models"
```

---

## Task 4: Lobby Registry

**Files:**
- Create: `server/internal/server/lobby/registry.go`

- [ ] **Step 1: Create registry with per-lobby locking**

```go
// server/internal/server/lobby/registry.go
package lobby

import (
    "context"
    "fmt"
    "sync"
    "time"

    "github.com/google/uuid"
)

type Registry struct {
    mu sync.RWMutex
    lobbies map[string]*Lobby
    
    matchmakingQueue []uint64  // User IDs waiting for ranked
}

func NewRegistry() *Registry {
    return &Registry{
        lobbies: make(map[string]*Lobby),
        matchmakingQueue: make([]uint64, 0),
    }
}

func (r *Registry) Create(ctx context.Context, hostID uint64, hostName string, settings *LobbySettings) (*Lobby, error) {
    if settings.ID == "" {
        settings.ID = uuid.New().String()
    }
    
    lobby := NewLobby(hostID, hostName, settings)
    
    r.mu.Lock()
    defer r.mu.Unlock()
    
    if _, exists := r.lobbies[settings.ID]; exists {
        return nil, fmt.Errorf("lobby already exists: %s", settings.ID)
    }
    
    r.lobbies[settings.ID] = lobby
    return lobby, nil
}

func (r *Registry) Get(id string) (*Lobby, bool) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    lobby, ok := r.lobbies[id]
    return lobby, ok
}

func (r *Registry) Delete(id string) bool {
    r.mu.Lock()
    defer r.mu.Unlock()
    _, ok := r.lobbies[id]
    if ok {
        delete(r.lobbies, id)
    }
    return ok
}

func (r *Registry) ListPublic() []*Lobby {
    r.mu.RLock()
    defer r.mu.RUnlock()
    
    result := make([]*Lobby, 0)
    for _, l := range r.lobbies {
        if l.Visibility == LobbyVisibilityPublic && l.State() == LobbyStatePreGame {
            result = append(result, l)
        }
    }
    return result
}

func (r *Registry) AddToMatchmaking(userID uint64) {
    r.mu.Lock()
    defer r.mu.Unlock()
    r.matchmakingQueue = append(r.matchmakingQueue, userID)
}

func (r *Registry) PopMatchmaking() (uint64, bool) {
    r.mu.Lock()
    defer r.mu.Unlock()
    if len(r.matchmakingQueue) == 0 {
        return 0, false
    }
    userID := r.matchmakingQueue[0]
    r.matchmakingQueue = r.matchmakingQueue[1:]
    return userID, true
}
```

- [ ] **Step 2: Commit**

```bash
git add server/internal/server/lobby/registry.go
git commit -m "feat: add lobby registry with per-lobby mutex"
```

---

## Task 5: Lobby Message Handler

**Files:**
- Create: `server/internal/server/lobby/handler.go`

- [ ] **Step 1: Create message handler**

```go
// server/internal/server/lobby/handler.go
package lobby

import (
    "context"
    "log/slog"

    "github.com/bfibraga/turntide/server/internal/server"
    "github.com/bfibraga/turntide/pkg/packets"
)

type Handler struct {
    hub      *server.Hub
    registry *Registry
    logger   *slog.Logger
}

func NewHandler(hub *server.Hub, registry *Registry, logger *slog.Logger) *Handler {
    return &Handler{
        hub:      hub,
        registry: registry,
        logger:   logger,
    }
}

func (h *Handler) HandleLobbyMessage(ctx context.Context, senderID uint64, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby, ok := h.registry.Get(msg.LobbyId)
    if !ok && msg.Action != packets.LobbyAction_LOBBY_ACTION_CREATE {
        return &packets.LobbyResponse{
            LobbyId: msg.LobbyId,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_FOUND,
            Reason: "lobby not found",
        }
    }

    switch msg.Action {
    case packets.LobbyAction_LOBBY_ACTION_CREATE:
        return h.handleCreate(ctx, senderID, msg)
    case packets.LobbyAction_LOBBY_ACTION_JOIN:
        return h.handleJoin(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_LEAVE:
        return h.handleLeave(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_UPDATE_SETTINGS:
        return h.handleUpdateSettings(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_SET_READY:
        return h.handleSetReady(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_START_GAME:
        return h.handleStartGame(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_CHAT:
        return h.handleChat(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_AUTO_FILL:
        return h.handleAutoFill(ctx, senderID, lobby, msg)
    case packets.LobbyAction_LOBBY_ACTION_REQUEST_RECONNECT:
        return h.handleReconnect(ctx, senderID, lobby, msg)
    default:
        return &packets.LobbyResponse{
            LobbyId: msg.LobbyId,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_FOUND,
            Reason: "unknown action",
        }
    }
}

func (h *Handler) handleCreate(ctx context.Context, senderID uint64, msg *packets.LobbyMessage) *packets.LobbyResponse {
    username := msg.Settings.Name // Gets username from authenticated session
    lobby, err := h.registry.Create(ctx, senderID, username, &LobbySettings{
        ID:            msg.LobbyId,
        Name:          msg.Settings.Name,
        Type:         LobbyType(msg.Settings.LobbyType),
        Visibility:   LobbyVisibility(msg.Settings.Visibility),
        MinPlayers:   int(msg.Settings.MinPlayers),
        MaxPlayers:  int(msg.Settings.MaxPlayers),
        Format:      msg.Settings.Format,
        ReadyRequired: msg.Settings.ReadyRequired,
        AFKTimeout:  int(msg.Settings.AfkTimeout),
    })
    if err != nil {
        return &packets.LobbyResponse{
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_FOUND,
            Reason: err.Error(),
        }
    }
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) handleJoin(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    if lobby.State() != LobbyStatePreGame {
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_GAME_IN_PROGRESS,
            Reason: "game in progress",
        }
    }
    
    if lobby.PlayerCount() >= lobby.MaxPlayers {
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_FULL,
            Reason: "lobby full",
        }
    }
    
    username := msg.ChatMessage // Gets username from authenticated session
    player := NewPlayer(senderID, username, false)
    
    lobby.mu.Lock()
    lobby.Players[senderID] = player
    lobby.mu.Unlock()
    
    // Broadcast to all players
    h.broadcastState(lobby)
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) handleLeave(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby.mu.Lock()
    defer lobby.mu.Unlock()
    
    player, exists := lobby.Players[senderID]
    if !exists {
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_FOUND,
            Reason: "player not in lobby",
        }
    }
    
    if player.IsHost {
        // Host leaving - migrate or close
        h.handleHostLeave(ctx, lobby)
    } else {
        delete(lobby.Players, senderID)
    }
    
    h.broadcastState(lobby)
    
    return &packets.LobbyResponse{
        LobbyId: lobby.ID,
        Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS,
    }
}

func (h *Handler) handleSetReady(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby.mu.Lock()
    player, exists := lobby.Players[senderID]
    if exists {
        player.IsReady = msg.Ready
    }
    lobby.mu.Unlock()
    
    h.broadcastState(lobby)
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) handleStartGame(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby.mu.Lock()
    player, exists := lobby.Players[senderID]
    if !exists || !player.IsHost {
        lobby.mu.Unlock()
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_HOST,
            Reason: "only host can start game",
        }
    }
    lobby.mu.Unlock()
    
    // Check ready requirement
    if lobby.ReadyRequired {
        allReady := true
        lobby.mu.Lock()
        for _, p := range lobby.Players {
            if !p.IsReady {
                allReady = false
                break
            }
        }
        lobby.mu.Unlock()
        
        if !allReady {
            return &packets.LobbyResponse{
                LobbyId: lobby.ID,
                Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_HOST,
                Reason: "not all players ready",
            }
        }
    }
    
    // Ensure min players
    if lobby.PlayerCount() < lobby.MinPlayers {
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_HOST,
            Reason: fmt.Sprintf("need at least %d players", lobby.MinPlayers),
        }
    }
    
    lobby.SetState(LobbyStateInGame)
    h.broadcastState(lobby)
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) handleHostLeave(ctx context.Context, lobby *Lobby) {
    if len(lobby.Players) <= 1 {
        h.registry.Delete(lobby.ID)
        return
    }
    
    // Find new host
    var newHostID uint64
    var newestPlayer *Player
    
    lobby.mu.Lock()
    for id, p := range lobby.Players {
        if newestPlayer == nil || p.JoinedAt.Before(newestPlayer.JoinedAt) {
            newHostID = id
            newestPlayer = p
        }
    }
    
    if newHostID != 0 {
        lobby.HostID = newHostID
        lobby.Players[newHostID].IsHost = true
    }
    lobby.mu.Unlock()
}

func (h *Handler) handleChat(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    // Broadcast chat to all players in lobby
    lobby.mu.Lock()
    for userID := range lobby.Players {
        if userID != senderID {
            h.hub.Clients.SendTo(userID, &packets.Packet{
                SenderId: senderID,
                Msg: &packets.LobbyMessage{
                    LobbyId: lobby.ID,
                    Action: packets.LobbyAction_LOBBY_ACTION_CHAT,
                    ChatMessage: msg.ChatMessage,
                },
            })
        }
    }
    lobby.mu.Unlock()
    
    return &packets.LobbyResponse{
        LobbyId: lobby.ID,
        Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS,
    }
}

func (h *Handler) handleAutoFill(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby.mu.Lock()
    player, exists := lobby.Players[senderID]
    if !exists || !player.IsHost {
        lobby.mu.Unlock()
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_HOST,
            Reason: "only host can auto-fill",
        }
    }
    lobby.mu.Unlock()
    
    // Query matchmaking queue and send invites to candidates
    openSlots := lobby.MaxPlayers - lobby.PlayerCount()
    
    lobby.mu.Unlock()
    
    for i := 0; i < openSlots; i++ {
        if userID, ok := h.registry.PopMatchmaking(); ok {
            // Send INVITE to userID via WebSocket
            h.hub.Clients.SendTo(userID, &packets.Packet{
                SenderId: lobby.HostID,
                Msg: &packets.LobbyMessage{
                    LobbyId: lobby.ID,
                    Action: packets.LobbyAction_LOBBY_ACTION_JOIN,
                    TargetUserId: userID,
                },
            })
        }
    }
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) handleReconnect(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby.mu.Lock()
    player, exists := lobby.Players[senderID]
    if !exists {
        lobby.mu.Unlock()
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_FOUND,
            Reason: "player not found",
        }
    }
    
    player.IsConnected = true
    player.LastPing = time.Now()
    lobby.mu.Unlock()
    
    h.broadcastState(lobby)
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) handleUpdateSettings(ctx context.Context, senderID uint64, lobby *Lobby, msg *packets.LobbyMessage) *packets.LobbyResponse {
    lobby.mu.Lock()
    player, exists := lobby.Players[senderID]
    if !exists || !player.IsHost {
        lobby.mu.Unlock()
        return &packets.LobbyResponse{
            LobbyId: lobby.ID,
            Status: packets.LobbyResponseStatus_LOBBY_RESPONSE_NOT_HOST,
            Reason: "only host can update settings",
        }
    }
    
    if msg.Settings.Name != "" {
        lobby.Name = msg.Settings.Name
    }
    if msg.Settings.Format != "" {
        lobby.Format = msg.Settings.Format
    }
    lobby.ReadyRequired = msg.Settings.ReadyRequired
    if msg.Settings.AfkTimeout >= 30 {
        lobby.AFKTimeout = int(msg.Settings.AfkTimeout)
    }
    lobby.mu.Unlock()
    
    h.broadcastState(lobby)
    
    return h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
}

func (h *Handler) lobbyResponse(lobby *Lobby, status packets.LobbyResponseStatus) *packets.LobbyResponse {
    resp := &packets.LobbyResponse{
        LobbyId: lobby.ID,
        Status: status,
        LobbyState: &packets.LobbyStateMessage{
            LobbyId: lobby.ID,
            State:   packets.LobbyState(lobby.State()),
            Settings: &packets.LobbySettings{
                LobbyId:     lobby.ID,
                Name:       lobby.Name,
                LobbyType:  packets.LobbyType(lobby.Type),
                Visibility:  packets.LobbyVisibility(lobby.Visibility),
                MinPlayers: int32(lobby.MinPlayers),
                MaxPlayers: int32(lobby.MaxPlayers),
                Format:     lobby.Format,
                ReadyRequired: lobby.ReadyRequired,
                AfkTimeout:  int32(lobby.AFKTimeout),
            },
            Players: h.getPlayerDataSlice(lobby),
        },
    }
    return resp
}

func (h *Handler) getPlayerDataSlice(lobby *Lobby) []*packets.LobbyPlayerData {
    lobby.mu.Lock()
    defer lobby.mu.Unlock()
    
    players := make([]*packets.LobbyPlayerData, 0, len(lobby.Players))
    for _, p := range lobby.Players {
        players = append(players, &packets.LobbyPlayerData{
            UserId:      p.UserID,
            Username:   p.Username,
            IsReady:    p.IsReady,
            IsHost:    p.IsHost,
            DeckId:    p.DeckID,
            IsConnected: p.IsConnected,
        })
    }
    return players
}

func (h *Handler) broadcastState(lobby *Lobby) {
    resp := h.lobbyResponse(lobby, packets.LobbyResponseStatus_LOBBY_RESPONSE_SUCCESS)
    
    lobby.mu.Lock()
    for userID := range lobby.Players {
        h.hub.Clients.SendTo(userID, &packets.Packet{
            Msg: &packets.LobbyMessage{
                LobbyId: lobby.ID,
                Action: packets.LobbyAction_LOBBY_ACTION_UPDATE_SETTINGS,
            },
        })
    }
    lobby.mu.Unlock()
}
```

- [ ] **Step 2: Commit**

```bash
git add server/internal/server/lobby/handler.go
git commit -m "feat: add lobby message handler"
```

---

## Task 6: Integrate Lobby Handler with Hub

**Files:**
- Modify: `server/internal/server/hub.go`
- Modify: `server/main.go`

- [ ] **Step 1: Add lobby registry to Hub**

In `server/internal/server/hub.go`, add:

```go
type Hub struct {
    Logger         *slog.Logger
    UserRepository repository.UserRepository
    Clients      *objects.SharedCollection[ClientInterfacer]
    LobbyRegistry *lobby.Registry  // ADD THIS
    LobbyHandler *lobby.Handler  // ADD THIS
    BroadcastChan chan *packets.Packet
    RegisterChan  chan ClientInterfacer
    UnregisterChan chan ClientInterfacer
}

func NewHub(logger *slog.Logger, userRepo repository.UserRepository) *Hub {
    registry := lobby.NewRegistry()
    return &Hub{
        Logger:         logger,
        UserRepository: userRepo,
        Clients:      objects.NewSharedCollection[ClientInterfacer](),
        LobbyRegistry: registry,  // ADD THIS
        LobbyHandler:  lobby.NewHandler(nil, registry, logger),  // ADD THIS (hub set later)
        BroadcastChan: make(chan *packets.Packet),
        RegisterChan:  make(chan ClientInterfacer),
        UnregisterChan: make(chan ClientInterfacer),
    }
}
```

- [ ] **Step 2: Update Hub initializers**

In `server/main.go`, after creating hub:

```go
hub := server.NewHub(logger, userRepo)
hub.LobbyHandler = lobby.NewHandler(hub, hub.LobbyRegistry, logger)  // ADD THIS
```

- [ ] **Step 3: Handle lobby messages in client**

In client ProcessPacket method, add:

```go
case *packets.LobbyMessage:
    resp := h.LobbyHandler.HandleLobbyMessage(ctx, senderID, msg)
    c.SocketSend(resp)
```

- [ ] **Step 4: Commit**

```bash
git add server/internal/server/hub.go server/main.go
git commit -m "feat: integrate lobby handler with hub"
```

---

## Task 7: Ranked Matchmaking

**Files:**
- Create: `server/internal/server/lobby/matchmaking.go`

- [ ] **Step 1: Create matchmaking logic**

```go
// server/internal/server/lobby/matchmaking.go
package lobby

import (
    "sort"
)

type MatchmakingEntry struct {
    UserID      uint64
    Username    string
    Rating      int
    Format      string
    QueuedAt    int64
}

type Matchmaking struct {
    queue map[string][]*MatchmakingEntry  // format -> queue
}

func NewMatchmaking() *Matchmaking {
    return &Matchmaking{
        queue: make(map[string][]*MatchmakingEntry),
    }
}

func (m *Matchmaking) JoinQueue(entry *MatchmakingEntry) {
    m.queue[entry.Format] = append(m.queue[entry.Format], entry)
    sort.Slice(m.queue[entry.Format], func(i, j int) bool {
        return m.queue[entry.Format][i].Rating < m.queue[entry.Format][j].Rating
    })
}

func (m *Matchmaking) LeaveQueue(userID uint64, format string) {
    entries := m.queue[format]
    for i, e := range entries {
        if e.UserID == userID {
            m.queue[format] = append(entries[:i], entries[i+1:]...)
            return
        }
    }
}

func (m *Matchmaking) FindMatch(format string, minPlayers, maxPlayers int, targetRating int) []uint64 {
    entries := m.queue[format]
    if len(entries) == 0 {
        return nil
    }
    
    // Find players around target rating
    var matches []uint64
    for _, e := range entries {
        if e.Rating >= targetRating-200 && e.Rating <= targetRating+200 {
            matches = append(matches, e.UserID)
            if len(matches) >= maxPlayers {
                break
            }
        }
    }
    
    if len(matches) < minPlayers {
        return nil
    }
    
    return matches
}
```

- [ ] **Step 2: Commit**

```bash
git add server/internal/server/lobby/matchmaking.go
git commit -m "feat: add ranked matchmaking"
```

---

## Task 8: Cloudflare Tunnel Setup

**Files:**
- Create: `.cloudflared/config.yml`
- Create: `cloudflared/start.sh`

- [ ] **Step 1: Create cloudflared config**

```yaml
# .cloudflared/config.yml
tunnel: turntide
ingress:
  - hostname: game.yourdomain.com
    service: http://localhost:8080
  - service: http_status:404
```

- [ ] **Step 2: Create start script**

```bash
#!/bin/bash
# cloudflared/start.sh
set -e

echo "Starting Cloudflare Tunnel..."
cloudflared tunnel run turntide

echo "Tunnel running. Connect at: wss://game.yourdomain.com/ws"
```

- [ ] **Step 3: Commit**

```bash
git add .cloudflared/ cloudflared/
git commit -m "feat: add cloudflare tunnel config"
```

---

## Task 9: Client Lobby Manager

**Files:**
- Create: `client/scripts/lobby/lobby_manager.gd`
- Create: `client/scripts/lobby/lobby_handler.gd`
- Create: `client/scripts/lobby/url_handler.gd`

- [ ] **Step 1: Create LobbyManager**

```gdscript
# client/scripts/lobby/lobby_manager.gd
class_name LobbyManager
extends Node

signal lobby_created(lobby_id: String)
signal lobby_joined(lobby_id: String)
signal lobby_state_changed(state: int)
signal player_joined(player_data: Dictionary)
signal player_left(user_id: int)
signal chat_received(user_id: int, message: String)
signal error(reason: String)

var _current_lobby_id: String = ""
var _is_host: bool = false
var _lobby_state: int = 0  # PRE_GAME = 0, IN_GAME = 1, GAME_OVER = 2
var _settings: Dictionary = {}
var _players: Array = []

func create_lobby(name: String, lobby_type: int = 0, max_players: int = 8) -> void:
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = ""
    msg.action = Packets.LobbyAction.LOBBY_ACTION_CREATE
    msg.settings = PacketsFactory.lobby_settings()
    msg.settings.lobby_id = ""
    msg.settings.name = name
    msg.settings.lobby_type = lobby_type
    msg.settings.max_players = max_players
    msg.settings.ready_required = true
    msg.settings.afk_timeout = 120
    
    Network.send_packet(msg)

func join_lobby(lobby_id: String) -> bool:
    if _current_lobby_id != "":
        error.emit("Already in a lobby")
        return false
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_JOIN
    
    Network.send_packet(msg)
    return true

func leave_lobby() -> void:
    if _current_lobby_id == "":
        return
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = _current_lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_LEAVE
    
    Network.send_packet(msg)
    _current_lobby_id = ""
    _players.clear()

func set_ready(ready: bool) -> void:
    if _current_lobby_id == "":
        return
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = _current_lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_SET_READY
    msg.ready = ready
    
    Network.send_packet(msg)

func start_game() -> void:
    if _current_lobby_id == "" or not _is_host:
        return
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = _current_lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_START_GAME
    
    Network.send_packet(msg)

func update_settings(settings: Dictionary) -> void:
    if _current_lobby_id == "" or not _is_host:
        return
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = _current_lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_UPDATE_SETTINGS
    msg.settings = PacketsFactory.lobby_settings()
    
    for key in settings:
        msg.settings[key] = settings[key]
    
    Network.send_packet(msg)

func send_chat(message: String) -> void:
    if _current_lobby_id == "":
        return
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = _current_lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_CHAT
    msg.chat_message = message
    
    Network.send_packet(msg)

func request_reconnect() -> void:
    if _current_lobby_id == "":
        return
    
    var msg = PacketsFactory.lobby_message()
    msg.lobby_id = _current_lobby_id
    msg.action = Packets.LobbyAction.LOBBY_ACTION_REQUEST_RECONNECT
    
    Network.send_packet(msg)

func _handle_lobby_response(resp: Dictionary) -> void:
    var status = resp.get("status", 0)
    if status != Packets.LobbyResponseStatus.LOBBY_RESPONSE_SUCCESS:
        error.emit(resp.get("reason", "Unknown error"))
        return
    
    _current_lobby_id = resp.get("lobby_id", "")
    
    if resp.has("lobby_state"):
        var state = resp.lobby_state
        _apply_lobby_state(state)

func _apply_lobby_state(state: Dictionary) -> void:
    _lobby_state = state.get("state", 0)
    _settings = state.get("settings", {})
    _players = state.get("players", [])
    
    lobby_state_changed.emit(_lobby_state)
    
    for player in _players:
        if player.get("is_host", false):
            _is_host = player.get("user_id") == Network.my_user_id
```

- [ ] **Step 2: Create URL handler**

```gdscript
# client/scripts/lobby/url_handler.gd
class_name URLHandler
extends Node

static func parse_deep_link(url: String) -> String:
    # turntide://lobby/{id}
    # turntide://join/{id}
    if url.begins_with("turntide://lobby/"):
        return url.substr(18)
    if url.begins_with("turntide://join/"):
        return url.substr(16)
    return ""

static func create_lobby_link(lobby_id: String) -> String:
    return "turntide://lobby/%s" % lobby_id
```

- [ ] **Step 3: Commit**

```bash
git add client/scripts/lobby/
git commit -m "feat: add client lobby manager"
```

---

## Task 10: Client Lobby States

**Files:**
- Create: `client/states/lobby/`
- Create: `client/states/lobby/lobby.gd`
- Create: `client/states/lobby/pregame_state.gd`
- Create: `client/states/lobby/ingame_state.gd`

- [ ] **Step 1: Create main lobby state**

```gdscript
# client/states/lobby/lobby.gd
class_name LobbyState
extends SceneState

@export var lobby_scene: PackedScene

var _lobby_manager: LobbyManager

func _ready() -> void:
    _lobby_manager = LobbyManager.new()
    add_child(_lobby_manager)
    
    _lobby_manager.lobby_state_changed.connect(_on_lobby_state_changed)
    _lobby_manager.player_joined.connect(_on_player_joined)
    _lobby_manager.player_left.connect(_on_player_left)
    _lobby_manager.error.connect(_on_error)

func enter() -> void:
    push_scene(lobby_scene)

func exit() -> void:
    _lobby_manager.leave_lobby()

func _on_lobby_state_changed(state: int) -> void:
    match state:
        0:  # PRE_GAME
            transition_to("pregame")
        1:  # IN_GAME
            transition_to("ingame")
        2:  # GAME_OVER
            transition_to("gameover")

func _on_player_joined(player_data: Dictionary) -> void:
    pass

func _on_player_left(user_id: int) -> void:
    pass

func _on_error(reason: String) -> void:
    Log.error("Lobby error: %s" % reason)
    transition_to("/menu")
```

- [ ] **Step 2: Create pregame state**

```gdscript
# client/states/lobby/pregame_state.gd
class_name PregameState
extends SubState

var _ready: bool = false

func _ready() -> void:
    super._ready()
    
    # Connect UI signals
    # ready_button.toggled.connect(_on_ready_toggled)
    # start_button.pressed.connect(_on_start_pressed)
    # settings_button.pressed.connect(_on_settings_pressed)

func _on_ready_toggled(toggled: bool) -> void:
    _ready = toggled
    LobbyManager.set_ready(toggled)

func _on_start_pressed() -> void:
    LobbyManager.start_game()

func _on_settings_pressed() -> void:
    # Show settings panel (host only)
    pass
```

- [ ] **Step 3: Create ingame state**

```gdscript
# client/states/lobby/ingame_state.gd
class_name IngameState
extends SubState

var _afk_timer: float = 0.0
var _afk_timeout: float = 120.0

func _process(delta: float) -> void:
    # Handle reconnection timer
    var connected = true  # Get from Network
    if not connected:
        _afk_timer += delta
        if _afk_timer >= _afk_timeout:
            _on_afk_timeout()

func _on_afk_timeout() -> void:
    Log.warning("AFK timeout reached")
    transition_to("/menu")
```

- [ ] **Step 4: Commit**

```bash
git add client/states/lobby/
git commit -m "feat: add client lobby states"
```

---

## Task 11: Build & Test

**Files:**
- Run: Build and test commands

- [ ] **Step 1: Build server**

Run: `make server`

Expected: Binary in `server/turntide-server`

- [ ] **Step 2: Test proto generation**

Run: `make proto`

Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: complete game lobby implementation"
```

---

## Verification Commands

```bash
# Build everything
make all

# Run tests
go test ./server/internal/server/lobby/... -v

# Start server
./server/turntide-server

# Start cloudflare tunnel (for external connections)
./cloudflared/start.sh
```

---

## Coverage Check

| Requirement | Task |
|-------------|------|
| 8 players max | Task 1, Task 3 |
| URL shareable link | Task 9 |
| Pre-game/In-game/Pre-game | Task 5, Task 10 |
| Host migration | Task 5 (handleHostLeave) |
| Per-format MMR | Task 2 |
| Auto-fill | Task 7 |
| AFK timer (30-120s) | Task 1, Task 10 |
| Lobby chat | Task 5 (handleChat) |
| External connection | Task 8 |
| Per-lobby locking | Task 3, Task 4 |

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-08-game-lobby-plan.md`.**

Two execution options:

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?