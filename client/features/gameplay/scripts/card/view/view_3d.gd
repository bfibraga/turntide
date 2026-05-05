class_name CardView3D
extends Node3D

var renderer: CardViewRenderer
var card_data
var game_state_machine
var animation_state_machine

var target_position: Vector3
var tween: Tween

func _ready() -> void:
	renderer = CardViewRenderer.new()
	renderer.observe_card_data(card_data)
	renderer.observe_game_state(game_state_machine)
	renderer.observe_animation_state(animation_state_machine)
	renderer.reactive_changed.connect(_on_state_changed)

func setup(data, game_sm, anim_sm) -> void:
	card_data = data
	game_state_machine = game_sm
	animation_state_machine = anim_sm
	
	if renderer:
		renderer.observe_card_data(card_data)
		renderer.observe_game_state(game_state_machine)
		renderer.observe_animation_state(animation_state_machine)

func _on_state_changed(_reactive: Reactive) -> void:
	_play_state_animation()

func _play_state_animation() -> void:
	if not game_state_machine:
		return
	
	var current_state = game_state_machine.current_state
	if current_state and current_state.name == "playing":
		_animate_play()
	elif current_state and current_state.name == "discarding":
		_animate_discard()

func _animate_play() -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	target_position = Vector3(0, 0, 0)
	tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _animate_discard() -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	target_position = Vector3(0, -100, 0)
	tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)