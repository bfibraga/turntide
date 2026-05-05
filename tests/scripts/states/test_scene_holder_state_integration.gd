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
