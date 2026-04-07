extends Node

var game_controller: GameController
var logger: Log
var card_repository: CardRepository
var printings_manager: PrintingsManager

var client_id : int = -1

func _ready() -> void:
	if not card_repository:
		card_repository = RepositoryFactory.new_card_repository()
		card_repository.open()
	
	if not printings_manager:
		printings_manager = PrintingsManager.new()
		printings_manager.load_tracker()

func _exit_tree() -> void:
	if card_repository:
		card_repository.close()
	
