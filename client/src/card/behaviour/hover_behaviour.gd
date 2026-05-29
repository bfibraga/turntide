class_name HoverBehavior extends CardBehavior

@export_category("Hover")
@export var hover_y_offset: float = -Card.DEFAULT_SIZE.y + 75
@export var hover_duration: float = 0.15
@export var hover_z_index: int = 10
@export var hover_rotation: float = 0.0
@export var default_rotation: float = 0.0
@export var default_z_index: int = 0

var hovered: bool = false
var _hover_tween: Tween

func setup(card_node: Card) -> void:
	super(card_node)
	card.view.on_mouse_enter.connect(_on_mouse_enter)
	card.view.on_mouse_exit.connect(_on_mouse_exit)
	card.view.gui_input.connect(_on_gui_input)

func teardown() -> void:
	card.view.on_mouse_enter.disconnect(_on_mouse_enter)
	card.view.on_mouse_exit.disconnect(_on_mouse_exit)
	card.view.gui_input.disconnect(_on_gui_input)

func _on_mouse_enter() -> void:
	hovered = true
	card.z_index = hover_z_index
	_update_hover()

func _on_mouse_exit() -> void:
	hovered = false
	card.z_index = default_z_index  # from Card.default_z_index concept
	_update_hover()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card.view.follow()

func _update_hover() -> void:
	if _hover_tween: _hover_tween.kill()
	var target: Vector2 = card.base_position
	if hovered:
		target.y += hover_y_offset
	_hover_tween = create_tween().set_parallel() \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(card, "position", target, hover_duration)
	_hover_tween.tween_property(card, "rotation", hover_rotation if hovered else default_rotation, hover_duration)

# Called by DragBehavior during drag
func suppress() -> void:
	if _hover_tween: _hover_tween.kill()
