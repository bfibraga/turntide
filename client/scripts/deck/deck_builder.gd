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
extends Control

var deck_service: DeckService
var current_deck: Deck = null

@onready var deck_list_vbox: VBoxContainer = $"%DeckListVBox"
@onready var deck_name_edit: LineEdit = $"%DeckNameEdit"
@onready var format_select: OptionButton = $"%FormatSelect"
@onready var card_count_label: Label = $"%CardCountLabel"
@onready var cards_list: VBoxContainer = $"%CardsList"
@onready var name_filter: LineEdit = $"%NameFilter"
@onready var set_filter: LineEdit = $"%SetFilter"
@onready var search_button: Button = $"%SearchButton"
@onready var search_results_grid: GridContainer = $"%SearchResultsGrid"

var deck_list: Array[String] = []
var search_results: Array[CardMetadata] = []

func _ready() -> void:
	deck_service = DeckService.new(Global.card_repository)
	_setup_format_dropdown()
	_load_deck_list()
	_connect_signals()

func _connect_signals() -> void:
	$"%NewDeckButton".pressed.connect(_on_new_deck_pressed)
	$"%SaveButton".pressed.connect(_on_save_pressed)
	$"%DeleteButton".pressed._pressed.connect(_on_delete_pressed)
	search_button.pressed.connect(_on_search_pressed)
	deck_name_edit.text_changed.connect(_on_deck_name_changed)
	format_select.item_selected.connect(_on_format_selected)

func _setup_format_dropdown() -> void:
	var format_names: Array[String] = DeckFormat.get_all_display_names()
	for i in range(format_names.size()):
		format_select.add_item(format_names[i], i)

func _load_deck_list() -> void:
	deck_list = deck_service.list_decks()
	_update_deck_list_ui()

func _update_deck_list_ui() -> void:
	for child in deck_list_vbox.get_children():
		child.queue_free()
	
	for deck_name in deck_list:
		var button: Button = Button.new()
		button.text = deck_name
		button.pressed.connect(_on_deck_selected.bind(deck_name))
		deck_list_vbox.add_child(button)

func _update_deck_editor() -> void:
	if current_deck == null:
		deck_name_edit.text = ""
		format_select.select(0)
		card_count_label.text = "0 cards"
		_clear_cards_list()
		return
	
	deck_name_edit.text = current_deck.name
	
	var format_index: int = DeckFormat.from_string(current_deck.format)
	format_select.select(format_index)
	
	card_count_label.text = "%d cards" % current_deck.get_card_count()
	_update_cards_list()

func _clear_cards_list() -> void:
	for child in cards_list.get_children():
		child.queue_free()

func _update_cards_list() -> void:
	_clear_cards_list()
	
	if current_deck == null:
		return
	
	for deck_card in current_deck.cards:
		var metadata: CardMetadata = deck_service.get_card_metadata(deck_card.uuid)
		var card_name: String = metadata.name if metadata else "Unknown"
		
		var hbox: HBoxContainer = HBoxContainer.new()
		
		var name_label: Label = Label.new()
		name_label.text = "%s x%d" % [card_name, deck_card.quantity]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)
		
		var minus_btn: Button = Button.new()
		minus_btn.text = "-"
		minus_btn.pressed.connect(_on_remove_card.bind(deck_card.uuid))
		hbox.add_child(minus_btn)
		
		var plus_btn: Button = Button.new()
		plus_btn.text = "+"
		plus_btn.pressed.connect(_on_add_card.bind(deck_card.uuid))
		hbox.add_child(plus_btn)
		
		cards_list.add_child(hbox)

func _on_new_deck_pressed() -> void:
	current_deck = deck_service.create_deck("New Deck", "Commander")
	_load_deck_list()
	_update_deck_editor()

func _on_deck_selected(deck_name: String) -> void:
	current_deck = deck_service.load_deck(deck_name)
	_update_deck_editor()

func _on_save_pressed() -> void:
	if current_deck != null:
		deck_service.save_deck(current_deck)

func _on_delete_pressed() -> void:
	if current_deck != null:
		var deck_name: String = current_deck.name
		deck_service.delete_deck(deck_name)
		current_deck = null
		_load_deck_list()
		_update_deck_editor()

func _on_deck_name_changed(new_text: String) -> void:
	if current_deck != null:
		current_deck.name = new_text

func _on_format_selected(index: int) -> void:
	if current_deck != null:
		current_deck.format = format_select.get_item_text(index)

func _on_search_pressed() -> void:
	var query: Dictionary = {}
	if not name_filter.text.is_empty():
		query["name"] = name_filter.text
	if not set_filter.text.is_empty():
		query["setcode"] = set_filter.text
	query["page"] = 1
	query["page_size"] = 20
	
	search_results = Global.card_repository.search_cards(query)
	_update_search_results()

func _update_search_results() -> void:
	for child in search_results_grid.get_children():
		child.queue_free()
	
	for card in search_results:
		var button: Button = Button.new()
		button.text = card.name
		button.pressed.connect(_on_card_result_clicked.bind(card.uuid))
		search_results_grid.add_child(button)

func _on_card_result_clicked(card_uuid: String) -> void:
	if current_deck != null:
		current_deck.add_card(card_uuid, 1)
		deck_service.save_deck(current_deck)
		_update_deck_editor()

func _on_add_card(card_uuid: String) -> void:
	if current_deck != null:
		current_deck.add_card(card_uuid, 1)
		deck_service.save_deck(current_deck)
		_update_deck_editor()

func _on_remove_card(card_uuid: String) -> void:
	if current_deck != null:
		current_deck.remove_card(card_uuid, 1)
		deck_service.save_deck(current_deck)
		_update_deck_editor()