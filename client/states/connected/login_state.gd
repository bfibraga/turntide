class_name LoginState
extends SceneHolderState

static func Name() -> String:
	return "Login"

func _init() -> void:
	packed_scene = preload("res://states/connected/login.tscn")
