extends ColorRect

@export_category("Colors")
@export var background_color_1 : Color = Color("8169ea")
@export var background_color_2 : Color = Color("955708")
@export var background_color_3 : Color = Color("162325")

func _ready() -> void:
	material.set_shader_parameter("colour_1", background_color_1)
	material.set_shader_parameter("colour_2", background_color_2)
	material.set_shader_parameter("colour_3", background_color_3)
