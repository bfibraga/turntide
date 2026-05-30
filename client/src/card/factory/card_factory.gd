class_name CardFactory extends RefCounted

const CardScene: PackedScene = preload("res://src/card/ui/card_ui.tscn")
static var void_fn: Callable = func(_card: Card) -> void: pass

## Creates a [Card] node from [CardData]
static func create_card(card_data: CardData, decorate_callable: Callable = void_fn) -> Card:
	var card_node: Card = CardScene.instantiate()
	card_node.setup(card_data)
	decorate_callable.call(card_node)

	return card_node
