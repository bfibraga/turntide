class_name CardFactory extends RefCounted

## Creates a [CardUI] node from [CardData]
static func create_card(card_data: CardData) -> CardUI:
	return CardUI.new(card_data)
