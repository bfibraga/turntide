@abstract class_name BaseFormat
extends RefCounted

var _validation_filters: Array[Callable] = []

func _init() -> void:
	Global.deck_format_manager.added_new_deck_format.emit(self)

func validate(deck: DeckCard.Deck) -> bool:
	return _validation_filters.all(
		func(validate_step: Callable) -> bool: 
			return validate_step.call(deck)
	)

@abstract func display_name() -> String
