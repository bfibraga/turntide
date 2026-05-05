class_name CardController
extends Node

signal pressed(card: Card)

@export_category("Card components")
@export var view: CardView
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		pressed.emit(self.get_parent())
