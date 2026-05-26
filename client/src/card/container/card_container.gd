@tool @icon("res://addons/icodot/ui/fantasy/icon-book-ui.svg")
class_name CardContainer extends Control

class Data extends Reactive:
	var cards: ReactiveArray = ReactiveArray.new([], self)

#region Signals

signal card_added(card: Card, index: int)
signal card_removed(card: Card, index: int)

signal container_full()
signal container_empty()

#endregion

#region Export

@export var max_cards: int = -1 :
	set(value):
		max_cards = value

@export var cards: Array[Card] = []

#endregion

var data: Data = Data.new()

func organize_cards() -> void:
	pass

func can_accept_card(card: Card) -> bool:
	return true

func shuffle() -> void:
	cards.shuffle()

func peek_top_card() -> Card:
	return cards.get(cards.size() - 1)

func pop_top_card() -> Card:
	var card: Card = cards.pop_back()
	if not card:
		return null
		
	card_removed.emit(card, cards.size() + 1)
	
	if cards.size() == 0:
		container_empty.emit()
		
	return card
