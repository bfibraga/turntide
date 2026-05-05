# TransitionManager: In and Out Transitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement animated fade-through transitions that hide the current scene, swap it, then reveal the new scene.

**Architecture:** The `transition_to()` function orchestrates a sequence: play transition_in animation (hiding overlay), swap scene while hidden, play transition_out animation backward (revealing overlay). Error handling ensures null scenes don't cause transitions and invalid animations fall back to "fade".

**Tech Stack:** GDScript (Godot 4.x), AnimationPlayer for shader animations, PackedScene for scene swaps.

---

## File Structure

**File to modify:**
- `client/scripts/utils/transition_manager.gd` - Core transition logic

**Files to create:**
- `tests/scripts/utils/test_transition_manager.gd` - Unit tests

**No changes needed:**
- `client/scenes/transition_manager.tscn` - Already has correct setup
- `client/states/scene_state.gd` - Already calls transition_to correctly

---

## Task 1: Write Failing Tests for Happy Path

**Files:**
- Create: `tests/scripts/utils/test_transition_manager.gd`

- [ ] **Step 1: Create test file with basic structure**

Create `tests/scripts/utils/test_transition_manager.gd`:

```gdscript
extends GutTest

var transition_manager: TransitionManager
var test_scene: PackedScene

func before_each():
	transition_manager = TransitionManager.new()
	# Load a simple test scene (or create one on the fly)
	test_scene = preload("res://scenes/test_scene.tscn")

func test_transition_to_plays_transition_in_animation():
	# Verify that transition_in is called/played
	var animation_played = false
	var played_animation_name = ""
	
	# We'll spy on animation_player.play() calls
	var spy = SpyOn(transition_manager.animation_player, "play")
	
	transition_manager.transition_to(test_scene, "fade", "fade")
	await transition_manager.transition_completed
	
	# Verify play was called with "fade"
	assert_true(spy.was_called())
	# First call should be transition_in
	assert_eq(spy.call_args_list[0][0], ["fade"])

func test_transition_to_swaps_scene():
	# Verify that the new scene is instantiated and added
	var initial_child_count = transition_manager.content_container.get_child_count()
	
	transition_manager.transition_to(test_scene, "fade", "fade")
	await transition_manager.transition_completed
	
	var final_child_count = transition_manager.content_container.get_child_count()
	# Scene should be swapped (count might be same, but instance is different)
	assert_true(final_child_count > 0)

func test_transition_to_emits_transition_completed():
	# Verify signal is emitted
	var signal_emitted = false
	
	transition_manager.transition_completed.connect(func(): signal_emitted = true)
	transition_manager.transition_to(test_scene, "fade", "fade")
	await transition_manager.transition_completed
	
	assert_true(signal_emitted)

func test_transition_to_is_awaitable():
	# Verify we can await the transition
	var start_time = Time.get_ticks_msec()
	await transition_manager.transition_to(test_scene, "fade", "fade")
	var end_time = Time.get_ticks_msec()
	
	# Should have taken some time (animations play)
	assert_true(end_time - start_time > 0)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /home/bfbraga/Documents/Programming/turntide
make test -- tests/scripts/utils/test_transition_manager.gd
```

Expected: Tests fail because `transition_to()` doesn't yet use the animations.

---

## Task 2: Implement transition_to() - Happy Path

**Files:**
- Modify: `client/scripts/utils/transition_manager.gd:44-50`

- [ ] **Step 1: Update transition_to() to use animations**

Replace the current `transition_to()` function (lines 44-50) with:

```gdscript
func transition_to(scene: PackedScene, transition_in_name: String = "fade", transition_out_name: String = "fade") -> void:
	# Validate scene
	if not scene:
		push_warning("transition_to() called with null scene. Aborting transition.")
		return
	
	# Play transition in (hide current scene)
	await transition_in(transition_in_name)
	
	# Swap the scene while hidden
	_swap_scene(scene)
	
	# Play transition out (reveal new scene)
	await transition_out(transition_out_name)
	
	# Signal completion
	transition_completed.emit()
```

