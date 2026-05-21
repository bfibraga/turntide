class_name State
extends Node

@warning_ignore("unused_signal")
signal Transitioned(state: State, new_state_name: String, data: Dictionary)

static func Name() -> String:
	return ""

@warning_ignore("unused_parameter")
func enter(data: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func _to_string() -> String:
	return "%s" % self.name
