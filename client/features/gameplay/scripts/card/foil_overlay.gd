class_name FoilOverlay
extends ColorRect

@export var foil_type: int = 0:
	set(value):
		foil_type = value
		_update_foil_type()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_foil_type()

func _update_foil_type() -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("foil_type", foil_type)

func set_intensity(intensity: float) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("foil_intensity", intensity)

func set_speed(speed: float) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("shimmer_speed", speed)