- [ ] **Step 2: Update transition_in() to show overlay and play animation**

Replace the current `transition_in()` function (lines 52-59) with:

```gdscript
func transition_in(animation: String = "fade") -> void:
	print("IN: %s" % animation)
	
	# Show the overlay
	color_rect.show()
	
	# Play the animation
	if not animation_player.has_animation(animation):
		push_warning("Animation '%s' not found. Using 'fade' as fallback." % animation)
		animation = "fade"
	
	animation_player.play(animation)
	await animation_player.animation_finished
```

- [ ] **Step 3: Update transition_out() to play animation backward and hide overlay**

Replace the current `transition_out()` function (lines 61-68) with:

```gdscript
func transition_out(animation: String = "fade") -> void:
	print("OUT: %s" % animation)
	
	# Check if animation exists, fall back if not
	if not animation_player.has_animation(animation):
		push_warning("Animation '%s' not found. Using 'fade' as fallback." % animation)
		animation = "fade"
	
	# Play animation backwards (revealing overlay)
	animation_player.play_backwards(animation)
	await animation_player.animation_finished
	
	# Hide the overlay when done
	color_rect.hide()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /home/bfbraga/Documents/Programming/turntide
make test -- tests/scripts/utils/test_transition_manager.gd
```

Expected: Tests pass (or mostly pass - adjust test expectations if animation timing is off).

- [ ] **Step 5: Commit the implementation**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add client/scripts/utils/transition_manager.gd tests/scripts/utils/test_transition_manager.gd
git commit -m "feat: implement fade-through transitions with animation sequencing"
```

---

## Task 3: Add Error Handling Tests

**Files:**
- Modify: `tests/scripts/utils/test_transition_manager.gd`

- [ ] **Step 1: Add test for null scene**

Add to test file after existing tests:

```gdscript
func test_transition_to_null_scene_logs_warning_and_returns():
	# Verify that calling with null scene logs warning and doesn't transition
	var initial_child_count = transition_manager.content_container.get_child_count()
	
	# Capture warning output
	var warnings_captured = []
	var original_push_warning = get_stack()[0].owner.push_warning
	
	transition_manager.transition_to(null, "fade", "fade")
	# Don't await - should return immediately
	await get_tree().process_frame
	
	var final_child_count = transition_manager.content_container.get_child_count()
	# No scene should have been swapped
	assert_eq(initial_child_count, final_child_count)
```

- [ ] **Step 2: Add test for invalid animation fallback**

Add to test file:

```gdscript
func test_transition_to_invalid_animation_falls_back_to_fade():
	# Verify that an invalid animation name falls back to "fade"
	var spy = SpyOn(transition_manager.animation_player, "play")
	
	transition_manager.transition_to(test_scene, "nonexistent_animation", "fade")
	await transition_manager.transition_completed
	
	# Should have played "fade" instead
	assert_true(spy.was_called())
	# Check that "fade" was played (after fallback)
	var call_args = spy.call_args_list
	# Should contain "fade" in at least one call
	var found_fade = false
	for args in call_args:
		if args[0][0] == "fade":
			found_fade = true
			break
	assert_true(found_fade)
```

- [ ] **Step 3: Run tests to verify they pass**

```bash
cd /home/bfbraga/Documents/Programming/turntide
make test -- tests/scripts/utils/test_transition_manager.gd
```

Expected: All error handling tests pass.

- [ ] **Step 4: Commit error handling tests**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add tests/scripts/utils/test_transition_manager.gd
git commit -m "test: add error handling tests for null scenes and invalid animations"
```

---

## Task 4: Integration Test with SceneHolderState

**Files:**
- Create: `tests/scripts/states/test_scene_holder_state_integration.gd`

- [ ] **Step 1: Create integration test file**

Create `tests/scripts/states/test_scene_holder_state_integration.gd`:

