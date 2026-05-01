class_name RegisterState
extends SceneHolderState

static func Name() -> String:
	return "Register"

func _init() -> void:
	packed_scene = preload("res://states/connected/register.tscn")
