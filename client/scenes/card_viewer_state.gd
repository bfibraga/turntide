class_name CardViewerState
extends SceneHolderState

static func Name() -> String:
	return "CardViewer"

func _init() -> void:
	packed_scene = preload("res://states/ingame/ingame.tscn")
