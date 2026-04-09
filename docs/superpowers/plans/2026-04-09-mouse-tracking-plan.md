# Mouse Position Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Track player mouse position and synchronize across clients with server-side smoothing

**Architecture:** Client sends normalized mouse position when delta exceeds threshold. Server applies EMA smoothing before broadcasting to other clients.

**Tech Stack:** Godot 4.x (GDScript), Go (server)

---

### Task 1: Create MouseTracker.gd

**Files:**
- Create: `client/states/ingame/mouse_tracker.gd`

- [ ] **Step 1: Create MouseTracker.gd**

```gdscript
class_name MouseTracker
extends Node

signal mouse_position_changed(normalized_pos: Vector2)

@export var threshold_px: float = 5.0
@export var viewport: Viewport

var _last_sent_raw_position: Vector2 = Vector2.ZERO
var _initialized: bool = false

func _ready() -> void:
	if viewport == null:
		viewport = get_viewport()

func _process(_delta: float) -> void:
	if viewport == null:
		return
	
	var raw_mouse := viewport.get_mouse_position()
	
	if not _initialized:
		_last_sent_raw_position = raw_mouse
		_initialized = true
		return
	
	var delta := raw_mouse - _last_sent_raw_position
	if delta.length() > threshold_px:
		_last_sent_raw_position = raw_mouse
		_emit_normalized(raw_mouse)

func _emit_normalized(raw_pos: Vector2) -> void:
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x == 0 or viewport_size.y == 0:
		return
	
	var normalized := Vector2(
		raw_pos.x / viewport_size.x,
		raw_pos.y / viewport_size.y
	)
	mouse_position_changed.emit(normalized)

func get_last_normalized() -> Vector2:
	if viewport == null:
		return Vector2.ZERO
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x == 0 or viewport_size.y == 0:
		return Vector2.ZERO
	return Vector2(
		_last_sent_raw_position.x / viewport_size.x,
		_last_sent_raw_position.y / viewport_size.y
	)
```

- [ ] **Step 2: Verify file created**

Run: `ls -la client/states/ingame/mouse_tracker.gd`

---

### Task 2: Add PlayerMessage to network.gd

**Files:**
- Modify: `client/scripts/network/network.gd`

- [ ] **Step 1: Add PlayerMessage class**

Add to end of file (after line 24):

```gdscript
class PlayerMessage extends _packets.PlayerMessage:
	pass
```

- [ ] **Step 2: Verify edit**

Run: `grep -n "class PlayerMessage" client/scripts/network/network.gd`

Expected: line with "class PlayerMessage"

---

### Task 3: Add new_player_msg to factory.gd

**Files:**
- Modify: `client/scripts/network/packets/factory.gd`

- [ ] **Step 1: Add new_player_msg function**

Add at end of file (after line 44):

```gdscript
func new_player_msg(mouse_x: float, mouse_y: float, player_name: String = "", player_id: int = 0) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var player_msg : packets.PlayerMessage = packet.new_player()
	
	if player_id == 0:
		player_id = Global.client_id
	packet.set_sender_id(player_id)
	
	player_msg.set_mouse_x(mouse_x)
	player_msg.set_mouse_y(mouse_y)
	
	return packet
```

- [ ] **Step 2: Verify edit**

Run: `grep -n "new_player_msg" client/scripts/network/packets/factory.gd`

Expected: line with "new_player_msg"

---

### Task 4: Integrate MouseTracker in IngameState

**Files:**
- Modify: `client/states/ingame/ingame.gd`

- [ ] **Step 1: Add MouseTracker integration**

Replace lines 1-41 with:

