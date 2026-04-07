class_name DeckService
extends RefCounted

var _repository: DeckRepository
var _card_repository: CardRepository

func _init(card_repository: CardRepository) -> void:
	_repository = DeckRepository.new()
	_card_repository = card_repository

func create_deck(name: String, format: String = "Commander") -> DeckCard.Deck:
	var deck: DeckCard.Deck = DeckCard.Deck.new()
	deck.name = name
	deck.format = format
	_repository.save(deck)
	return deck

func save_deck(deck: DeckCard.Deck) -> bool:
	return _repository.save(deck)

func load_deck(name: String) -> DeckCard.Deck:
	return _repository.load(name)

func delete_deck(name: String) -> bool:
	return _repository.delete(name)

func list_decks() -> Array[String]:
	return _repository.list_decks()

func add_card(deck: DeckCard.Deck, card_uuid: String, quantity: int = 1) -> void:
	deck.add_card(card_uuid, quantity)

func remove_card(deck: DeckCard.Deck, card_uuid: String, quantity: int = 1) -> bool:
	return deck.remove_card(card_uuid, quantity)

func set_card_quantity(deck: DeckCard.Deck, card_uuid: String, quantity: int) -> void:
	deck.set_card_quantity(card_uuid, quantity)

func get_card_metadata(uuid: String) -> CardMetadata:
	var results: Array[CardMetadata] = _card_repository.search_cards({
		"uuid": uuid,
		"page": 1,
		"page_size": 1,
	})
	return results[0] if results.size() > 0 else null
