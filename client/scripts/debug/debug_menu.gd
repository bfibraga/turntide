extends Control

@export var enabled: bool = false
@export var state_machine: StateMachine

@onready var state_label: Label = $VBoxContainer/State

func _ready() -> void:
	if !enabled: 
		return
	
	if state_machine:
		state_machine.state_changed.connect(_on_state_changed)

func _on_state_changed(_from: State, to: State) -> void:
	state_label.text = "State: %s" % to.Name()
