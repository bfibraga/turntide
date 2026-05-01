class_name SceneStateMachine extends StateMachine

@export var transition_manager: TransitionManager

func _ready() -> void:
	if transition_manager:
		for child in get_children():
			if child is SceneHolderState and not child.transition_manager:
				child.transition_manager = transition_manager

	super._ready()
