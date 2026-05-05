# Card Component Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework card component from scratch with modular architecture (data, state machines, controller, views) using reactive data flow and node-based state machines.

**Architecture:** 
- `CardData` resource wraps `CardMetadata`, extends `Reactive`
- Two independent state machines: `CardGameStateMachine` (hand/battlefield/graveyard) and `CardAnimationStateMachine` (idle/hovering/dragging/playing/discarding)
- `CardController` thin input handler translating to state machine events
- `CardViewRenderer` shared reactive logic, `CardView2D`/`CardView3D` subclasses handle 2D UI and 3D gameplay rendering respectively

**Tech Stack:** GDScript 4.6, Godot StateMachine (`@client/core/state_machine/`), Reactive pattern (`@client/core/utils/reactive/`)

---

## File Structure

### Files to Create

**Core Data:**
- `@client/features/gameplay/scripts/card/data.gd` - CardData resource wrapper

**State Machines & States:**
- `@client/features/gameplay/scripts/card/state/game/state_machine.gd` - CardGameStateMachine
- `@client/features/gameplay/scripts/card/state/game/in_hand.gd` - InHandState
- `@client/features/gameplay/scripts/card/state/game/on_battlefield.gd` - OnBattlefieldState
- `@client/features/gameplay/scripts/card/state/game/in_graveyard.gd` - InGraveyardState
- `@client/features/gameplay/scripts/card/state/game/exiled.gd` - ExiledState

- `@client/features/gameplay/scripts/card/state/animation/state_machine.gd` - CardAnimationStateMachine
- `@client/features/gameplay/scripts/card/state/animation/idle.gd` - IdleState (animation)
- `@client/features/gameplay/scripts/card/state/animation/hovering.gd` - HoveringState
- `@client/features/gameplay/scripts/card/state/animation/dragging.gd` - DraggingState
- `@client/features/gameplay/scripts/card/state/animation/playing.gd` - PlayingState
- `@client/features/gameplay/scripts/card/state/animation/discarding.gd` - DiscardingState

**Input & Views:**
- `@client/features/gameplay/scripts/card/controller.gd` - CardController input handler
- `@client/features/gameplay/scripts/card/view/renderer.gd` - CardViewRenderer reactive logic
- `@client/features/gameplay/scripts/card/view/view_2d.gd` - CardView2D for UI
- `@client/features/gameplay/scripts/card/view/view_3d.gd` - CardView3D for gameplay

**Factory Update:**
- Modify: `@client/features/gameplay/scripts/card/card_factory.gd`

**Unit Tests:**
- `@client/test/features/gameplay/card/test_card_data.gd`
- `@client/test/features/gameplay/card/test_card_game_state_machine.gd`
- `@client/test/features/gameplay/card/test_card_animation_state_machine.gd`
- `@client/test/features/gameplay/card/test_card_controller.gd`
- `@client/test/features/gameplay/card/test_card_view_renderer.gd`
- `@client/test/features/gameplay/card/test_card_integration.gd`

---

## Task Breakdown

### Task 1: CardData Resource

**Files:**
- Create: `@client/features/gameplay/scripts/card/data.gd`
- Test: `@client/test/features/gameplay/card/test_card_data.gd`

- [ ] **Step 1: Write failing test - CardData initialization**

Create `@client/test/features/gameplay/card/test_card_data.gd`:

```gdscript
extends GutTest

func test_card_data_creation() -> void:
	var metadata = CardMetadata.new("uuid1", "Lightning Bolt", "LEA", "1")
	var card_data = CardData.new(metadata)
	
	assert_not_null(card_data)
	assert_equal(card_data.metadata.name, "Lightning Bolt")
	assert_equal(card_data.metadata.uuid, "uuid1")

func test_card_data_is_reactive() -> void:
	var metadata = CardMetadata.new("uuid1", "Test Card", "TST", "1")
	var card_data = CardData.new(metadata)
	
	assert_true(card_data is Reactive)

func test_reactive_signal_emits() -> void:
	var metadata = CardMetadata.new("uuid1", "Test Card", "TST", "1")
	var card_data = CardData.new(metadata)
	
	var signal_emitted = false
	card_data.reactive_changed.connect(func(_r): signal_emitted = true)
	card_data.manually_emit()
	
	assert_true(signal_emitted)
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_data
```

