class_name GameController extends Node

@export var gui_state_machine: StateMachine

func _ready() -> void:
	Global.game_controller = self

func gui_transition_to(state_name: String, data: Dictionary = {}) -> void:
	var current_state: State = gui_state_machine.current_state
	
	current_state.Transitioned.emit(
		current_state,
		state_name,
		data
	)
	
