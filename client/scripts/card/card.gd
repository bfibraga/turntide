class_name Card
extends Control

@export var controller: CardController
@export var view: CardView

var data: CardData

func _init(card_data: CardData = null) -> void:
	self.data = card_data

func _ready() -> void:
	if view:
		view.setup()
	
func setup() -> void:
	view.set_printing(data.image_path)

func update_image_path(path: String) -> void:
	data.image_path = path
	view.set_printing(path)