```gdscript
class_name IngameState
extends SceneHolderState

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger : Log = Global.logger
@onready var mouse_tracker: MouseTracker = $MouseTracker

static func Name() -> String:
	return "Ingame"

func _init() -> void:
	transition_config = preload("res://resources/transitions/slide_left.tres")
	packed_scene = preload("res://states/ingame/ingame.tscn")

func enter() -> void:
	WS.connection_closed.connect(_on_ws_connection_closed)
	WS.packet_received.connect(_on_ws_packet_received)
	
	if mouse_tracker:
		mouse_tracker.mouse_position_changed.connect(_on_mouse_position_changed)
		mouse_tracker.viewport = get_viewport()

	self.enter_scene()

func _on_ws_connection_closed() -> void:
	logger.error("Connection closed")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	var sender_id : int = packet.get_sender_id()
	if packet.has_chat():
		_handle_chat_msg(sender_id, packet.get_chat())

func _handle_chat_msg(sender_id: int, chat_msg: packets.ChatMessage) -> void:
	logger.chat("Client %d" % sender_id, chat_msg.get_msg())

func _on_mouse_position_changed(normalized_pos: Vector2) -> void:
	var packet := factory.new_player_msg(normalized_pos.x, normalized_pos.y)
	var err := WS.send(packet)
	if err:
		logger.error("Error sending mouse position")

func _on_line_edit_text_entered(text: String) -> void:
	var chat_packet : packets.Packet = factory.new_chat_msg(text)
	
	var err : Error = WS.send(chat_packet)
	if err:
		logger.error("Error sending chat message")
	else:
		logger.chat("You", text)
```

- [ ] **Step 2: Verify edit**

Run: `grep -n "mouse_tracker" client/states/ingame/ingame.gd`

Expected: lines with mouse_tracker connection and usage

---

### Task 5: Server - Accept own packets and add smoothing

**Files:**
- Modify: `server/internal/server/states/ingame.go`

- [ ] **Step 1: Add smoothing constant and update HandleMessage**

Replace `HandleMessage` function (lines 48-53):

```go
func (g *InGame) HandleMessage(senderId uint64, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_Player:
		g.handlePlayer(senderId, message)
	}
}

func (g *InGame) handlePlayer(senderId uint64, message *packets.Packet_Player) {
	// Accept packets from our own client for mouse position updates
	if senderId == g.client.Id() {
		g.logger.Debug("Received player update from own client, applying smoothing")
		g.applySmoothing(message.Player.MouseX, message.Player.MouseY)
		return
	}
	// Relay other clients' player updates
	g.client.SocketSendAs(senderId, message)
}
```

- [ ] **Step 2: Add applySmoothing method**

Add after `handlePlayer` (after line 61, before line 63):

```go
const smoothingFactor = 0.3

func (g *InGame) applySmoothing(newMouseX, newMouseY float64) {
	g.player.MouseX = g.player.MouseX*(1-smoothingFactor) + newMouseX*smoothingFactor
	g.player.MouseY = g.player.MouseY*(1-smoothingFactor) + newMouseY*smoothingFactor

	updatePacket := packets.NewPlayer(g.client.Id(), g.player)
	g.client.Broadcast(updatePacket)
}
```

- [ ] **Step 3: Remove simulated movement in syncPlayer**

Replace `syncPlayer` function (lines 71-83):

```go
func (g *InGame) syncPlayer(delta float64) {
	// Server now trusts client mouse positions (with smoothing applied)
	// No more simulated movement - client sends real positions
	
	updatePacket := packets.NewPlayer(g.client.Id(), g.player)
	g.client.Broadcast(updatePacket)
}
```

- [ ] **Step 4: Verify edits**

Run: `grep -n "applySmoothing\|smoothingFactor" server/internal/server/states/ingame.go`

Expected: lines with smoothing implementation

---

### Task 6: Add MouseTracker to scene

**Files:**
- Modify: `client/states/ingame/ingame.tscn`

- [ ] **Step 1: Add MouseTracker node**

Check if file is binary (.tscn), if so add in editor or convert. If text format, add:

```
[node name="MouseTracker" type="Node" parent="."]
script = SubResource("Script")
```

Or via Godot editor - add a Node with script `mouse_tracker.gd`.

- [ ] **Step 2: Verify node exists**

Open scene in Godot and verify MouseTracker node is present

---

### Task 7: Commit changes

- [ ] **Step 1: Stage and commit**

```bash
git add client/states/ingame/mouse_tracker.gd client/states/ingame/ingame.gd client/states/ingame/ingame.tscn client/scripts/network/network.gd client/scripts/network/packets/factory.gd server/internal/server/states/ingame.go docs/superpowers/specs/2026-04-09-mouse-tracking-design.md
git commit -m "feat: add mouse position tracking with server-side smoothing"
```
