class_name CardViewer
extends Control

signal transition_requested(state_name: String)

@export var page : int = 1
@export var page_size : int = 10

@onready var card_name_search : SearchLineEdit = $%CardName
@onready var setcode_search : SearchLineEdit = $%Set

@onready var back_button: Button = $%Back

@onready var previous_button: Button = $%Previous
@onready var next_button: Button = $%Next
@onready var page_number_label: Label = $"%Page Number"

@onready var grid : Control = $%Grid

@onready var card_content: RichTextLabel = $"MarginContainer/VBoxContainer/Main/Card Details/Content"

func _ready() -> void:
	card_name_search.executed_search.connect(_on_card_name_search)
	card_name_search.text_submitted.connect(_on_card_name_search)
	
	setcode_search.executed_search.connect(_on_card_name_search)
	setcode_search.text_submitted.connect(_on_card_name_search)

	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)

	Global.printings_manager.card_printing_ready.connect(_on_printings_download_completed)

	RepositoryFactory.new_card_repository()
	Global.card_repository.open()
	
	back_button.pressed.connect(_on_back_button_pressed)

func _search_card(
	card_name : String = "", 
	setcode: String = "",
	) -> void:
	grid.get_children().map(func(child: Node) -> void: child.queue_free())
	
	var cards: Array[CardMetadata] = Global.card_repository.search_cards({ 
		"name": card_name,
		"setcode": setcode,
		"page": page,
		"page_size": page_size 
	})
		
	for card_metadata: CardMetadata in cards:
		#var card_view_node: CardView = CardFactory.create_card_view(card_metadata)
		var card_node: Card = CardFactory.create_card(card_metadata)
		
		card_node.controller.pressed.connect(func(_card: Card) -> void: _on_pressed_card(card_metadata))

		grid.add_child(card_node)
	
	Global.logger.info("Downloaded %d printings" % cards.size())

func _on_pressed_card(card_data: CardMetadata) -> void:
	card_content.text = """
		{name} : {mana_value}
		{text}
		{power} / {toughness}
	""".format(card_data.to_dict())

func _on_card_name_search(card_name: String) -> void:
	page = 1
	_search_card(card_name, setcode_search.text)
	
func _on_setcode_search(setcode: String) -> void:
	page = 1
	_search_card(card_name_search.text, setcode)
	
func _on_printings_download_completed(_key: String, _path: String) -> void:
	#Global.logger.info("key: %s | path: %s" % [key, path])
	pass

func _on_previous_button_pressed() -> void:
	page = max(page - 1, 1)
	_search_card.call_deferred(card_name_search.text, setcode_search.text)
	page_number_label.text = "%d" % [page]
	
func _on_next_button_pressed() -> void:
	page = page + 1
	_search_card.call_deferred(card_name_search.text, setcode_search.text)
	page_number_label.text = "%d" % [page]
	
func _on_back_button_pressed() -> void:
	transition_requested.emit(EnteredState.Name())
