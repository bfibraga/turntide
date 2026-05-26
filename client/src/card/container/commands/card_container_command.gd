## Represent a abstract command to execute on [CardContainer] (i.e hand, library, another pile)
@abstract @icon("res://addons/icodot/node/coding/icon-terminal.svg")
class_name CardContainerCommand

var _card_container: CardContainer

func _init(card_container: CardContainer) -> void:
	_card_container = card_container
	
@abstract func execute() -> void
