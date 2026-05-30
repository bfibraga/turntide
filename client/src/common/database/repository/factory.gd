extends Node

func new_card_repository(
	auto_open: bool = true, 
	path: String = CardRepository.DEFAULT_DB_PATH
	) -> CardRepository:
	var db : SQLite = SQLite.new()
	db.path = path
	
	var repo : CardRepository = CardRepository.new(db)
	if auto_open:
		var result: Result = repo.open()
		
		return repo if result.is_ok() else null
		
	return repo

func new_deck_repository(
	auto_open: bool = true, 
	path: String = DeckRepository.DECKS_DIR
	) -> DeckRepository:
	var repo: DeckRepository = DeckRepository.new(path)
	
	if auto_open:
		var result: Result = repo.open()
		
		return repo if result.is_ok() else null
	
	return repo

func new_keyword_repository(
	auto_open: bool = true,
	path: String = KeywordRepository.KEYWORDS_DIR
) -> KeywordRepository:
	var repo: KeywordRepository = KeywordRepository.new(path)
	
	if auto_open:
		var result: Result = repo.open()
		
		return repo if result.is_ok() else null
	
	return repo
