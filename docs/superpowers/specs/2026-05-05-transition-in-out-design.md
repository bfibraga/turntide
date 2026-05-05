# TransitionManager: In and Out Transitions Design

**Date:** May 5, 2026  
**Author:** Design Brainstorming Session  
**Status:** Design Complete  

## Overview

Implement animated fade-through transitions for scene changes in the TransitionManager. The system will hide the current scene with an overlay animation, swap scenes instantly while hidden, then reveal the new scene by reversing the animation.

## Goals

1. Provide smooth, visually polished scene transitions
2. Support multiple transition animation types (fade, diagonal_popping_squares, etc.)
3. Make `transition_to()` awaitable for async scene state flow
4. Maintain signal-based API for backward compatibility
5. Handle errors gracefully without breaking game flow

## Current State

**File:** `client/scripts/utils/transition_manager.gd`

Current issues:
- `transition_to()` swaps scenes instantly with no animations
- `transition_in()` and `transition_out()` methods defined but unused
- Commented code suggests previous attempt at implementation

**Existing Assets:**
- `transition_manager.tscn` has AnimationPlayer with animations: "fade", "diagonal_popping_squares"
- ColorRect with shader material for transition effects
- Scene unique nodes: `%AnimationPlayer`, `%ColorRect`

## Architecture

### Components

1. **TransitionManager (main class)**
   - Owns the AnimationPlayer and ColorRect overlay
   - Orchestrates the fade-through sequence
   - Manages content_container for scene swaps

2. **AnimationPlayer**
   - Drives overlay shader animations
   - Supports any animation name (animations defined in scene)
   - Reversible animations: can play forward and backward

3. **ColorRect with Shader Material**
   - Overlay that hides/reveals scenes
   - Uses shader parameters (progress, grid_size, etc.) for visual effects
   - Layer 20 to appear above all game content

### Data Flow

```
transition_to(scene, transition_in_name, transition_out_name)
  ├─ [Validate] Check if scene != null
  │  └─ If null: log warning, return early (don't transition)
  │
  ├─ [Play fade in] animation_player.play(transition_in_name)
  │  ├─ Overlay becomes opaque (progress: 0 → 1)
  │  ├─ Hides current scene behind colored overlay
  │  └─ await animation_player.animation_finished
  │
  ├─ [Swap scene] _swap_scene(scene)
  │  ├─ Free old scene with queue_free()
  │  ├─ Instantiate new scene
  │  ├─ Add to content_container
  │  └─ Emit scene_instantiated signal
  │
  ├─ [Play fade out] animation_player.play_backwards(transition_out_name)
  │  ├─ Overlay becomes transparent (progress: 1 → 0)
  │  ├─ Reveals new scene
  │  └─ await animation_player.animation_finished
  │
  ├─ [Signal completion] transition_completed.emit()
  └─ [Return awaitable] function completes (can be awaited)
```

## Implementation Details

### Function Signature

```gdscript
func transition_to(
    scene: PackedScene,
    transition_in_name: String = "fade",
    transition_out_name: String = "fade"
) -> void:
```

Returns `void` but the function is async/awaitable (uses await internally).

### Error Handling

| Scenario | Action |
|----------|--------|
| `scene is null` | Log warning, return without transitioning |
| Animation doesn't exist | Log warning, use "fade" as fallback |
| Animation fails mid-play | Log error, continue to next transition step |
| content_container is null | Fallback to `get_tree().change_scene_to_packed()` |

### Animation Requirements

Animations must be **reversible** for the fade-out backward play:
- `play(animation)` goes 0 → 1 (hides scene)
- `play_backwards(animation)` goes 1 → 0 (reveals scene)

Current animations meet this requirement:
- **fade:** progress parameter 0 → 1 over 2 seconds (reversible ✓)
- **diagonal_popping_squares:** grid-based animation (reversible ✓)

### Signal Behavior

**Signals remain the same:**
- `transition_completed` - emitted when entire sequence finishes
- `scene_instantiated(scene_instance: Node)` - emitted after new scene added

**Both patterns supported:**
```gdscript
# Pattern 1: Awaitable
await transition_manager.transition_to(scene, "fade", "fade")
# Code here runs after transition completes

# Pattern 2: Signal-based
transition_manager.transition_to(scene, "fade", "fade")
transition_manager.transition_completed.connect(func(): print("done"))
```

## Edge Cases & Constraints

1. **No overlapping transitions** - Game design prevents calling `transition_to()` while one is in progress
2. **Overlay state** - ColorRect visibility controlled by transition_in/transition_out; starts hidden
3. **Animation duration** - Determined by animation definition in AnimationPlayer; typically 2 seconds for fade
4. **Scene instantiation** - Happens while overlay is opaque, so no visual pop

## Testing Strategy

### Unit Tests

1. **Happy path:** Transition with valid scene and animation
2. **Null scene:** Ensure no transition occurs, warning logged
3. **Invalid animation:** Fallback to "fade" animation
4. **Signal emission:** `transition_completed` emitted after sequence
5. **Awaitable:** Can `await transition_to()` and code runs after

### Integration Tests

1. **State machine integration:** SceneHolderState calls transition_to correctly
2. **Scene visibility:** New scene visible after transition completes
3. **Overlay cleanup:** ColorRect hidden after transition_out finishes
4. **Multiple transitions:** Sequential transitions work correctly (game design prevents overlap)

## Files to Modify

- `client/scripts/utils/transition_manager.gd` - Update `transition_to()`, `transition_in()`, `transition_out()` functions

## Files NOT to Modify

- `client/scenes/transition_manager.tscn` - Already has correct AnimationPlayer setup
- `client/states/scene_state.gd` - Already calls transition_to correctly
- `client/shaders/transition.gdshader` - Shader works as-is

## Success Criteria

✓ `transition_to()` plays transition_in animation  
✓ Scene swaps while overlay is opaque  
✓ `transition_to()` plays transition_out animation backward  
✓ `transition_completed` signal emitted  
✓ Awaitable: `await transition_to(scene, "fade", "fade")` works  
✓ Null scene returns early with warning, no crash  
✓ Invalid animation name falls back to "fade" with warning  
✓ Works with SceneHolderState state machine  

## Implementation Order

1. Implement `transition_to()` main function with error handling
2. Update `transition_in()` and `transition_out()` if needed (likely just uncomment/refactor)
3. Test happy path
4. Test error cases
5. Verify integration with SceneHolderState