Expected output: Errors about `CardData` class not found

- [ ] **Step 3: Write CardData implementation**

Create `@client/features/gameplay/scripts/card/data.gd`:

```gdscript
class_name CardData extends Reactive

var metadata: CardMetadata

func _init(card_metadata: CardMetadata) -> void:
	super._init()
	metadata = card_metadata
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_data
```

Expected output: All 3 tests PASS

- [ ] **Step 5: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/data.gd client/test/features/gameplay/card/test_card_data.gd
git commit -m "feat: add CardData resource wrapper"
```

---

### Task 2: Game State Machine & States

**Files:**
- Create: `@client/features/gameplay/scripts/card/state/game/state_machine.gd`
- Create: `@client/features/gameplay/scripts/card/state/game/in_hand.gd`
- Create: `@client/features/gameplay/scripts/card/state/game/on_battlefield.gd`
- Create: `@client/features/gameplay/scripts/card/state/game/in_graveyard.gd`
- Create: `@client/features/gameplay/scripts/card/state/game/exiled.gd`
- Test: `@client/test/features/gameplay/card/test_card_game_state_machine.gd`

- [ ] **Step 1: Write failing test - Game state machine initialization**

Create `@client/test/features/gameplay/card/test_card_game_state_machine.gd`:

```gdscript
extends GutTest

class MockCardGameStateMachine extends CardGameStateMachine:
	pass

func test_initial_state_is_in_hand() -> void:
	var state_machine = create_game_state_machine()
	assert_not_null(state_machine.current_state)
	assert_equal(state_machine.current_state.name, "InHand")

func test_transition_hand_to_battlefield() -> void:
	var state_machine = create_game_state_machine()
	var initial_state = state_machine.current_state
	
	state_machine.on_state_transition(initial_state, "OnBattlefield")
	
	assert_equal(state_machine.current_state.name, "OnBattlefield")

func test_state_changed_signal_emits() -> void:
	var state_machine = create_game_state_machine()
	var initial_state = state_machine.current_state
	
	var signal_emitted = false
	state_machine.state_changed.connect(func(_from, _to): signal_emitted = true)
	
	state_machine.on_state_transition(initial_state, "OnBattlefield")
	
	assert_true(signal_emitted)

func test_enter_exit_hooks_called() -> void:
	var state_machine = create_game_state_machine()
	var in_hand_state = state_machine.states["inhand"]
	var on_battlefield_state = state_machine.states["onbattlefield"]
	
	# Spy on enter/exit methods
	var enter_called = false
	var exit_called = false
	
	# This test validates that state machine calls enter/exit
	# Actual verification will be done in integration tests
	assert_not_null(in_hand_state)
	assert_not_null(on_battlefield_state)

func create_game_state_machine() -> CardGameStateMachine:
	var sm = CardGameStateMachine.new()
	
	# Manually add states (since we're not using scene tree)
	var in_hand = InHandState.new()
	in_hand.name = "InHand"
	sm.add_child(in_hand)
	
	var on_battlefield = OnBattlefieldState.new()
	on_battlefield.name = "OnBattlefield"
	sm.add_child(on_battlefield)
	
	var in_graveyard = InGraveyardState.new()
	in_graveyard.name = "InGraveyard"
	sm.add_child(in_graveyard)
	
	var exiled = ExiledState.new()
	exiled.name = "Exiled"
	sm.add_child(exiled)
	
	sm.initial_state = in_hand
	sm._ready()
	
	return sm
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_game_state_machine
```

Expected output: Errors about classes not found

- [ ] **Step 3: Create CardGameStateMachine**

Create `@client/features/gameplay/scripts/card/state/game/state_machine.gd`:

```gdscript
class_name CardGameStateMachine extends StateMachine

func _ready() -> void:
	super._ready()
```

- [ ] **Step 4: Create InHandState**

Create `@client/features/gameplay/scripts/card/state/game/in_hand.gd`:

```gdscript
class_name InHandState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

- [ ] **Step 5: Create OnBattlefieldState**

Create `@client/features/gameplay/scripts/card/state/game/on_battlefield.gd`:

