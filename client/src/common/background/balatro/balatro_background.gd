@tool
extends ColorRect

@export_category("Colors")
@export var background_color_1 : Color = Color("8169ea") : 
	set(value):
		_refresh_background()
		return value
@export var background_color_2 : Color = Color("955708") : 
	set(value):
		_refresh_background()
		return value
@export var background_color_3 : Color = Color("162325") : 
	set(value):
		_refresh_background()
		return value

func _ready() -> void:
	_refresh_background()

func _draw() -> void:
	_refresh_background()

func _refresh_background() -> void:
	material.set_shader_parameter("colour_1", background_color_1)
	material.set_shader_parameter("colour_2", background_color_2)
	material.set_shader_parameter("colour_3", background_color_3)
	queue_redraw()
