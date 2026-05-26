class_name CardFactory extends RefCounted

const CardScene: PackedScene = preload("res://src/card/ui/card_ui.tscn")

## Creates a [Card] node from [CardData]
static func create_card(card_data: CardData) -> Card:
	var card_node: Card = CardScene.instantiate()
	card_node.setup(card_data)

	return card_node
