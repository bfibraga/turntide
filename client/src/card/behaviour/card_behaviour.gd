class_name CardBehavior extends Node

var card: Card

func setup(card_node: Card) -> void:
	card = card_node
	# Override to connect signals, start logic

func teardown() -> void:
	# Override to disconnect signals, clean up
	pass

func is_active() -> bool:
	return card != null and is_inside_tree()
