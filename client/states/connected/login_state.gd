class_name LoginState
extends SceneHolderState

static func Name() -> String:
	return "Login"

func _init() -> void:
	transition_config = preload("res://resources/transitions/slide_left.tres")
	packed_scene = preload("res://states/connected/login.tscn")

func enter() -> void:
	self.enter_scene()
