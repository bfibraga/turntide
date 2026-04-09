class_name CommanderFormat
extends BaseFormat

const _DEFAULT_DECK_SIZE: int = 100

func _init() -> void:
	self._validation_filters.append_array([
		_is_deck_size_enough,
		_is_deck_singleton,
		# TODO: Commander color identity
	])

func _is_deck_size_enough(deck: DeckCard.Deck) -> bool:
	return deck.cards.size() == _DEFAULT_DECK_SIZE

func _is_deck_singleton(deck: DeckCard.Deck) -> bool:
	var cards: Array[DeckCard] = deck.cards
	var map : Dictionary[String, bool]
	for card: DeckCard in cards:
		if map.get(card.uuid, false):
			return false
		
		map[card.uuid] = true
	
	return true

func display_name() -> String:
	return "Commander"
