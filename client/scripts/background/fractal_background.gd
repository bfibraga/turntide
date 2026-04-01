# Credits to https://godotshaders.com/shader/warped-fractal-noise/
@tool
extends ColorRect

@export_category("Misc")
@export var speed : float = 0.10

@export_category("Colors")
@export var low : Color = Color(0.01, 0.41, 0.51, 1.0)
@export var mid_red : Color = Color(.50, 0.10, 0.30, 1.0)
@export var high : Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("u_speed", speed)
	
		material.set_shader_parameter("u_color_low", low)
		material.set_shader_parameter("u_color_mid_red", mid_red)
		material.set_shader_parameter("u_color_high", high)