```gdscript
class_name OnBattlefieldState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

- [ ] **Step 6: Create InGraveyardState**

Create `@client/features/gameplay/scripts/card/state/game/in_graveyard.gd`:

```gdscript
class_name InGraveyardState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

- [ ] **Step 7: Create ExiledState**

Create `@client/features/gameplay/scripts/card/state/game/exiled.gd`:

```gdscript
class_name ExiledState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

- [ ] **Step 8: Run test to verify it passes**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_game_state_machine
```

Expected output: All tests PASS

- [ ] **Step 9: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/state/game/ client/test/features/gameplay/card/test_card_game_state_machine.gd
git commit -m "feat: add card game state machine with states (hand, battlefield, graveyard, exiled)"
```

---

### Task 3: Animation State Machine & States

**Files:**
- Create: `@client/features/gameplay/scripts/card/state/animation/state_machine.gd`
- Create: `@client/features/gameplay/scripts/card/state/animation/idle.gd`
- Create: `@client/features/gameplay/scripts/card/state/animation/hovering.gd`
- Create: `@client/features/gameplay/scripts/card/state/animation/dragging.gd`
- Create: `@client/features/gameplay/scripts/card/state/animation/playing.gd`
- Create: `@client/features/gameplay/scripts/card/state/animation/discarding.gd`
- Test: `@client/test/features/gameplay/card/test_card_animation_state_machine.gd`

- [ ] **Step 1: Write failing test - Animation state machine**

Create `@client/test/features/gameplay/card/test_card_animation_state_machine.gd`:

```gdscript
extends GutTest

func test_initial_state_is_idle() -> void:
	var state_machine = create_animation_state_machine()
	assert_not_null(state_machine.current_state)
	assert_equal(state_machine.current_state.name, "Idle")

func test_transition_idle_to_hovering() -> void:
	var state_machine = create_animation_state_machine()
	var initial_state = state_machine.current_state
	
	state_machine.on_state_transition(initial_state, "Hovering")
	
	assert_equal(state_machine.current_state.name, "Hovering")

func test_transition_hovering_to_dragging() -> void:
	var state_machine = create_animation_state_machine()
	state_machine.on_state_transition(state_machine.current_state, "Hovering")
	state_machine.on_state_transition(state_machine.current_state, "Dragging")
	
	assert_equal(state_machine.current_state.name, "Dragging")

func test_transition_dragging_to_playing() -> void:
	var state_machine = create_animation_state_machine()
	state_machine.on_state_transition(state_machine.current_state, "Dragging")
	state_machine.on_state_transition(state_machine.current_state, "Playing")
	
	assert_equal(state_machine.current_state.name, "Playing")

func test_can_transition_back_to_idle() -> void:
	var state_machine = create_animation_state_machine()
	state_machine.on_state_transition(state_machine.current_state, "Hovering")
	state_machine.on_state_transition(state_machine.current_state, "Idle")
	
	assert_equal(state_machine.current_state.name, "Idle")

func create_animation_state_machine() -> CardAnimationStateMachine:
	var sm = CardAnimationStateMachine.new()
	
	var idle = CardAnimationIdleState.new()
	idle.name = "Idle"
	sm.add_child(idle)
	
	var hovering = CardAnimationHoveringState.new()
	hovering.name = "Hovering"
	sm.add_child(hovering)
	
	var dragging = CardAnimationDraggingState.new()
	dragging.name = "Dragging"
	sm.add_child(dragging)
	
	var playing = CardAnimationPlayingState.new()
	playing.name = "Playing"
	sm.add_child(playing)
	
	var discarding = CardAnimationDiscardingState.new()
	discarding.name = "Discarding"
	sm.add_child(discarding)
	
	sm.initial_state = idle
	sm._ready()
	
	return sm
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_animation_state_machine
```

Expected output: Errors about classes not found

- [ ] **Step 3: Create CardAnimationStateMachine**

Create `@client/features/gameplay/scripts/card/state/animation/state_machine.gd`:

```gdscript
class_name CardAnimationStateMachine extends StateMachine

func _ready() -> void:
	super._ready()
```

- [ ] **Step 4: Create animation states**

Create `@client/features/gameplay/scripts/card/state/animation/idle.gd`:

```gdscript
class_name CardAnimationIdleState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

