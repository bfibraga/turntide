class_name GameController extends Node

@export var gui_state_machine: StateMachine

func _ready() -> void:
	Global.game_controller = self

func gui_transition_to(state_name: String) -> void:
	gui_state_machine.current_state.Transitioned.emit(
		gui_state_machine.current_state,
		state_name
	)
