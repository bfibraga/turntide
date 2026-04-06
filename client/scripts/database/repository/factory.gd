extends Node

func new_card_repository(path: String = CardRepository.DEFAULT_DB_PATH) -> Repository:
	var db : SQLite = SQLite.new()
	db.path = path
	
	var repo : CardRepository = CardRepository.new(db)
	Global.card_repository = repo
	
	return repo
