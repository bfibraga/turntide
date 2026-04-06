extends Node

var game_controller: GameController
var logger: Log
var card_repository: CardRepository
var printings_manager: PrintingsManager

var client_id : int = -1

func _ready() -> void:
	if not printings_manager:
		printings_manager = PrintingsManager.new()
		printings_manager.load_tracker()
