extends Node
class_name Card

var data: CardData

@export var controller: CardController

func setup() -> void:
	controller.set_printing(data.image_path)
