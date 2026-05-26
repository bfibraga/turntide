## Represent a abstract command to execute on [CardContainer] (i.e hand, library, another pile)
@abstract @icon("res://addons/icodot/node/coding/icon-terminal.svg")
class_name CardContainerCommand extends Node
	
@abstract func execute() -> void
