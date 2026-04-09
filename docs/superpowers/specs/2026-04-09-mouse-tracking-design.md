# Mouse Position Tracking System Design

**Goal:** Track player mouse position and synchronize across clients with server-side smoothing

## Overview

A client-side class that sends normalized mouse position to the server when it changes beyond a threshold, with server-side EMA smoothing and interpolation.

## Architecture

### Client-Side (`states/ingame/`)

**New class: `MouseTracker.gd`**

```
class_name MouseTracker extends Node

signal mouse_position_changed(normalized_pos: Vector2)

@export var threshold_px: float = 5.0
@export var viewport: Viewport

var _last_sent_raw_position: Vector2
```

**Responsibilities:**
- Track raw mouse position each frame
- Compare against threshold (5px delta)
- Normalize to 0-1 range based on viewport size
- Emit signal with normalized position when threshold exceeded

### Server-Side (`server/internal/server/states/ingame.go`)

**Changes:**
1. Remove simulated mouse movement in `syncPlayer()`
2. Accept `Packet_Player` from own client (change guard at line 56-59)
3. Apply EMA smoothing to incoming mouse positions
4. Broadcast smoothed position to other clients

### Packet Flow

```
Client: mouse moves → threshold check → normalize (0-1) → send PlayerMessage
  ↓
Server: receive → EMA smoothing → broadcast to other clients
  ↓
Other Clients: receive → update local player display
```

## Constants

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Threshold | 5 pixels | Balances responsiveness vs network traffic |
| EMA factor | 0.3 | Smooth but responsive (lower = smoother/more lag) |
| Y direction | 0 = bottom, 1 = top | UV-style normalized coords |

## File Changes

| File | Action |
|------|--------|
| `client/states/ingame/mouse_tracker.gd` | Create |
| `client/states/ingame/ingame.gd` | Modify - integrate MouseTracker |
| `client/scripts/network/network.gd` | Modify - add PlayerMessage class |
| `server/internal/server/states/ingame.go` | Modify - smoothing + accept own packets |

## Acceptance Criteria

1. Client sends mouse position when delta > 5px
2. Mouse position is normalized (0-1 range)
3. Server applies smoothing before broadcasting
4. Other clients receive smooth interpolated positions
5. System works without game-breaking lag
