class_name EnteredState
extends SceneHolderState

static func Name() -> String:
	return "Entered"

func _init() -> void:
	packed_scene = preload("res://core/state_machine/ingame/ingame.tscn")
