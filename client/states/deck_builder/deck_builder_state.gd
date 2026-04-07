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
class_name DeckBuilderState
extends SceneHolderState

var deck_service: DeckService
var current_deck: Deck = null
var deck_list: Array[String] = []

@onready var deck_list_panel: Control = $"%DeckListPanel"
@onready var deck_editor_panel: Control = $"%DeckEditorPanel"
@onready var card_search_panel: Control = $"%CardSearchPanel"

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

func Name() -> String:
	return "DeckBuilder"