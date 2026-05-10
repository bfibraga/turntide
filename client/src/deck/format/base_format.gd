@abstract class_name BaseFormat
extends Resource

var _validation_filters: Array[Callable] = []

func announce_format() -> void:
	Global.deck_format_manager.added_new_deck_format.emit(self)

func add_validation_step(callable: Callable) -> BaseFormat:
	self._validation_filters.append(callable)
	return self

func validate(deck: DeckData) -> bool:
	return _validation_filters.all(
		func(validate_step: Callable) -> bool: 
			return validate_step.call(deck)
	)

@abstract func display_name() -> String

func _to_string() -> String:
	return self.display_name()