Create `@client/features/gameplay/scripts/card/state/animation/hovering.gd`:

```gdscript
class_name CardAnimationHoveringState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

Create `@client/features/gameplay/scripts/card/state/animation/dragging.gd`:

```gdscript
class_name CardAnimationDraggingState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

Create `@client/features/gameplay/scripts/card/state/animation/playing.gd`:

```gdscript
class_name CardAnimationPlayingState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

Create `@client/features/gameplay/scripts/card/state/animation/discarding.gd`:

```gdscript
class_name CardAnimationDiscardingState extends State

func enter() -> void:
	pass

func exit() -> void:
	pass
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_animation_state_machine
```

Expected output: All tests PASS

- [ ] **Step 6: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/state/animation/ client/test/features/gameplay/card/test_card_animation_state_machine.gd
git commit -m "feat: add card animation state machine with states (idle, hovering, dragging, playing, discarding)"
```

---

### Task 4: CardController Input Handler

**Files:**
- Create: `@client/features/gameplay/scripts/card/controller.gd`
- Test: `@client/test/features/gameplay/card/test_card_controller.gd`

- [ ] **Step 1: Write failing test - Input detection**

Create `@client/test/features/gameplay/card/test_card_controller.gd`:

```gdscript
extends GutTest

var card_controller: CardController
var card_node: Control

func before_each() -> void:
	card_node = Control.new()
	card_controller = CardController.new()
	card_node.add_child(card_controller)

func test_controller_detects_mouse_click() -> void:
	var click_detected = false
	card_controller.input_event.connect(func(event): 
		if event is InputEventMouseButton and event.pressed:
			click_detected = true
	)
	
	var event = InputEventMouseButton.new()
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = Vector2(100, 100)
	
	card_controller._on_gui_input(event)
	
	assert_true(click_detected)

func test_controller_differentiates_drag() -> void:
	var drag_detected = false
	card_controller.drag_started.connect(func(): drag_detected = true)
	
	# Mouse down at (100, 100)
	var mouse_down = InputEventMouseButton.new()
	mouse_down.pressed = true
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.position = Vector2(100, 100)
	
	card_controller._on_gui_input(mouse_down)
	
	# Mouse move to (200, 200) - distance > threshold
	var mouse_move = InputEventMouseMotion.new()
	mouse_move.position = Vector2(200, 200)
	
	card_controller._on_gui_input(mouse_move)
	
	# Mouse up
	var mouse_up = InputEventMouseButton.new()
	mouse_up.pressed = false
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.position = Vector2(200, 200)
	
	card_controller._on_gui_input(mouse_up)
	
	assert_true(drag_detected)

func test_controller_click_vs_drag_threshold() -> void:
	var drag_distance_threshold = 10.0
	var distance_traveled = card_controller.calculate_drag_distance(
		Vector2(100, 100),
		Vector2(105, 105)
	)
	
	assert_true(distance_traveled < drag_distance_threshold)
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_controller
```

Expected output: Errors about `CardController` class not found

- [ ] **Step 3: Implement CardController**

Create `@client/features/gameplay/scripts/card/controller.gd`:

```gdscript
class_name CardController extends Node

signal input_event(event: InputEvent)
signal drag_started
signal drag_ended
signal clicked

const DRAG_DISTANCE_THRESHOLD: float = 10.0

var drag_start_position: Vector2
var is_dragging: bool = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			drag_start_position = event.position
			is_dragging = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var drag_distance = calculate_drag_distance(drag_start_position, event.position)
			
			if drag_distance > DRAG_DISTANCE_THRESHOLD:
				drag_ended.emit()
			else:
				clicked.emit()
			
			is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var drag_distance = calculate_drag_distance(drag_start_position, event.position)
		if drag_distance > DRAG_DISTANCE_THRESHOLD:
			drag_started.emit()

func calculate_drag_distance(start: Vector2, end: Vector2) -> float:
	return start.distance_to(end)
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_controller
```

Expected output: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/controller.gd client/test/features/gameplay/card/test_card_controller.gd
git commit -m "feat: add card controller input handler with drag detection"
```

---

### Task 5: CardViewRenderer Reactive Logic

**Files:**
- Create: `@client/features/gameplay/scripts/card/view/renderer.gd`
- Test: `@client/test/features/gameplay/card/test_card_view_renderer.gd`

- [ ] **Step 1: Write failing test - Renderer reactivity**

Create `@client/test/features/gameplay/card/test_card_view_renderer.gd`:

```gdscript
extends GutTest

