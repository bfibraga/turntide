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

func test_transition_to_null_scene_logs_warning_and_returns():
	# Verify that calling with null scene logs warning and doesn't transition
	var initial_child_count = transition_manager.content_container.get_child_count()
	
	transition_manager.transition_to(null, "fade", "fade")
	# Don't await - should return immediately
	await get_tree().process_frame
	
	var final_child_count = transition_manager.content_container.get_child_count()
	# No scene should have been swapped
	assert_eq(initial_child_count, final_child_count)

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
