class_name DeckRepository
extends JSONDirectoryRepository

const DECKS_DIR: String = "user://cache/decks"

# Use the sanitized filename as the key to prevent collisions
var _deck_cache: Dictionary = {} 

func _init(path: String = DECKS_DIR) -> void:
	super(path, ".json")

## Only returns the base filename (no extension, no directory)
func _get_safe_id(deck_name: String) -> String:
	return deck_name.to_lower() \
		.replace(" ", "-") \
		.replace("/", "") \
		.replace("\\", "")

func create_deck(deck: DeckData) -> bool:
	var id: String = _get_safe_id(deck.deck_name)
	
	var result: Result = save_data(id, deck.to_dict())
	if result.is_err():
		return false
		
	_deck_cache[id] = deck
	return true

func load_deck(deck_name: String) -> DeckData:
	# Load by the display name by converting to the safe id, then delegating
	# to the id-based loader. This keeps loading logic in one place.
	var id: String = _get_safe_id(deck_name)
	return _load_by_id(id)

## Replaces an existing deck's data. 
## If 'must_exist' is true, it will fail if the deck doesn't already exist.
func replace_deck(deck: DeckData, must_exist: bool = true) -> bool:
	var id: String = _get_safe_id(deck.name)
	
	if must_exist and not exists(id):
		push_error("Attempted to replace non-existent deck: %s" % deck.name)
		return false
	
	# create_deck already handles save_data and _deck_cache sync
	return create_deck(deck) 

func delete_deck(deck_name: String) -> bool:
	var id: String = _get_safe_id(deck_name)
	var result: Result = delete(id)
	
	if result.is_ok():
		_deck_cache.erase(id)
		return true
		
	return false

func list_decks() -> Array[DeckData]:
	# Return full DeckData objects for all decks in the repository.
	# This will populate the internal cache as a side effect.
	var ids: PackedStringArray = list()
	ids.sort()

	var decks: Array[DeckData] = []
	for id: String in ids:
		var deck: DeckData = _load_by_id(id)
		if deck:
			decks.append(deck)

	return decks


func _load_by_id(id: String) -> DeckData:
	# Internal helper: load a deck by its sanitized filename (id).
	if _deck_cache.has(id):
		return _deck_cache[id]

	var data: Variant = load_data(id)
	if not data:
		return null

	var deck: DeckData = DeckData.Builder.new() \
		.from_dict(data) \
		.build()

	_deck_cache[id] = deck
	return deck
