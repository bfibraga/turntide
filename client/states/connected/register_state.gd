class_name RegisterState
extends SceneHolderState

static func Name() -> String:
	return "Register"

func _init() -> void:
	transition_config = preload("res://resources/transitions/slide_left.tres")
	packed_scene = preload("res://states/connected/register.tscn")

func enter() -> void:
	self.enter_scene()
