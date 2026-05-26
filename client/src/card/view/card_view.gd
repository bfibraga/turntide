# An example of a simulating a 3D card with a 2D TextureRect
# using the Faux 3D Perspective shader by CodeVogel (https://github.com/codevogel/faux-3d-perspective-shader-godot)
@tool @icon("res://addons/icodot/ui/games/icon-card-back-light-ui.svg")
class_name CardView
extends SubViewportContainer

signal on_mouse_enter
signal on_mouse_exit
signal tap_card
signal flip_card

@export var front_art: Texture2D = preload("res://assets/card/back/back_card.png"):
	set(value):
		front_art = value
		_refresh()
@export var back_art: Texture2D = preload("res://assets/card/back/back_card.png"):
	set(value):
		back_art = value
		_refresh()
@export var cull_backface: bool = false

@onready var art_texture_rect: TextureRect = $%Art

@export_range(1, 120, 1) var simulated_camera_fov: float = 60:
	set(value):
		simulated_camera_fov = value
		_refresh()
@export_range(-360, 360, 1) var rotation_y: float = 0.0:
	set(value):
		rotation_y = value
		_refresh()
@export_range(-360, 360, 1) var rotation_x: float = 0.0:
	set(value):
		rotation_x = value
		_refresh()

@export var tilt_scale: float = 0.045
@export var tilt_weight: float = 0.25

var is_mouse_entered: bool = false
var is_tapped: bool = false
var is_flipped: bool = false
var _flip_offset: float = 0.0

var exit_tween: Tween
var _tap_tween: Tween
var _flip_tween: Tween

@export var exit_tween_duration: float = 0.3
@export var tap_tween_duration: float = 0.2
@export var flip_tween_duration: float = 0.3

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not front_art:
		warnings.append("Front art texture is not assigned.")
	if cull_backface:
		if back_art:
			warnings.append(
				"Back art texture will not be visible because backface culling is enabled."
			)
	elif not back_art:
		warnings.append("Back art texture is not assigned.")
	if not (material is ShaderMaterial):
		warnings.append("CardArt requires a ShaderMaterial to function properly.")
	return warnings


func _ready() -> void:
	if not Engine.is_editor_hint():
		_refresh()
	
	set_process(true)
	
	mouse_entered.connect(func() -> void: 
		is_mouse_entered = true
		on_mouse_enter.emit()
	)
	mouse_exited.connect(func() -> void: 
		is_mouse_entered = false
		_set_normal_state()
		on_mouse_exit.emit()
	)
	tap_card.connect(func() -> void: toggle_tap())
	flip_card.connect(func() -> void: toggle_flip())

func follow() -> void:
	var centred_mouse_postion: Vector2 = get_local_mouse_position() - size / 2.0

	rotation_x = lerp(rotation_x, -centred_mouse_postion.y * tilt_scale, tilt_weight)
	rotation_y = lerp(rotation_y, centred_mouse_postion.x * tilt_scale, tilt_weight)
			
	_refresh()

func toggle_tap() -> void:
	is_tapped = not is_tapped
	var target: float = 90.0 if is_tapped else 0.0

	if _tap_tween and _tap_tween.is_valid():
		_tap_tween.kill()
	
	_tap_tween = get_tree().create_tween()
	_tap_tween.tween_property(self, "rotation_degrees", target, tap_tween_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	
	_refresh()


func toggle_flip() -> void:
	is_flipped = not is_flipped
	var target: float = 180.0 if is_flipped else 0.0

	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()
		
	_flip_tween = get_tree().create_tween()
	_flip_tween.tween_method(
		func(value: float) -> void:
			_flip_offset = value
			_refresh(),
		_flip_offset,
		target,
		flip_tween_duration
	).set_trans(Tween.TRANS_CUBIC) \
	 .set_ease(Tween.EASE_IN_OUT)

	_refresh()

#go back to original state with ease out
func _set_normal_state() -> void:
	if exit_tween and exit_tween.is_valid():
		exit_tween.kill()
	exit_tween = get_tree().create_tween().set_parallel()
	
	exit_tween.tween_property(self, "rotation_x", 0.0, exit_tween_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	
	exit_tween.tween_property(self, "rotation_y", 0.0, exit_tween_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	

func _refresh() -> void:
	if not (material is ShaderMaterial):
		return

	var shader_material: ShaderMaterial = material as ShaderMaterial
	shader_material.set_shader_parameter("rot_y_deg", rotation_y + _flip_offset)
	shader_material.set_shader_parameter("rot_x_deg", rotation_x)
	shader_material.set_shader_parameter("cull_backface", cull_backface)
	shader_material.set_shader_parameter("fov", simulated_camera_fov)
	_refresh_texture()


func _refresh_texture() -> void:
	if not front_art or not back_art or not art_texture_rect:
		return

	var rot_x_deg: float = wrapf(rotation_x, 0, 360)
	var rot_y_deg: float = wrapf(rotation_y + _flip_offset, 0, 360)
	var front_facing_over_x: bool = rot_x_deg < 90 or rot_x_deg > 270
	var front_facing_over_y: bool = rot_y_deg < 90 or rot_y_deg > 270
	var use_front: bool = front_facing_over_y == front_facing_over_x
	
	#card_contents.visible = use_front
	art_texture_rect.texture = front_art if use_front else back_art
	material.set_shader_parameter("use_front", use_front)