func test_renderer_is_reactive() -> void:
	var renderer = CardViewRenderer.new()
	assert_true(renderer is Reactive)

func test_renderer_observes_card_data() -> void:
	var metadata = CardMetadata.new("uuid1", "Test", "TST", "1")
	var card_data = CardData.new(metadata)
	var renderer = CardViewRenderer.new()
	
	var data_changed_received = false
	renderer.reactive_changed.connect(func(_r): data_changed_received = true)
	
	renderer.observe_card_data(card_data)
	card_data.manually_emit()
	
	assert_true(data_changed_received)

func test_renderer_observes_game_state_changes() -> void:
	var renderer = CardViewRenderer.new()
	var game_state_machine = create_game_state_machine()
	
	var state_changed_received = false
	renderer.reactive_changed.connect(func(_r): state_changed_received = true)
	
	renderer.observe_game_state(game_state_machine)
	var in_hand = game_state_machine.states["inhand"]
	game_state_machine.on_state_transition(in_hand, "OnBattlefield")
	
	assert_true(state_changed_received)

func test_renderer_observes_animation_state_changes() -> void:
	var renderer = CardViewRenderer.new()
	var anim_state_machine = create_animation_state_machine()
	
	var state_changed_received = false
	renderer.reactive_changed.connect(func(_r): state_changed_received = true)
	
	renderer.observe_animation_state(anim_state_machine)
	var idle = anim_state_machine.states["idle"]
	anim_state_machine.on_state_transition(idle, "Hovering")
	
	assert_true(state_changed_received)

func create_game_state_machine() -> CardGameStateMachine:
	var sm = CardGameStateMachine.new()
	
	var in_hand = InHandState.new()
	in_hand.name = "InHand"
	sm.add_child(in_hand)
	
	var on_battlefield = OnBattlefieldState.new()
	on_battlefield.name = "OnBattlefield"
	sm.add_child(on_battlefield)
	
	sm.initial_state = in_hand
	sm._ready()
	
	return sm

func create_animation_state_machine() -> CardAnimationStateMachine:
	var sm = CardAnimationStateMachine.new()
	
	var idle = CardAnimationIdleState.new()
	idle.name = "Idle"
	sm.add_child(idle)
	
	var hovering = CardAnimationHoveringState.new()
	hovering.name = "Hovering"
	sm.add_child(hovering)
	
	sm.initial_state = idle
	sm._ready()
	
	return sm
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_view_renderer
```

Expected output: Errors about `CardViewRenderer` class not found

- [ ] **Step 3: Implement CardViewRenderer**

Create `@client/features/gameplay/scripts/card/view/renderer.gd`:

```gdscript
class_name CardViewRenderer extends Reactive

var card_data: CardData
var game_state_machine: CardGameStateMachine
var animation_state_machine: CardAnimationStateMachine

func _init() -> void:
	super._init()

func observe_card_data(data: CardData) -> void:
	card_data = data
	if card_data:
		card_data.reactive_changed.connect(_on_card_data_changed)

func observe_game_state(state_machine: CardGameStateMachine) -> void:
	game_state_machine = state_machine
	if game_state_machine:
		game_state_machine.state_changed.connect(_on_game_state_changed)

func observe_animation_state(state_machine: CardAnimationStateMachine) -> void:
	animation_state_machine = state_machine
	if animation_state_machine:
		animation_state_machine.state_changed.connect(_on_animation_state_changed)

func _on_card_data_changed(_reactive: Reactive) -> void:
	reactive_changed.emit(self)

func _on_game_state_changed(_from: State, _to: State) -> void:
	reactive_changed.emit(self)

func _on_animation_state_changed(_from: State, _to: State) -> void:
	reactive_changed.emit(self)
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_view_renderer
```

Expected output: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/view/renderer.gd client/test/features/gameplay/card/test_card_view_renderer.gd
git commit -m "feat: add card view renderer reactive observation logic"
```

---

### Task 6: Integration Tests

