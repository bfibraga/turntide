class_name StateMachine
extends Node

signal state_changed(from: State, to: State)

@export var initial_state : State

var current_state : State
var states : Dictionary[String, State] = {}

func _ready() -> void:
	for state: Node in self.get_children():
		if state is State:
			state.Transitioned.connect(on_state_transition)
			states[state.name.to_lower()] = state
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_state_transition(state: State, new_state_name: String, data: Dictionary = {}) -> void:
	if state != current_state:
		return

	if not current_state.can_transition_away:
		return

	var new_state_name_lower: String = new_state_name.to_lower()
	if current_state.name.to_lower() == new_state_name_lower:
		return

	var new_state : State = states[new_state_name_lower]
	if !new_state:
		push_error("State %s not found" % new_state_name)
		return

	if current_state:
		current_state.exit()

	new_state.enter(data)

	current_state = new_state
	state_changed.emit(state, new_state)