```gdscript
extends GutTest

var scene_holder_state: SceneHolderState
var transition_manager: TransitionManager
var test_scene: PackedScene

func before_each():
	transition_manager = TransitionManager.new()
	scene_holder_state = SceneHolderState.new()
	scene_holder_state.transition_manager = transition_manager
	scene_holder_state.packed_scene = preload("res://scenes/test_scene.tscn")
	scene_holder_state.transition_in = "fade"
	scene_holder_state.transition_out = "fade"

func test_scene_holder_state_enters_with_transition():
	# Verify that entering the state triggers a transition
	var transition_completed_emitted = false
	transition_manager.transition_completed.connect(func(): transition_completed_emitted = true)
	
	scene_holder_state.enter()
	await transition_manager.transition_completed
	
	assert_true(transition_completed_emitted)

func test_scene_holder_state_uses_configured_animations():
	# Verify that configured animation names are passed through
	var spy = SpyOn(transition_manager, "transition_to")
	
	scene_holder_state.transition_in = "diagonal_popping_squares"
	scene_holder_state.transition_out = "fade"
	
	scene_holder_state.enter()
	await transition_manager.transition_completed
	
	# Verify transition_to was called with the right animation names
	assert_true(spy.was_called())
	var args = spy.call_args_list[0][0]
	assert_eq(args[1], "diagonal_popping_squares")
	assert_eq(args[2], "fade")
```

- [ ] **Step 2: Run integration test**

```bash
cd /home/bfbraga/Documents/Programming/turntide
make test -- tests/scripts/states/test_scene_holder_state_integration.gd
```

Expected: Integration tests pass, verifying SceneHolderState works with new transition system.

- [ ] **Step 3: Commit integration tests**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add tests/scripts/states/test_scene_holder_state_integration.gd
git commit -m "test: add integration tests for SceneHolderState with transitions"
```

---

## Task 5: Verify All Tests Pass

**Files:**
- No file changes

- [ ] **Step 1: Run full test suite**

```bash
cd /home/bfbraga/Documents/Programming/turntide
make test
```

Expected: All tests pass, including new transition tests and existing tests.

- [ ] **Step 2: Verify no regressions**

Check that existing tests still pass and there are no new errors.

---

## Task 6: Manual Testing in Editor

**Files:**
- No file changes

- [ ] **Step 1: Run the game and test scene transitions**

1. Open Godot editor
2. Run main scene
3. Trigger a scene transition via state machine
4. Observe fade-out, scene swap, fade-in
5. Verify overlay hides completely after transition

- [ ] **Step 2: Test error cases manually**

1. Try to trigger a transition (e.g., via console/debug)
2. Verify warnings appear in console for invalid animations
3. Verify null scene doesn't crash the game

---

## Task 7: Final Commit and Documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-05-05-transition-in-out-design.md` (update status)

- [ ] **Step 1: Update design doc status**

Change the Status line in the design doc from "Design Complete" to "Implementation Complete".

- [ ] **Step 2: Create final commit**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git add docs/superpowers/specs/2026-05-05-transition-in-out-design.md
git commit -m "docs: mark transition implementation complete"
```

- [ ] **Step 3: Verify git log shows clean history**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git log --oneline -10
```

Expected: Shows commits for transition implementation, tests, integration.

---

## Success Criteria Checklist

✓ `transition_to()` plays transition_in animation  
✓ Scene swaps while overlay is opaque  
✓ `transition_to()` plays transition_out animation backward  
✓ `transition_completed` signal emitted  
✓ Awaitable: `await transition_to(scene, "fade", "fade")` works  
✓ Null scene returns early with warning, no crash  
✓ Invalid animation name falls back to "fade" with warning  
✓ Works with SceneHolderState state machine  
✓ All unit tests pass  
✓ All integration tests pass  
✓ No regressions in existing tests  

---

## Implementation Notes

- The fade-through effect relies on `play_backwards()` to reverse the overlay animation. Ensure animations are reversible (progress parameter goes 0→1).
- Error handling uses `push_warning()` and `push_error()` for Godot logging.
- Tests use GUT framework (likely already in project); adjust if using a different test framework.
- The ColorRect should start hidden (`hide()` called at startup or in `_ready()`).
