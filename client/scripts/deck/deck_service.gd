/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
class_name DeckService
extends RefCounted

var _repository: DeckRepository
var _card_repository: CardRepository

func _init(card_repository: CardRepository) -> void:
	_repository = DeckRepository.new()
	_card_repository = card_repository

func create_deck(name: String, format: String = "Commander") -> Deck:
	var deck: Deck = Deck.new()
	deck.name = name
	deck.format = format
	_repository.save(deck)
	return deck

func save_deck(deck: Deck) -> bool:
	return _repository.save(deck)

func load_deck(name: String) -> Deck:
	return _repository.load(name)

func delete_deck(name: String) -> bool:
	return _repository.delete(name)

func list_decks() -> Array[String]:
	return _repository.list_decks()

func add_card(deck: Deck, card_uuid: String, quantity: int = 1) -> void:
	deck.add_card(card_uuid, quantity)

func remove_card(deck: Deck, card_uuid: String, quantity: int = 1) -> bool:
	return deck.remove_card(card_uuid, quantity)

func set_card_quantity(deck: Deck, card_uuid: String, quantity: int) -> void:
	deck.set_card_quantity(card_uuid, quantity)

func get_card_metadata(uuid: String) -> CardMetadata:
	var results: Array[CardMetadata] = _card_repository.search_cards({
		"uuid": uuid,
		"page": 1,
		"page_size": 1,
	})
	return results[0] if results.size() > 0 else null