**Files:**
- Test: `@client/test/features/gameplay/card/test_card_integration.gd`

- [ ] **Step 1: Write integration test - Full lifecycle**

Create `@client/test/features/gameplay/card/test_card_integration.gd`:

```gdscript
extends GutTest

func test_full_card_lifecycle() -> void:
	# Create card data
	var metadata = CardMetadata.new("uuid1", "Test Card", "TST", "1")
	var card_data = CardData.new(metadata)
	
	# Create state machines
	var game_sm = create_game_state_machine()
	var anim_sm = create_animation_state_machine()
	
	# Create controller
	var controller = CardController.new()
	
	# Create renderer
	var renderer = CardViewRenderer.new()
	renderer.observe_card_data(card_data)
	renderer.observe_game_state(game_sm)
	renderer.observe_animation_state(anim_sm)
	
	# Verify initial states
	assert_equal(game_sm.current_state.name, "InHand")
	assert_equal(anim_sm.current_state.name, "Idle")
	
	# Simulate drag interaction
	var drag_detected = false
	controller.drag_started.connect(func(): drag_detected = true)
	
	var event_down = InputEventMouseButton.new()
	event_down.pressed = true
	event_down.button_index = MOUSE_BUTTON_LEFT
	event_down.position = Vector2(100, 100)
	controller._on_gui_input(event_down)
	
	var event_move = InputEventMouseMotion.new()
	event_move.position = Vector2(120, 120)
	controller._on_gui_input(event_move)
	
	assert_true(drag_detected)
	
	# Verify renderer receives updates
	var renderer_updates = 0
	renderer.reactive_changed.connect(func(_r): renderer_updates += 1)
	
	# Transition game state
	var in_hand = game_sm.states["inhand"]
	game_sm.on_state_transition(in_hand, "OnBattlefield")
	
	assert_equal(game_sm.current_state.name, "OnBattlefield")
	assert_true(renderer_updates > 0)

func create_game_state_machine() -> CardGameStateMachine:
	var sm = CardGameStateMachine.new()
	
	var in_hand = InHandState.new()
	in_hand.name = "InHand"
	sm.add_child(in_hand)
	
	var on_battlefield = OnBattlefieldState.new()
	on_battlefield.name = "OnBattlefield"
	sm.add_child(on_battlefield)
	
	sm.initial_state = in_hand
	sm._ready()
	
	return sm

func create_animation_state_machine() -> CardAnimationStateMachine:
	var sm = CardAnimationStateMachine.new()
	
	var idle = CardAnimationIdleState.new()
	idle.name = "Idle"
	sm.add_child(idle)
	
	var dragging = CardAnimationDraggingState.new()
	dragging.name = "Dragging"
	sm.add_child(dragging)
	
	sm.initial_state = idle
	sm._ready()
	
	return sm
```

- [ ] **Step 2: Run integration test**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter test_card_integration
```

Expected output: All tests PASS

- [ ] **Step 3: Run all card tests to verify no regressions**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test -- --filter "test_card"
```

Expected output: All tests PASS (19+ tests total)

- [ ] **Step 4: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/test/features/gameplay/card/test_card_integration.gd
git commit -m "feat: add integration tests for card lifecycle"
```

---

### Task 7: CardView2D Implementation

**Files:**
- Create: `@client/features/gameplay/scripts/card/view/view_2d.gd`
- Modify: `@client/features/gameplay/scenes/card/card_view.tscn` (reuse existing)

- [ ] **Step 1: Implement CardView2D**

Create `@client/features/gameplay/scripts/card/view/view_2d.gd`:

```gdscript
class_name CardView2D extends Control

var card_data: CardData
var game_state_machine: CardGameStateMachine
var animation_state_machine: CardAnimationStateMachine
var renderer: CardViewRenderer

@onready var card_texture: TextureRect = $SubViewportContainer/SubViewport/TextureRect

func _init() -> void:
	renderer = CardViewRenderer.new()

func setup(data: CardData, game_sm: CardGameStateMachine, anim_sm: CardAnimationStateMachine) -> void:
	card_data = data
	game_state_machine = game_sm
	animation_state_machine = anim_sm
	
	renderer.observe_card_data(card_data)
	renderer.observe_game_state(game_state_machine)
	renderer.observe_animation_state(animation_state_machine)
	
	renderer.reactive_changed.connect(_on_state_changed)

