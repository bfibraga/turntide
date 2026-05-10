class_name CommanderFormat extends BaseFormat

const _DEFAULT_DECK_SIZE: int = 100

func _init() -> void:
	self.add_validation_step(_is_deck_size_enough) \
		.add_validation_step(_is_deck_singleton)

func _is_deck_size_enough(deck: DeckData) -> bool:
	return deck.mainboard.size() == _DEFAULT_DECK_SIZE

func _is_deck_singleton(deck: DeckData) -> bool:
	var is_singleton: Callable = func(cards: Dictionary[CardData, int]) -> bool:
		var cards_set: Set = Set.new(cards.keys())
		
		return cards_set.size() == cards.size()
	
	var mainboard: Dictionary[CardData, int] = deck.mainboard
	var sideboard: Dictionary[CardData, int] = deck.sideboard
	
	return is_singleton.call(mainboard) \
			and is_singleton.call(sideboard)

func display_name() -> String:
	return "Commander"
