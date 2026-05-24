@tool @icon("res://addons/icodot/ui/fantasy/icon-book-ui.svg")
class_name CardContainer extends Panel

#region Signals

signal card_added(card: CardData, index: int)
signal card_removed(card: CardData, index: int)

signal container_full()
signal container_empty()

#endregion

#region Export

@export var max_cards: int = -1 :
	set(value):
		max_cards = value

#endregion
