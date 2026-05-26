class_name CardController extends Node

signal pressed(card: Card)

const HOVER_OFFSET := -40

var card: Card
var move_tween: Tween
var hover_tween: Tween

var hovered := false
var base_position := Vector2.ZERO


func setup(owner_card: Card) -> void:
	card = owner_card

	card.mouse_entered.connect(
		_on_mouse_entered
	)

	card.mouse_exited.connect(
		_on_mouse_exited
	)

	card.pressed.connect(
		func():
			pressed.emit(card)
	)


func move_to(
	position: Vector2,
	rotation: float,
	duration := .25
) -> void:

	base_position = position

	if hovered:
		position.y += HOVER_OFFSET

	if move_tween:
		move_tween.kill()

	move_tween = card.create_tween()

	move_tween.set_parallel()

	move_tween.tween_property(
		card,
		"position",
		position,
		duration
	)

	move_tween.tween_property(
		card,
		"rotation",
		rotation,
		duration
	)


func _on_mouse_entered() -> void:
	hovered = true
	card.z_index = 100

	_apply_hover()


func _on_mouse_exited() -> void:
	hovered = false
	card.z_index = 0

	_apply_hover()


func _apply_hover():
	var pos = base_position

	if hovered:
		pos.y += HOVER_OFFSET

	if hover_tween:
		hover_tween.kill()

	hover_tween = card.create_tween()

	hover_tween.tween_property(
		card,
		"position",
		pos,
		0.15
	)
