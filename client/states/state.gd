class_name State
extends Node

signal Transitioned(state: State, new_state_name: String)

static func Name() -> String:
	return ""

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