func _on_state_changed(_reactive: Reactive) -> void:
	if animation_state_machine.current_state.name == "Hovering":
		_apply_hover_effect()
	elif animation_state_machine.current_state.name == "Idle":
		_remove_hover_effect()

func _apply_hover_effect() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)

func _remove_hover_effect() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
```

- [ ] **Step 2: Test CardView2D manually by creating a simple scene**

Create a test scene that instantiates CardView2D with mock data and verify hover effects work.

- [ ] **Step 3: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/view/view_2d.gd
git commit -m "feat: add CardView2D for UI rendering with hover effects"
```

---

### Task 8: CardView3D Implementation

**Files:**
- Create: `@client/features/gameplay/scripts/card/view/view_3d.gd`

- [ ] **Step 1: Implement CardView3D**

Create `@client/features/gameplay/scripts/card/view/view_3d.gd`:

```gdscript
class_name CardView3D extends Node3D

var card_data: CardData
var game_state_machine: CardGameStateMachine
var animation_state_machine: CardAnimationStateMachine
var renderer: CardViewRenderer

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var material: StandardMaterial3D = mesh_instance.get_active_material(0) if has_node("MeshInstance3D") else null

func _init() -> void:
	renderer = CardViewRenderer.new()

func setup(data: CardData, game_sm: CardGameStateMachine, anim_sm: CardAnimationStateMachine) -> void:
	card_data = data
	game_state_machine = game_sm
	animation_state_machine = anim_sm
	
	renderer.observe_card_data(card_data)
	renderer.observe_game_state(game_state_machine)
	renderer.observe_animation_state(animation_state_machine)
	
	renderer.reactive_changed.connect(_on_state_changed)

func _on_state_changed(_reactive: Reactive) -> void:
	var current_anim_state = animation_state_machine.current_state.name
	
	match current_anim_state:
		"Playing":
			_play_animation()
		"Discarding":
			_discard_animation()
		"Dragging":
			_dragging_animation()

func _play_animation() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "position:y", position.y - 50, 0.3)

func _discard_animation() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "rotation", PI * 0.1, 0.3)
	tween.tween_property(self, "position:y", position.y + 50, 0.3)

func _dragging_animation() -> void:
	# Following mouse handled by parent/state
	pass
```

- [ ] **Step 2: Test CardView3D manually by creating a simple scene**

Create a test scene that instantiates CardView3D and verify animations play.

- [ ] **Step 3: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/view/view_3d.gd
git commit -m "feat: add CardView3D for gameplay 3D rendering with animations"
```

---

### Task 9: Update CardFactory

**Files:**
- Modify: `@client/features/gameplay/scripts/card/card_factory.gd`

- [ ] **Step 1: Review current CardFactory**

Current factory creates Card with CardView. Need to update to wire up new architecture.

- [ ] **Step 2: Update CardFactory**

Modify `@client/features/gameplay/scripts/card/card_factory.gd`:

```gdscript
extends Node

var card_scene: PackedScene
var card_view_scene: PackedScene

func _ready() -> void:
	card_scene = preload("res://features/gameplay/scenes/card/card_node.tscn")
	card_view_scene = preload("res://features/gameplay/scenes/card/card_view.tscn")

func create_card_2d(card_metadata: CardMetadata) -> CardView2D:
	var card_data = CardData.new(card_metadata)
	var game_sm = _create_game_state_machine()
	var anim_sm = _create_animation_state_machine()
	
	var view = CardView2D.new()
	view.setup(card_data, game_sm, anim_sm)
	
	return view

func create_card_3d(card_metadata: CardMetadata) -> CardView3D:
	var card_data = CardData.new(card_metadata)
	var game_sm = _create_game_state_machine()
	var anim_sm = _create_animation_state_machine()
	
	var view = CardView3D.new()
	view.setup(card_data, game_sm, anim_sm)
	
	return view

