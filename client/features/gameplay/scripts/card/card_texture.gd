class_name CardTexture extends TextureRect

signal mouse_entered_view
signal mouse_exited_view

@export_category("Card Settings")
@export var card_size: Vector2 = Vector2(250, 350)
@export var hover_offset: Vector2 = Vector2(0, -20)

@export_category("Animation Parameters")
@export var hover_scale: float = 1.05
@export var selected_scale: float = 1.1
@export var hover_z_index: int = 10
@export var default_z_index: int = 0

var base_scale: Vector2 = Vector2.ONE
var is_hovered: bool = false
var is_selected: bool = false
var _target_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	#stretch_mode = STRETCH_KEEP_ASPECT_COVERED
	#pivot_offset = Vector2(125, 175)
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_clicked()
			else:
				_on_released()

func _mouse_enter() -> void:
	is_hovered = true
	z_index = hover_z_index
	_animate_to_scale(Vector2.ONE * hover_scale)
	mouse_entered_view.emit()

func _mouse_exit() -> void:
	is_hovered = false
	if not is_selected:
		z_index = default_z_index
		_animate_to_scale(base_scale)
	mouse_exited_view.emit()

func _process(delta: float) -> void:
	scale = scale.lerp(_target_scale, delta * 10.0)

func _animate_to_scale(target: Vector2) -> void:
	_target_scale = target

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		_animate_to_scale(Vector2.ONE * selected_scale)
		z_index = hover_z_index
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
		if is_hovered:
			_animate_to_scale(Vector2.ONE * hover_scale)
			z_index = hover_z_index
		else:
			_animate_to_scale(base_scale)
			z_index = default_z_index

func _on_clicked() -> void:
	pass

func _on_released() -> void:
	pass
