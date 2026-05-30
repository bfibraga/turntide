class_name GameController extends Node

var _previous_state_machine: StateMachine

@export var gui_state_machine: StateMachine:
	set(value):
		_previous_state_machine = gui_state_machine
		
		gui_state_machine = value
		return value

func _ready() -> void:
	Global.game_controller = self

func gui_transition_to(state_name: String, data: Dictionary = {}) -> void:
	var current_state: State = gui_state_machine.current_state
	
	current_state.Transitioned.emit(
		current_state,
		state_name,
		data
	)

func rollback_state_machine() -> void:
	gui_state_machine = _previous_state_machine