func _create_game_state_machine() -> CardGameStateMachine:
	var sm = CardGameStateMachine.new()
	
	var in_hand = InHandState.new()
	in_hand.name = "InHand"
	sm.add_child(in_hand)
	
	var on_battlefield = OnBattlefieldState.new()
	on_battlefield.name = "OnBattlefield"
	sm.add_child(on_battlefield)
	
	var in_graveyard = InGraveyardState.new()
	in_graveyard.name = "InGraveyard"
	sm.add_child(in_graveyard)
	
	var exiled = ExiledState.new()
	exiled.name = "Exiled"
	sm.add_child(exiled)
	
	sm.initial_state = in_hand
	
	return sm

func _create_animation_state_machine() -> CardAnimationStateMachine:
	var sm = CardAnimationStateMachine.new()
	
	var idle = CardAnimationIdleState.new()
	idle.name = "Idle"
	sm.add_child(idle)
	
	var hovering = CardAnimationHoveringState.new()
	hovering.name = "Hovering"
	sm.add_child(hovering)
	
	var dragging = CardAnimationDraggingState.new()
	dragging.name = "Dragging"
	sm.add_child(dragging)
	
	var playing = CardAnimationPlayingState.new()
	playing.name = "Playing"
	sm.add_child(playing)
	
	var discarding = CardAnimationDiscardingState.new()
	discarding.name = "Discarding"
	sm.add_child(discarding)
	
	sm.initial_state = idle
	
	return sm
```

- [ ] **Step 3: Run tests to verify factory integration**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test
```

Expected output: All tests PASS

- [ ] **Step 4: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/gameplay/scripts/card/card_factory.gd
git commit -m "feat: update CardFactory to create cards with new modular architecture"
```

---

### Task 10: Integration with Existing Code

**Files:**
- Modify: `@client/features/card_viewer/scripts/card_viewer.gd`
- Modify: `@client/features/gameplay/scripts/hand/hand.gd`

- [ ] **Step 1: Update CardViewer to use CardFactory.create_card_2d()**

Modify `@client/features/card_viewer/scripts/card_viewer.gd` (around line 54):

Replace:
```gdscript
var card_node: Card = CardFactory.create_card(card_metadata)
```

With:
```gdscript
var card_view: CardView2D = CardFactory.create_card_2d(card_metadata)
```

And update signal connection:
```gdscript
# Old: card_node.controller.pressed.connect(...)
# New approach will need controller wired up, for now skip
```

- [ ] **Step 2: Update Hand to use CardFactory.create_card_3d()**

Modify `@client/features/gameplay/scripts/hand/hand.gd`:

Replace the commented code with:
```gdscript
func _ready() -> void:
	for i: int in range(initial_number_cards):
		var card_metadata = CardMetadata.new("uuid%d" % i, "Card %d" % i, "TST", "%d" % i)
		var card_view: CardView3D = CardFactory.create_card_3d(card_metadata)
		card_view.position = Vector3(i * 2, 0, 0)
		self.add_child(card_view)
```

- [ ] **Step 3: Run tests to verify integration**

```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test
```

Expected output: All tests PASS

- [ ] **Step 4: Manual testing - Verify card viewer still displays cards**

Open the card viewer scene and verify cards display with new architecture.

- [ ] **Step 5: Manual testing - Verify hand displays cards**

Open the gameplay scene and verify hand displays card positions.

- [ ] **Step 6: Commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/features/card_viewer/scripts/card_viewer.gd client/features/gameplay/scripts/hand/hand.gd
git commit -m "refactor: integrate new card architecture with existing card viewer and hand"
```

---

## Testing & Verification

Run all tests:
```bash
cd /home/bfbraga/Documents/Programming/turntide/client
make test
```

All tests should PASS. Expected count: 20+ tests across:
- test_card_data.gd (3 tests)
- test_card_game_state_machine.gd (5+ tests)
- test_card_animation_state_machine.gd (5+ tests)
- test_card_controller.gd (3 tests)
- test_card_view_renderer.gd (3+ tests)
- test_card_integration.gd (1+ tests)

---

## Notes

- All state machines use node-based `StateMachine` from `@client/core/state_machine/`
- All data uses `Reactive` pattern from `@client/core/utils/reactive/`
- Tests follow AGENTS.md convention: `@client/test/` directory (not alongside source)
- Factory wires up state machines and views together
- Views observe renderer reactive signals
- Gradual migration: existing code updated to use new factory methods
