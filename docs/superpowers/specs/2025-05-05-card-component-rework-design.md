# Card Component Rework Design

**Date:** 2025-05-05  
**Status:** Design Approved  
**Approach:** Approach 1 - Clean Separation with Resource-Based State

## Overview

Rework the card component from scratch with clear module separation and reactive data flow. The card will be used in two contexts:
- **Gameplay (3D):** Cards rendered as 3D objects on the battlefield
- **UI (2D):** Cards displayed in card search grid, hand, and deck builder

### Architecture

```
Input Events → CardController → Game/Animation State Machines → CardView (2D/3D)
                     ↓                      ↓
              CardData (shared reactive resource)
```

**Data Flow:** User input → Controller translates to state events → State machines process transitions → Reactive values update → Views react automatically.

## Modules

### 1. CardData Module

**File:** `@client/features/gameplay/scripts/card/data.gd`  
**Purpose:** Immutable card identity resource

**Structure:**
- `CardData` extends `Reactive`
  - Holds: `metadata: CardMetadata` (uuid, name, setcode, mana_value, type_line, text, power, toughness, foil_type, etc.)
  - Wraps CardMetadata for reactive integration
  - No runtime state (game zone, selection, etc.) - that's in state machines

**Usage:**
```gdscript
var card_data = CardData.new(card_metadata)
# Access metadata properties
print(card_data.metadata.name)
```

### 2. CardState Modules

Separate state machines for game state and animation state. Both extend `StateMachine` from `@client/core/state_machine/`.

#### 2.1 Game State Machine

**Directory:** `@client/features/gameplay/scripts/card/state/game/`

**Purpose:** Track card's location/zone in the game

**Main class:** `CardGameStateMachine` extends `StateMachine`

**States:**
- `InHandState` - card in player's hand
- `OnBattlefieldState` - card on the battlefield
- `InGraveyardState` - card in graveyard
- `ExiledState` - card in exile

**Features:**
- Each state implements `enter()` and `exit()` hooks
- Emits `state_changed(from: State, to: State)` signal
- Child states accessible via `states` dictionary

**Transitions:**
- Triggered by: gameplay events (play, discard, exile, etc.)
- Validated by: state machine (prevents invalid transitions)

#### 2.2 Animation State Machine

**Directory:** `@client/features/gameplay/scripts/card/state/animation/`

**Purpose:** Manage visual/animation effects independent of game state

**Main class:** `CardAnimationStateMachine` extends `StateMachine`

**States:**
- `IdleState` - card at rest (no animation)
- `HoveringState` - mouse hovering over card
- `DraggingState` - card being dragged
- `PlayingState` - card play animation (fade out, scale up, move)
- `DiscardingState` - card discard animation (rotate, fade out)

**Features:**
- Each state can control visual effects (tweens, shader parameters, etc.)
- States can transition without game state changing
- Can respond to game state changes (e.g., entering `OnBattlefieldState` triggers play animation)

**Transitions:**
- Triggered by: controller input (mouse events) and game events
- Example: drag start → transition to `DraggingState`

### 3. CardController Module

**File:** `@client/features/gameplay/scripts/card/controller.gd`  
**Purpose:** Thin input handler, translates input events to state machine transitions

**Structure:**
- `CardController` extends `Node`
- Receives: card's `gui_input` signals (clicks, drags, mouse enter/exit)
- Processes: detects drag vs click, calculates drag distance
- Calls: state machine methods (e.g., `start_drag()`, `play()`, `discard()`)

**Responsibilities:**
- Listen to `gui_input` events
- Detect interactions: click, drag, hover enter/exit
- Forward to state machines via method calls
- No state logic - just translates input → events

**Mouse Hover Effects:** Handled by view layer, not controller

**Key Methods:**
- `_on_gui_input(event: InputEvent)` - main input handler
- `_detect_drag_start()` - check if drag threshold exceeded
- `_detect_drag_end()` - finalize drag, emit drag event

### 4. CardView Module

**Directory:** `@client/features/gameplay/scripts/card/view/`  
**Purpose:** Reactive view layer that observes CardData and state machines, updates visualization

#### 4.1 CardViewRenderer (Utility)

**File:** `@client/features/gameplay/scripts/card/view/renderer.gd`  
**Purpose:** Shared reactive observation logic

**Structure:**
- `CardViewRenderer` extends `Reactive`
- Observes: `card_data.reactive_changed` and state machine `state_changed` signals
- Provides: methods for view updates (`update_image()`, `on_state_changed()`, etc.)
- Not a Node itself - just reactive logic and utility methods

