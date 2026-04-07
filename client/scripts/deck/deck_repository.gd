class_name DeckRepository
extends RefCounted

const DECKS_DIR: String = "cache/decks"
const FILE_EXTENSION: String = ".json"

var _deck_cache: Dictionary = {}

func _init() -> void:
	_ensure_directory()

func _ensure_directory() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("Failed to open user:// directory")
		return false
	
	var path: String = DECKS_DIR
	if not dir.dir_exists(path):
		var err: Error = dir.make_dir_recursive(path)
		if err != OK:
			push_error("Failed to create decks directory: " + str(err))
			return false
	return true

func _get_file_path(deck_name: String) -> String:
	var safe_name: String = deck_name.replace(" ", "-").to_lower()
	safe_name = safe_name.replace("/", "").replace("\\", "")
	return "user://%s/%s%s" % [DECKS_DIR, safe_name, FILE_EXTENSION]

func save(deck: DeckCard.Deck) -> bool:
	var path: String = _get_file_path(deck.name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to open deck file for writing: " + path)
		return false
	
	var json: String = JSON.stringify(deck.to_dict(), "\t")
	file.store_string(json)
	file.close()
	
	_deck_cache[deck.name] = deck
	return true

func load(deck_name: String) -> DeckCard.Deck:
	if _deck_cache.has(deck_name):
		return _deck_cache[deck_name]
	
	var path: String = _get_file_path(deck_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to open deck file: " + path)
		return null
	
	var json_str: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_str)
	if error != OK:
		push_error("Failed to parse deck JSON: " + json.get_error_message())
		return null
	
	var deck: DeckCard.Deck = DeckCard.Deck.from_dict(json.data)
	_deck_cache[deck.name] = deck
	return deck

func delete(deck_name: String) -> bool:
	var path: String = _get_file_path(deck_name)
	var dir: DirAccess = DirAccess.open("user://" + DECKS_DIR)
	
	if dir == null:
		return false
	
	var err: Error = dir.remove(path)
	if err != OK:
		push_error("Failed to delete deck: " + str(err))
		return false
	
	_deck_cache.erase(deck_name)
	return true

func list_decks() -> Array[String]:
	var dir: DirAccess = DirAccess.open("user://" + DECKS_DIR)
	if dir == null:
		return []
	
	var deck_names: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(FILE_EXTENSION):
			var name: String = file_name.replace(FILE_EXTENSION, "").replace("-", " ")
			deck_names.append(name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	deck_names.sort()
	return deck_names

func exists(deck_name: String) -> bool:
	var path: String = _get_file_path(deck_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	file.close()
	return true
