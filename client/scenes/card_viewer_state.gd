class_name CardViewerState
extends SceneHolderState

static func Name() -> String:
	return "CardViewer"

func _init() -> void:
	transition_config = preload("res://resources/transitions/fade_color.tres")
	packed_scene = preload("res://states/ingame/ingame.tscn")

func enter() -> void:
	self.enter_scene()
