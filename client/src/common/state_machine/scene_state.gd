class_name SceneHolderState extends State

@export_category("Scene")
@export var packed_scene: PackedScene
@export var transition_in: Animation = preload("res://assets/animations/transitions/none.res")
@export var transition_out: Animation = preload("res://assets/animations/transitions/none.res")

@export_category("Dependencies")
@export var transition_manager: TransitionManager

func enter(data: Dictionary = {}) -> void:
	super.enter()
	
	transition_manager.transition_to(packed_scene, transition_in, transition_out, data)
	
