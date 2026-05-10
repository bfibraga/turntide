extends Node

var game_controller: GameController
var debug: Debug
var transition_manager: TransitionManager
var logger: Log
var card_repository: CardRepository
var deck_repository: DeckRepository
var deck_format_manager: FormatManager
var printings_manager: PrintingsManager

var client_id : int = -1

func _init() -> void:
	if not logger:
		logger = ConsoleLogger.new()
	
	if not card_repository:
		card_repository = RepositoryFactory.new_card_repository()
		card_repository.open()
	
	if not deck_repository:
		deck_repository = RepositoryFactory.new_deck_repository()
		deck_repository.open()
	
	if not deck_format_manager:
		deck_format_manager = FormatManager.new()
	
	if not printings_manager:
		printings_manager = PrintingsManager.new()
		printings_manager.load_tracker()
	
	#if not transition_manager:
		#transition_manager = TransitionManager.new()

func _exit_tree() -> void:
	if card_repository:
		card_repository.close()
	
	if deck_repository:
		deck_repository.close()
	
