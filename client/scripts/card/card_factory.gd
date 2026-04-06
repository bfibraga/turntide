extends Node

var card_scene : PackedScene
var card_view_scene: PackedScene

func _ready() -> void:
	card_scene = preload("res://scenes/card/card_node.tscn")
	card_view_scene = preload("res://scenes/card/card_view.tscn")

func create_card(card_data: CardData = null) -> Card:
	var card : Card = card_scene.instantiate()
	card.data = card_data

	return card

func create_card_at_position(card_data: CardData, global_pos: Vector2) -> Card:
	var card : Card = create_card(card_data)
	card.global_position = global_pos
	return card

func create_cards(count: int, start_pos: Vector2, spacing: float = 50.0) -> Array[Card]:
	var cards: Array[Card] = []
	
	for i : int in range(count):
		var card : Card = create_card()
		card.global_position = start_pos + Vector2(i * spacing, 0)
		cards.append(card)
	
	return cards

func create_card_view(card_metadata: CardMetadata = null) -> CardView:
	var card_view: CardView = card_view_scene.instantiate()
	card_view.metadata = card_metadata
	
	card_view.size_flags_horizontal = Control.SIZE_FILL
	card_view.custom_minimum_size = Vector2(250, 350)
	
	return card_view
	
