class_name CardView2D
extends Control

var renderer: CardViewRenderer
var card_data
var game_state_machine
var animation_state_machine

var base_scale: Vector2 = Vector2.ONE
var hover_scale: Vector2 = Vector2(1.1, 1.1)
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
	_update_hover_effect()
	_play_animation_effect()

func _update_hover_effect() -> void:
	if card_data and card_data.is_hovered:
		_animate_to_scale(hover_scale)
	else:
		_animate_to_scale(base_scale)

func _animate_to_scale(target_scale: Vector2) -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _play_animation_effect() -> void:
	pass