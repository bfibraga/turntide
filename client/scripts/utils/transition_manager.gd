extends Node

## Signal emitted when transition completes
signal transition_completed
signal execute_transition(new_scene: PackedScene, config: TransitionConfig)

## Default transition config if none specified
var default_config: TransitionConfig = preload("res://resources/transitions/none.tres")

## Container node for scene content
@export var content_container: Node

var _overlay: Dictionary = {}
var _loading_screen: Dictionary = {}
var _is_transitioning: bool = false
var _current_scene: PackedScene = null

func _ready() -> void:
	# Create overlay and loading screen
	_create_overlay()
	_create_loading_screen()
	self.execute_transition.connect(transition_to)
	# Find container after scene tree is ready
	call_deferred("_find_content_container")

func _find_content_container() -> void:
	# Try to find ContentContainer in the scene tree
	var root: Node = get_tree().root
	
	for scene : Node in root.get_children():
		if scene and scene.has_node("ContentContainer"):
			content_container = scene.get_node("ContentContainer")
			print("TransitionManager: Found ContentContainer")


func _create_overlay() -> void:
	"""Create transition overlay with animation player"""
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 999
	canvas_layer.name = "TransitionOverlay"
	canvas_layer.visible = false  # Keep hidden until transition starts
	add_child(canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.anchor_left = 0.0
	color_rect.anchor_top = 0.0
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.modulate.a = 0.0
	color_rect.z_index = 999
	canvas_layer.add_child(color_rect)
	
	var anim_player = AnimationPlayer.new()
	canvas_layer.add_child(anim_player)
	
	_overlay = {
		"canvas_layer": canvas_layer,
		"color_rect": color_rect,
		"anim_player": anim_player
	}
	
	_setup_animations()

func _create_loading_screen() -> void:
	"""Create loading screen with progress bar"""
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 998
	canvas_layer.name = "LoadingScreen"
	canvas_layer.visible = false
	add_child(canvas_layer)
	
	var control = Control.new()
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.z_index = 999
	canvas_layer.add_child(control)
	
	# Semi-transparent background
	var bg_rect = ColorRect.new()
	bg_rect.anchor_left = 0.0
	bg_rect.anchor_top = 0.0
	bg_rect.anchor_right = 1.0
	bg_rect.anchor_bottom = 1.0
	bg_rect.color = Color(0, 0, 0, 0.3)
	control.add_child(bg_rect)
	
	# Center container
	var center = CenterContainer.new()
	center.anchor_left = 0.0
	center.anchor_top = 0.0
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	control.add_child(center)
	
	# VBox for loading UI
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 80)
	center.add_child(vbox)
	
	# Loading label
	var label = Label.new()
	label.text = "Loading..."
	label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(label)
	
	# Progress bar (indeterminate)
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(300, 30)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 50
	vbox.add_child(progress_bar)
	
	_loading_screen = {
		"canvas_layer": canvas_layer,
		"control": control,
		"progress_bar": progress_bar,
		"label": label
	}

func _setup_animations() -> void:
	"""Setup animation library for different transition effects"""
	var anim_player = _overlay["anim_player"]
	
	# Create animation library
	var lib = AnimationLibrary.new()
	anim_player.add_animation_library("", lib)
	
	# FADE effect animations
	var fade_out = Animation.new()
	fade_out.length = 0.5
	var fade_out_track = fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.track_set_path(fade_out_track, NodePath(".:modulate:a"))
	fade_out.track_insert_key(fade_out_track, 0.0, 0.0)
	fade_out.track_insert_key(fade_out_track, 0.5, 1.0)
	lib.add_animation("fade_out", fade_out)
	
	var fade_in = Animation.new()
	fade_in.length = 0.5
	var fade_in_track = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(fade_in_track, NodePath(".:modulate:a"))
	fade_in.track_insert_key(fade_in_track, 0.0, 1.0)
	fade_in.track_insert_key(fade_in_track, 0.5, 0.0)
	lib.add_animation("fade_in", fade_in)

func transition_to(scene: PackedScene, config: TransitionConfig = null) -> void:
	"""
	Transition to a new scene with specified config
	
	Args:
		scene: PackedScene to load
		config: TransitionConfig with animation settings (uses default if null)
	"""
	if _is_transitioning:
		push_error("Transition already in progress")
		return
	
	_is_transitioning = true
	_current_scene = scene
	
	var cfg : TransitionConfig = config if config else default_config
	
	# Handle NONE effect - instant transition
	if cfg.effect == TransitionConfig.TransitionEffect.NONE:
		_instant_transition(scene)
		_is_transitioning = false
		transition_completed.emit()
		return
	
	# Execute transition with animation and async loading
	await _execute_transition(scene, cfg)
	_is_transitioning = false
	transition_completed.emit()

func _instant_transition(scene: PackedScene) -> void:
	"""Instant scene change with no animation"""
	_swap_scene(scene)

func _swap_scene(scene: PackedScene) -> void:
	"""Swap scene in content container"""
	if not content_container:
		get_tree().change_scene_to_packed(scene)
		return
	
	var new_scene = scene.instantiate()
	content_container.add_child(new_scene)
	
	for child in content_container.get_children():
		if child != new_scene:
			child.queue_free()

