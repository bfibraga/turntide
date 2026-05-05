class_name SceneHolderState extends State

@export_category("Scene")
@export var packed_scene: PackedScene
@export var transition_in: String = "none"
@export var transition_out: String = "none"

@export_category("Dependencies")
@export var transition_manager: TransitionManager

func enter() -> void:
	super.enter()
	
	transition_manager.transition_to(packed_scene, transition_in, transition_out)
	
