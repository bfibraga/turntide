class_name DeckBuilderState
extends SceneHolderState

var deck_service: DeckService
var current_deck: DeckCard.Deck = null
var deck_list: Array[String] = []

func _ready() -> void:
	deck_service = DeckService.new(Global.card_repository)
	_load_deck_list()

func _load_deck_list() -> void:
	deck_list = deck_service.list_decks()

func create_deck(name: String, format: String = "Commander") -> void:
	current_deck = deck_service.create_deck(name, format)
	_load_deck_list()
	_update_deck_editor()

func load_deck(name: String) -> void:
	current_deck = deck_service.load_deck(name)
	_update_deck_editor()

func save_current_deck() -> bool:
	if current_deck == null:
		return false
	return deck_service.save_deck(current_deck)

func delete_deck(name: String) -> bool:
	var result: bool = deck_service.delete_deck(name)
	if result:
		_load_deck_list()
		if current_deck != null and current_deck.name == name:
			current_deck = null
	return result

func add_card_to_deck(card_uuid: String) -> void:
	if current_deck == null:
		return
	deck_service.add_card(current_deck, card_uuid, 1)
	_update_deck_editor()
	save_current_deck()

func remove_card_from_deck(card_uuid: String) -> bool:
	if current_deck == null:
		return false
	var result: bool = deck_service.remove_card(current_deck, card_uuid, 1)
	if result:
		_update_deck_editor()
		save_current_deck()
	return result

func set_card_quantity(card_uuid: String, quantity: int) -> void:
	if current_deck == null:
		return
	deck_service.set_card_quantity(current_deck, card_uuid, quantity)
	_update_deck_editor()
	save_current_deck()

func search_cards(query: Dictionary) -> Array[CardMetadata]:
	return Global.card_repository.search_cards(query)

func get_card_metadata(uuid: String) -> CardMetadata:
	return deck_service.get_card_metadata(uuid)

func _update_deck_editor() -> void:
	pass

func enter_scene() -> void:
	super.enter_scene()
	_load_deck_list()

static func Name() -> String:
	return "DeckBuilder"
