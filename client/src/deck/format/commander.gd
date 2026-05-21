class_name CommanderFormat extends BaseFormat

const _DEFAULT_DECK_SIZE: int = 100

func _init() -> void:
	self.add_validation_step(_is_deck_size_enough) \
		.add_validation_step(_is_deck_singleton) \
		.add_validation_step(_has_commander) \
		.add_validation_step(_all_cards_same_color_identity)

func _is_deck_size_enough(deck: DeckData) -> bool:
	return deck.mainboard.size() == _DEFAULT_DECK_SIZE

func _is_deck_singleton(deck: DeckData) -> bool:
	var is_singleton: Callable = func(cards: Dictionary[CardData, int]) -> bool:
		var cards_set: Set = Set.new(cards.keys())
		
		return cards_set.size() == cards.size()
	
	var mainboard: Dictionary[CardData, int] = deck.mainboard
	var sideboard: Dictionary[CardData, int] = deck.sideboard
	
	return is_singleton.call(mainboard) and is_singleton.call(sideboard)

func _has_commander(deck: DeckData) -> bool:
	for card: CardData in deck.mainboard:
		if card.get_meta("is_commander", false):
			var card_color_identity_string: String = card.colorIdentity
			var color_identity: PackedStringArray = card_color_identity_string.split(",", true)
			deck.color_identity = Set.new(color_identity)
			
			return true
	
	return false

func _all_cards_same_color_identity(deck: DeckData) -> bool:
	var same_color_identity: Callable = func(cards: Dictionary[CardData, int]) -> bool:
		for card: CardData in cards:
			var card_color_identity_string: String = card.colorIdentity
			var color_identity: Set = Set.new(card_color_identity_string.split(",", true))
			
			if not color_identity.contains_all(deck.color_identity):
				return false
		
		return true
	
	return same_color_identity.call(deck.mainboard) and same_color_identity.call(deck.sideboard)

static func set_commander(card: CardData) -> CardData:
	card.set_meta("is_commander", true)
	return card

static func display_name() -> String:
	return "Commander"
