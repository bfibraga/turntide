class_name SceneStateMachine extends StateMachine

@export var transition_manager: TransitionManager

func _ready() -> void:
	Global.transition_manager = transition_manager
	super._ready()
