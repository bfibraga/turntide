extends Node

var card_scene: PackedScene

func _ready() -> void:
	card_scene = preload("res://scenes/card/card_node.tscn")

func create_card(card_data: CardData = null) -> Card:
	var card: Card = card_scene.instantiate()
	card.data = card_data
	card.setup()
	
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
