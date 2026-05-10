extends Node

func new_card_repository(path: String = CardRepository.DEFAULT_DB_PATH) -> Repository:
	var db : SQLite = SQLite.new()
	db.path = path
	
	var repo : CardRepository = CardRepository.new(db)	
	return repo

func new_deck_repository(path: String = DeckRepository.DECKS_DIR) -> Repository:	
	return DeckRepository.new(path)