**Responsibilities:**
- React to card data changes (e.g., foil type)
- React to game state changes (e.g., play animation when entering OnBattlefieldState)
- React to animation state changes (e.g., apply hover effects when entering HoveringState)
- Emit reactive signals that views observe

#### 4.2 CardView2D

**File:** `@client/features/gameplay/scripts/card/view/view_2d.gd`  
**Purpose:** 2D UI rendering (card viewer, hand, deck builder)

**Structure:**
- `CardView2D` extends `Control`
- Owns: `CardViewRenderer` instance
- Child nodes: SubViewportContainer, TextureRect, FoilOverlay, etc. (from current card_view.tscn)

**Responsibilities:**
- Load and display card image (TextureRect)
- Handle mouse hover effects (scale, shader parameters)
- React to animation state (hovering → scale up, dragging → follow mouse)
- React to selection state (visual highlight)

#### 4.3 CardView3D

**File:** `@client/features/gameplay/scripts/card/view/view_3d.gd`  
**Purpose:** 3D gameplay rendering

**Structure:**
- `CardView3D` extends `Node3D`
- Owns: `CardViewRenderer` instance
- Child nodes: MeshInstance3D, Material, AnimationPlayer (for animations)

**Responsibilities:**
- Render card as 3D plane/mesh
- Load card image onto 3D material
- Handle 3D animations (play animation, discard animation)
- React to state changes with 3D-specific effects

## Complete File Structure

```
@client/features/gameplay/scripts/card/
├── data.gd                          (CardData resource)
├── controller.gd                    (CardController input handler)
├── factory.gd                       (CardFactory - creates card instances)
├── view/
│   ├── renderer.gd                  (CardViewRenderer utility)
│   ├── view_2d.gd                   (CardView2D for UI)
│   └── view_3d.gd                   (CardView3D for gameplay)
└── state/
    ├── game/
    │   ├── state_machine.gd         (CardGameStateMachine)
    │   ├── in_hand.gd               (InHandState)
    │   ├── on_battlefield.gd        (OnBattlefieldState)
    │   ├── in_graveyard.gd          (InGraveyardState)
    │   └── exiled.gd                (ExiledState)
    └── animation/
        ├── state_machine.gd         (CardAnimationStateMachine)
        ├── idle.gd                  (IdleState)
        ├── hovering.gd              (HoveringState)
        ├── dragging.gd              (DraggingState)
        ├── playing.gd               (PlayingState)
        └── discarding.gd            (DiscardingState)
```

## Integration & Data Flow

### Initialization

1. Create `CardData` from `CardMetadata`
2. Create `CardGameStateMachine` (child nodes are states)
3. Create `CardAnimationStateMachine` (child nodes are states)
4. Create `CardController`
5. Create `CardView2D` or `CardView3D` (with internal `CardViewRenderer`)
6. Wire them together in a parent `Card` node or container

### Runtime Interaction

**User clicks card in hand:**
1. `CardController` receives `gui_input` (mouse click)
2. Controller detects: it's a click (not drag, distance < threshold)
3. Controller calls: some game handler method (e.g., `select()`)
4. Game handler triggers: `CardAnimationStateMachine.transition_to("hovering")`
5. `HoveringState.enter()` is called
6. View reacts to state change: scale up, apply hover shader

**User drags and plays card:**
1. `CardController` receives `gui_input` (mouse down)
2. Controller detects: drag (distance > threshold after mouse move)
3. `CardAnimationStateMachine` transitions to `DraggingState`
4. `DraggingState.update()` follows mouse
5. View follows mouse position (CardView3D updates transform, CardView2D updates position)
6. On drop, game handler calls: `CardGameStateMachine.transition_to("on_battlefield")`
7. Game state change triggers: `CardAnimationStateMachine.transition_to("playing")`
8. `PlayingState.enter()` plays animation (fade out, scale up, etc.)
9. View animates the card off-screen

### Reactive Chain Example

```
User Input (mouse down, drag)
  ↓
CardController._on_gui_input() detects drag
  ↓
CardAnimationStateMachine.start_drag() (or direct transition)
  ↓
DraggingState.enter() emits state_changed signal
  ↓
CardViewRenderer observes state_changed
  ↓
View.update_for_dragging() - update position, visual effects
  ↓
CardView2D/3D renders changes
```

## Testing Strategy

### Unit Tests

Unit tests are located in `@client/test/features/gameplay/card/` directory (following AGENTS.md convention of `test/` folder, not alongside source files).