func _execute_transition(scene: PackedScene, config: TransitionConfig) -> void:
	"""
	Execute full transition with animation and async loading
	
	Flow:
	1. Show overlay
	2. Play "out" animation
	3. Start async scene load
	4. Show loading screen
	5. Wait for scene load
	6. Apply scene
	7. Play "in" animation
	8. Hide overlay to allow interaction
	"""
	var color_rect = _overlay["color_rect"]
	var overlay_canvas = _overlay["canvas_layer"]
	var anim_player = _overlay["anim_player"]
	
	# Show overlay
	overlay_canvas.visible = true
	
	# Update overlay color
	var fade_color = config.fade_color
	color_rect.color = fade_color
	
	# Step 1: Play out animation
	await _play_transition_effect(config, true)
	
	# Step 2: Start async scene load
	var load_start_time = Time.get_ticks_msec()
	ResourceLoader.load_threaded_request(scene.resource_path)
	
	# Step 3: Show loading screen if configured
	if config.show_loading_screen:
		_loading_screen["canvas_layer"].visible = true
		_animate_loading_screen()
	
	# Step 4: Wait for scene load
	var scene_loaded = false
	while not scene_loaded:
		var status = ResourceLoader.load_threaded_get_status(scene.resource_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			scene_loaded = true
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + scene.resource_path)
			_loading_screen["canvas_layer"].visible = false
			overlay_canvas.visible = false
			return
		
		await get_tree().process_frame
	
	# Apply minimum loading time
	var load_elapsed = Time.get_ticks_msec() - load_start_time
	var min_time_ms = int(config.loading_min_time * 1000)
	if load_elapsed < min_time_ms:
		await get_tree().create_timer(float(min_time_ms - load_elapsed) / 1000.0).timeout
	
	# Hide loading screen
	if config.show_loading_screen:
		_loading_screen["canvas_layer"].visible = false
	
	# Step 5: Apply scene
	_swap_scene(scene)
	
	# Wait for scene to be ready before playing in animation
	await get_tree().process_frame
	
	# Step 6: Play in animation
	await _play_transition_effect(config, false)
	
	# Wait for everything to settle before allowing interaction
	await get_tree().process_frame
	
	# Step 7: Hide overlay to allow interaction with loaded scene
	overlay_canvas.visible = false

func _play_transition_effect(config: TransitionConfig, is_out: bool) -> void:
	"""Play transition effect based on config"""
	var color_rect = _overlay["color_rect"]
	var effect = config.effect
	var duration = config.duration
	
	match effect:
		TransitionConfig.TransitionEffect.FADE:
			_fade_effect(is_out, duration, config.fade_color)
		TransitionConfig.TransitionEffect.FADE_COLOR:
			_fade_effect(is_out, duration, config.fade_color)
		TransitionConfig.TransitionEffect.SLIDE_LEFT:
			_slide_effect(is_out, duration, Vector2(-1, 0))
		TransitionConfig.TransitionEffect.SLIDE_RIGHT:
			_slide_effect(is_out, duration, Vector2(1, 0))
		TransitionConfig.TransitionEffect.SLIDE_UP:
			_slide_effect(is_out, duration, Vector2(0, -1))
		TransitionConfig.TransitionEffect.SLIDE_DOWN:
			_slide_effect(is_out, duration, Vector2(0, 1))
		TransitionConfig.TransitionEffect.DISSOLVE:
			_dissolve_effect(is_out, duration)
		TransitionConfig.TransitionEffect.CROSSFADE:
			_crossfade_effect(is_out, duration, config.fade_color)
		_:
			push_error("Unknown transition effect: " + str(effect))

func _fade_effect(is_out: bool, duration: float, fade_color: Color) -> void:
	"""Simple fade to/from color"""
	var color_rect = _overlay["color_rect"]
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	if is_out:
		color_rect.color = fade_color
		color_rect.modulate.a = 0.0
		tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	else:
		color_rect.color = fade_color
		color_rect.modulate.a = 1.0
		tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	
	await tween.finished

func _slide_effect(is_out: bool, duration: float, direction: Vector2) -> void:
	"""Slide transition effect"""
	var overlay = _overlay["canvas_layer"]
	var start_pos = overlay.position
	var viewport_size = get_viewport().get_visible_rect().size
	var end_pos = start_pos + (direction * viewport_size)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	if is_out:
		overlay.position = start_pos
		tween.tween_property(overlay, "position", end_pos, duration)
	else:
		overlay.position = end_pos
		tween.tween_property(overlay, "position", start_pos, duration)
	
	await tween.finished

func _dissolve_effect(is_out: bool, duration: float) -> void:
	"""Dissolve effect (simplified as fade for now)"""
	await _fade_effect(is_out, duration, Color.BLACK)

func _crossfade_effect(is_out: bool, duration: float, fade_color: Color) -> void:
	"""Crossfade effect"""
	await _fade_effect(is_out, duration, fade_color)

func _animate_loading_screen() -> void:
	"""Animate progress bar indeterminately during loading"""
	var progress_bar = _loading_screen["progress_bar"]
	
	while _loading_screen["canvas_layer"].visible:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(progress_bar, "value", 100, 0.8)
		
		tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(progress_bar, "value", 0, 0.8)
		
		await tween.finished
