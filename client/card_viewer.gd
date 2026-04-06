class_name CardViewer
extends Control

@export var page : int = 1
@export var page_size : int = 10

@onready var card_name_search : SearchLineEdit = $%CardName
@onready var setcode_search : LineEdit = $%Set
@onready var page_spin_box: SpinBox = $%Page
@onready var total_spin_box: SpinBox = $%Total
@onready var back_button: Button = $%Back

@onready var grid : Control = $%Grid

func _ready() -> void:
	card_name_search.executed_search.connect(_on_card_name_search)
	card_name_search.text_submitted.connect(_on_card_name_search)
		
	page_spin_box.value_changed.connect(_on_page_spin_box_value_changed)
	total_spin_box.value_changed.connect(_on_total_spin_box_value_changed)

	Global.printings_manager.card_printing_ready.connect(_on_printings_download_completed)

	page_spin_box.value = page
	total_spin_box.value = page_size

	RepositoryFactory.new_card_repository()
	Global.card_repository.open()
	
	back_button.pressed.connect(_on_back_button_pressed)

func _on_card_name_search(card_name: String) -> void:
	grid.get_children().map(func(child): child.queue_free())
	
	var cards: Array[CardMetadata] = Global.card_repository.search_cards({ 
		"name": card_name,
		"page": page,
		"page_size": page_size 
	})
	
	for card_metadata: CardMetadata in cards:
		var card_view_node: CardView = CardFactory.create_card_view(card_metadata)

		grid.add_child(card_view_node)
	
	Global.logger.info("Downloaded %d printings" % cards.size())
	
func _on_printings_download_completed(key: String, path: String) -> void:
	#Global.logger.info("key: %s | path: %s" % [key, path])
	pass

func _on_page_spin_box_value_changed(value: float) -> void:
	page = int(value)

func _on_total_spin_box_value_changed(value: float) -> void:
	page_size = int(value)

func _on_back_button_pressed() -> void:
	Global.game_controller.transition_gui(EnteredState.Name())
