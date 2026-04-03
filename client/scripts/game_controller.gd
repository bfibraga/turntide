class_name GameController extends Node

@export var gui_state_machine: StateMachine

func _ready() -> void:
	Global.game_controller = self

func transition_gui(state_name: String) -> void:
	if gui_state_machine and gui_state_machine.current_state:
		gui_state_machine.current_state.Transitioned.emit(
			gui_state_machine.current_state, 
			state_name.to_lower()
		)

func get_gui_state() -> State:
	return gui_state_machine.current_state if gui_state_machine else null