#### CardData Unit Tests
- **File:** `test/features/gameplay/card/test_card_data.gd`
- **Tests:**
  - `test_card_data_creation()` - CardData initializes with CardMetadata
  - `test_card_data_is_reactive()` - CardData extends Reactive, emits reactive_changed signal
  - `test_card_metadata_access()` - access metadata properties via CardData
  - `test_reactive_signal_emits()` - manually_emit() signal propagation

#### CardGameStateMachine Unit Tests
- **File:** `test/features/gameplay/card/test_card_game_state_machine.gd`
- **Tests:**
  - `test_initial_state_is_in_hand()` - game state machine starts in InHandState
  - `test_transition_hand_to_battlefield()` - valid transition from InHandState to OnBattlefieldState
  - `test_transition_battlefield_to_graveyard()` - valid transition after discard
  - `test_invalid_transition_battlefield_to_hand()` - prevent invalid transitions
  - `test_state_changed_signal_emits()` - state_changed signal fires on transition
  - `test_enter_exit_hooks_called()` - verify enter() and exit() called on state change
  - `test_state_lookup_by_name()` - states dictionary lookup works
  - `test_multiple_transitions()` - sequence of valid transitions (hand → battlefield → graveyard)

#### CardAnimationStateMachine Unit Tests
- **File:** `test/features/gameplay/card/test_card_animation_state_machine.gd`
- **Tests:**
  - `test_initial_state_is_idle()` - animation state machine starts in IdleState
  - `test_transition_idle_to_hovering()` - valid transition on hover
  - `test_transition_hovering_to_dragging()` - transition when drag starts
  - `test_transition_dragging_to_playing()` - transition when card played
  - `test_invalid_transition_playing_to_dragging()` - prevent invalid animation transitions
  - `test_can_transition_while_in_any_game_state()` - animation state independent of game state
  - `test_enter_exit_hooks_called()` - verify animation enter() and exit() called

#### CardController Unit Tests
- **File:** `test/features/gameplay/card/test_card_controller.gd`
- **Tests:**
  - `test_controller_detects_mouse_click()` - InputEventMouseButton pressed
  - `test_controller_detects_drag_start()` - mouse down + small movement
  - `test_controller_detects_drag_end()` - mouse up after drag
  - `test_controller_differentiates_click_vs_drag()` - click when distance < threshold, drag when distance > threshold
  - `test_controller_drag_distance_calculation()` - correct distance calculation between start and end
  - `test_controller_mouse_enter_exit()` - mouse_entered and mouse_exited signal handling

#### CardViewRenderer Unit Tests
- **File:** `test/features/gameplay/card/test_card_view_renderer.gd`
- **Tests:**
  - `test_renderer_is_reactive()` - CardViewRenderer extends Reactive
  - `test_renderer_observes_card_data()` - connects to card_data.reactive_changed
  - `test_renderer_observes_game_state_changes()` - connects to game state machine state_changed
  - `test_renderer_observes_animation_state_changes()` - connects to animation state machine state_changed
  - `test_renderer_emits_on_data_change()` - propagates reactive_changed when observed values change

### Integration Tests

- **File:** `test/features/gameplay/card/test_card_integration.gd`
- **Tests:**
  - `test_full_card_lifecycle()` - create card, transition states, verify signals fire
  - `test_input_to_state_change()` - controller input → state machine transition → reactive signal
  - `test_concurrent_game_and_animation_states()` - game state and animation state transition independently
  - `test_multiple_cards_isolated_state()` - multiple cards don't interfere with each other's state

### Visual Tests

- Manual testing for 2D and 3D rendering
- Verify animations play correctly (play, discard animations)
- Verify hover effects scale/shader correctly
- Verify drag following works in both 2D and 3D

## Implementation Order

1. `CardData` - simple wrapper, lowest complexity → **Write unit tests**
2. `CardGameStateMachine` and states - game logic foundation → **Write unit tests**
3. `CardAnimationStateMachine` and states - animation logic → **Write unit tests**
4. `CardController` - input handling → **Write unit tests**
5. `CardViewRenderer` - reactive observation setup → **Write unit tests**
6. `CardView2D` - UI rendering (reuse existing card_view.tscn structure) → Manual testing
7. `CardView3D` - 3D rendering → Manual testing
8. `CardFactory` - update to create new architecture
9. **Integration tests** - Data → State → View reactive chain
10. Manual visual testing and fixes

## Migration Notes

- Current `CardMovement` logic splits into: animation states + controller
- Current `CardView` becomes `CardView2D` (with shared `CardViewRenderer`)
- Current `Card` node can become a container that wires up all modules
- Gradually migrate existing usages (card viewer, hand, etc.)
