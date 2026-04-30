class_name SceneHolderState
extends State

@export var packed_scene: PackedScene
@export var transition_config: TransitionConfig = preload("res://resources/transitions/none.tres")

func enter_scene() -> void:
	if !packed_scene:
		push_error("Packed scene not registered in state %s" % self.Name())
		return
	
	#if Global.transition_manager: 
	Global.transition_manager.transition_to(packed_scene, transition_config)
