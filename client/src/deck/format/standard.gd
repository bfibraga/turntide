class_name StandardFormat extends BaseFormat

const _DEFAULT_DECK_SIZE: int = 40

func _init() -> void:
	self.add_validation_step(_is_deck_size_enough)

func _is_deck_size_enough(deck: DeckData) -> bool:
	return deck.cards.size() >= _DEFAULT_DECK_SIZE

static func display_name() -> String:
	return "Standard"
