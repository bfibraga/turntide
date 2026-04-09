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

func create_deck(deck: DeckCard.Deck) -> bool:
	var id: String = _get_safe_id(deck.name)
	
	var err: Error = save_data(id, deck.to_dict())
	if err != OK:
		return false
		
	_deck_cache[id] = deck
	return true

func load_deck(deck_name: String) -> DeckCard.Deck:
	var id: String = _get_safe_id(deck_name)
	
	if _deck_cache.has(id):
		return _deck_cache[id]
	
	var data: Variant = load_data(id)
	if not data:
		return null
	
	var deck: DeckCard.Deck = DeckCard.Deck.from_dict(data)
	_deck_cache[id] = deck
	
	return deck

## Replaces an existing deck's data. 
## If 'must_exist' is true, it will fail if the deck doesn't already exist.
func replace_deck(deck: DeckCard.Deck, must_exist: bool = true) -> bool:
	var id: String = _get_safe_id(deck.name)
	
	if must_exist and not exists(id):
		push_error("Attempted to replace non-existent deck: %s" % deck.name)
		return false
	
	# create_deck already handles save_data and _deck_cache sync
	return create_deck(deck) 

func delete_deck(deck_name: String) -> bool:
	var id: String = _get_safe_id(deck_name)
	var error: Error = delete(id)
	
	if error == OK:
		_deck_cache.erase(id)
		return true
		
	return false

func list_decks() -> PackedStringArray:
	var ids: PackedStringArray = list()
	ids.sort()
	return ids
