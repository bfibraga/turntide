# Game Lobby System Specification

> **For implementation:** See corresponding plan at `docs/superpowers/plans/2026-04-08-game-lobby-plan.md`

## Overview

A multiplayer game lobby system for up to 8 players. Lobbies are joinable via deep URL links (`turntide://lobby/{id}`) and support both casual and ranked play modes. Lobby state persists across games (pre-game → in-game → pre-game cycle).

---

## 1. Lobby State Machine

### States

```
┌─────────────────────────────────────────────────────────┐
│                    LOBBY LIFETIME                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   ┌──────────────┐         ┌──────────────────────┐   │
│   │   PRE-GAME   │────────▶│      IN-GAME        │   │
│   │   (Waiting)  │         │   (Playing/Active) │   │
│   └──────────────┘◀────────└──────────────────────┘   │
│        │                                                 │
│        │ (All ready / Host starts)                       │
│        ▼                                                 │
│   ┌──────────────┐                                       │
│   │  GAME OVER  │──────── returns to PRE-GAME            │
│   └──────────────┘                                       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

| State | Description |
|-------|-------------|
| **Pre-Game** | Players can join/leave, chat, configure decks, ready up, host changes settings |
| **In-Game** | Game active, locked roster, server-authoritative state |
| **Game Over** | Results displayed, MMR updated (ranked), returns to pre-game same lobby |

### State Transitions

| From | To | Trigger |
|------|-----|---------|
| Pre-Game | In-Game | All ready ✅ + Host clicks Start (if ready required), OR Host clicks Start anytime |
| In-Game | Game Over | Game ends (win condition met) |
| Game Over | Pre-Game | Automatic return after N seconds |
| Pre-Game | Pre-Game | New player joins/leaves |
| In-Game | Pre-Game | Host disconnects during game |

---

## 2. Lobby Data Model

### Go (Server)

```go
// Lobby represents a game lobby
type Lobby struct {
    mu sync.Mutex // Per-lobby mutex

    ID              string               // UUID v4
    HostID          uint64              // Owner user ID
    Name            string              // Lobby name
    Type            LobbyType           // CASUAL or RANKED
    Visibility      Visibility           // PUBLIC or PRIVATE
    MinPlayers      int                 // Minimum to start (default 2)
    MaxPlayers      int                 // Maximum (2-8)
    Format          string               // Game format (host-configurable)
    ReadyRequired   bool                // Host toggle for ready system
    AFKTimeout     int                 // Reconnect timeout in seconds (30-120, default 120)
    State           LobbyState          // PRE_GAME, IN_GAME, GAME_OVER

    Players     map[uint64]*LobbyPlayer
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

// LobbyPlayer represents a player in a lobby
type LobbyPlayer struct {
    UserID      uint64
    Username    string
    IsReady     bool
    IsHost      bool
    DeckID      string
    IsConnected bool  // For AFK detection
    LastPing    time.Time
}

// LobbyTypeenum
type LobbyType string
const (
    LobbyTypeCasual LobbyType = "CASUAL"
    LobbyTypeRanked LobbyType = "RANKED"
)

// Visibility enum
type Visibility string
const (
    VisibilityPublic   Visibility = "PUBLIC"
    VisibilityPrivate Visibility = "PRIVATE"
)

// LobbyState enum
type LobbyState string
const (
    LobbyStatePreGame   LobbyState = "PRE_GAME"
    LobbyStateInGame  LobbyState = "IN_GAME"
    LobbyStateGameOver LobbyState = "GAME_OVER"
)
```

### Protocol Buffer

```protobuf
message LobbySettings {
  string lobby_id = 1;
  string name = 2;
  LobbyType type = 3;
  Visibility visibility = 4;
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

message LobbyMessage {
  enum Action {
    CREATE = 0;
    JOIN = 1;
    LEAVE = 2;
    UPDATE_SETTINGS = 3;
    SET_READY = 4;
    START_GAME = 5;
    REQUEST_RECONNECT = 6;
    CHAT = 7;
    AUTO_FILL = 8;
  }

  string lobby_id = 1;
  Action action = 2;
  LobbySettings settings = 3;
  bool ready = 4;
  string chat_message = 5;
  uint64 requesting_user_id = 6;
}

message LobbyResponse {
  enum Status {
    SUCCESS = 0;
    LOBBY_FULL = 1;
    LOBBY_NOT_FOUND = 2;
    NOT_HOST = 3;
    GAME_IN_PROGRESS = 4;
    ALREADY_IN_LOBBY = 5;
  }

  string lobby_id = 1;
  Status status = 2;
  string reason = 3;
  LobbyStateMessage lobby_state = 4;
}
```

---

## 3. URL Scheme & Networking

### Deep Link Format

```
turntide://lobby/{lobby_id}
turntide://join/{lobby_id}
```

### WebSocket Routes

| Route | Description |
|-------|-------------|
| `/ws` | Main game connection |
| `/ws?lobby={id}` | Auto-join lobby on connect |

### Connection Flow

```
Client                          Server
   │                              │
   │── Connect /ws ──────────────▶│
   │                              │
   │◀── Challenge ────────────────│
   │                              │
   │── Auth + Optional Lobby ID──▶│
   │                              │
   │◀── Lobby State ───────────────│
   │                              │
   │◀── Player Updates ──────────│
   │                              │
```

---

## 4. Reconnection & AFK Handling

### Reconnect Flow

```
Player disconnect detected:
  1. Set IsConnected = false
  2. Start AFK timer (configurable, 30-120s)
  3. Broadcast "Player disconnected" to lobby
  
Timer expires:
  - IF pre-game: Remove from lobby
  - IF in-game: Forfeit game, remove from lobby
  
Player reconnects before timer:
  1. Set IsConnected = true
  2. Cancel AFK timer
  3. If in-game: Send full game state for sync
  4. Broadcast "Player reconnected"
```

### Host Migration

```
Host disconnects:
  IF pre-game:
    1. Promote oldest player (by join time) as new host
    2. Broadcast new host_id to all players
    3. Update lobby state
    
  IF in-game:
    1. Pause game state
    2. Broadcast "Host left, game ending in 30s"
    3. Close lobby after grace period
    4. No MMR adjustment applied (ranked)
```

---

## 5. Ranked Matchmaking

### Auto-Fill Logic

```
On "Auto-fill" triggered:
  1. Calculate open slots = max_players - current_players
  2. Query matchmaking queue for N players (sorted by MMR)
  3. For each candidate:
     - Send INVITE (timeout 10s)
     - On ACCEPT: Add to lobby, broadcast
     - On REJECT/TIMEOUT: Continue to next
  4. Notify host when full or queue exhausted
```

### Per-Format MMR

```sql
CREATE TABLE player_mmr (
  user_id INTEGER NOT NULL,
  format TEXT NOT NULL,
  rating INTEGER DEFAULT 1000,
  games_played INTEGER DEFAULT 0,
  last_match INTEGER,
  PRIMARY KEY (user_id, format)
);
```

---

## 6. Database Schema

### SQLite Tables

```sql
-- Lobby metadata
CREATE TABLE lobbies (
  id TEXT PRIMARY KEY,
  host_id INTEGER NOT NULL,
  name TEXT,
  type TEXT CHECK(type IN ('CASUAL', 'RANKED')),
  visibility TEXT CHECK(visibility IN ('PUBLIC', 'PRIVATE')),
  min_players INTEGER DEFAULT 2,
  max_players INTEGER DEFAULT 8,
  format TEXT,
  ready_required BOOLEAN DEFAULT TRUE,
  afk_timeout INTEGER DEFAULT 120,
  created_at INTEGER,
  updated_at INTEGER
);

-- Player session in lobby
CREATE TABLE lobby_players (
  lobby_id TEXT REFERENCES lobbies(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL,
  is_ready BOOLEAN DEFAULT FALSE,
  deck_id TEXT,
  joined_at INTEGER,
  PRIMARY KEY (lobby_id, user_id)
);

-- Per-format MMR
CREATE TABLE player_mmr (
  user_id INTEGER NOT NULL,
  format TEXT NOT NULL,
  rating INTEGER DEFAULT 1000,
  games_played INTEGER DEFAULT 0,
  last_match INTEGER,
  PRIMARY KEY (user_id, format)
);

-- Public lobby listing (for visibility = PUBLIC)
CREATE TABLE public_lobbies (
  lobby_id TEXT PRIMARY KEY REFERENCES lobbies(id) ON DELETE CASCADE,
  host_name TEXT,
  player_count INTEGER,
  format TEXT,
  updated_at INTEGER
);

-- Match history (for MMR calculation)
CREATE TABLE matches (
  id TEXT PRIMARY KEY,
  lobby_id TEXT,
  format TEXT,
  winner_user_id INTEGER,
  loser_user_id INTEGER,
  is_ranked BOOLEAN,
  created_at INTEGER
);
```

---

## 7. Cloudflare Tunnel Integration

### Setup

1. Install Cloudflare Tunnels:
   ```bash
   # Install cloudflared
   brew install cloudflared  # macOS
   # or
   sudo apt install cloudflared  # Linux
   ```

2. Authenticate:
   ```bash
   cloudflared tunnel login
   ```

3. Create tunnel:
   ```bash
   cloudflared tunnel create turntide
   ```

4. Configure DNS and tunnel:
   ```bash
   cloudflared tunnel route dns turntide game.yourdomain.com
   ```

5. Run tunnel with config:
   ```yaml
   # ~/.cloudflared/config.yml
   tunnel: turntide
   ingress:
     - hostname: game.yourdomain.com
       service: http://localhost:8080
     - service: http_status:404
   ```

6. Run:
   ```bash
   cloudflared tunnel run turntide
   ```

### Result

Players connect via: `wss://game.yourdomain.com/ws`

---

## 8. Client (GDScript) Components

### Lobby State Hierarchy

```
states/
├── lobby/
│   ├── lobby.gd              # Main lobby state
│   ├── lobby_state.gd        # Base state class
│   ├── pregame_state.gd      # Pre-game state logic
│   ├── ingame_state.gd       # In-game state logic
│   └── gameover_state.gd     # Game over state logic
│
scripts/
├── lobby/
│   ├── lobby_manager.gd       # Lobby operations singleton
│   ├── lobby_handler.gd      # Network message handler
│   ├── url_handler.gd       # Deep link parser
│   └── chat_manager.gd     # Lobby chat
│
scenes/
├── lobby/
│   ├── lobby.tscn           # Lobby scene
│   ├── player_panel.tscn    # Player list
│   ├── settings_panel.tscn  # Lobby settings (host only)
│   └── chat_panel.tscn     # Lobby chat
```

### Key Interfaces

```gdscript
# lobby_manager.gd
class_name LobbyManager
extends Node

signal player_joined(player: LobbyPlayerData)
signal player_left(user_id: int)
signal lobby_state_changed(state: LobbyState)
signal gameStarting()

func create_lobby(settings: LobbySettings) -> String:
    pass

func join_lobby(lobby_id: String) -> bool:
    pass

func leave_lobby() -> void:
    pass

func set_ready(ready: bool) -> void:
    pass

func start_game() -> void:  # Host only
    pass

func request_reconnect() -> void:
    pass
```

---

## 9. Server Components

### Directory Structure

```
server/
├── internal/
│   └── server/
│       ├── lobby/
│       │   ├── registry.go      # Global lobby registry
│       │   ├── lobby.go      # Lobby model
│       │   ├── player.go   # Lobby player
│       │   ├── state.go    # State machine
│       │   ├── handler.go  # Message handling
│       │   └── matchmaking.go  # Ranked queue
│       ├── mmr/
│       │   ├── store.go    # MMR storage
│       │   └── calculator.go
│       └── web/
│           └── lobby_http.go  # HTTP for public lobby list
```

### Core Interfaces

```go
// LobbyRegistry manages all active lobbies
type LobbyRegistry interface {
    Create(ctx context.Context, settings *LobbySettings, hostID uint64) (*Lobby, error)
    Get(id string) (*Lobby, error)
    Join(ctx context.Context, lobbyID string, userID uint64) error
    Leave(ctx context.Context, lobbyID string, userID uint64) error
    Delete(id string) error
    ListPublic(ctx context.Context) ([]*Lobby, error)
}

// LobbyStateHandler handles lobby state transitions
type LobbyStateHandler interface {
    SetState(state LobbyState)
    GetState() LobbyState
    TransitionToPreGame()
    TransitionToInGame()
    TransitionToGameOver()
}
```

---

## 10. Configuration

### Environment Variables

```bash
# Server
TURNTIDE_SERVER_PORT=8080
TURNTIDE_DB_PATH=./turntide.db
TURNTIDE_LOBBY_TIMEOUT=300      # Auto-close idle lobby (5 min)
TURNTIDE_DEFAULT_AFK_TIMEOUT=120 # Seconds

# Cloudflare (optional)
CLOUDFLARE_TUNNEL_TOKEN=       # For cloudflared auth
```

---

## 11. Requirements Coverage

| Requirement | Spec Section |
|-------------|------------|
| 8 players max | Data Model |
| URL shareable link | URL Scheme |
| Pre-game/In-game/Pre-game cycle | State Machine |
| Host migration | Reconnection |
| Per-format MMR | Ranked Matchmaking |
| Auto-fill | Ranked Matchmaking |
| AFK timer (30-120s) | Reconnection |
| Lobby chat | Client Components |
| External connection | Cloudflare Tunnel |
| Per-lobby locking | Architecture |

---

## 12. Non-Goals (Out of Scope)

- Spectator mode for games
- Tournament bracket support
- Replay system
- Deck trading
- In-game voice chat