class_name CardAtlas
extends Control

enum SortMode {
	NAME,
}

class Data extends Reactive:
	var page: ReactiveValue = ReactiveValue.Int(1, self)
	
	var card_width: ReactiveValue = ReactiveValue.Float(1, self)
	var grid_width: ReactiveValue = ReactiveValue.Float(1, self)
	var columns: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> int: return int(grid_width.value / card_width.value),
		[grid_width, card_width],
		self
	)
	var page_size: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> int: return _nearest_multiple(10, columns.value),
		[columns],
		self
	)
	var sort_mode: ReactiveValue = ReactiveValue.new(SortMode.NAME, self)
	
	func _nearest_multiple(number: float, n: float) -> float:
		return n * round(number / n)

@export var sort_algorithms: Dictionary[SortMode, Callable] = {
	SortMode.NAME: sort_card_by_name,
}

var data: Data = Data.new()
var search_on_scroll: bool = false

@onready var card_name_search : SearchLineEdit = $%CardName
@onready var setcode_search : SearchLineEdit = $%Set

@onready var grid : Control = $%Grid
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

@onready var sort_by: OptionButton = %SortBy

#@onready var card_content: RichTextLabel = $"MarginContainer/VBoxContainer/Main/Card Details/Content"

@onready var CardScene: PackedScene = preload("res://src/card/ui/card_ui.tscn")

func _ready() -> void:
	card_name_search.executed_search.connect(_on_card_name_search)
	card_name_search.execute_search_empty_query.connect(cleanup_search)
	card_name_search.text_submitted.connect(_on_card_name_search)
	
	setcode_search.executed_search.connect(_on_setcode_search)
	setcode_search.execute_search_empty_query.connect(cleanup_search)
	setcode_search.text_submitted.connect(_on_setcode_search)

	Global.printings_manager.card_printing_ready.connect(_on_printings_download_completed)

	Global.card_repository = RepositoryFactory.new_card_repository()
	Global.card_repository.open()
	
	extensible_scroll_container.vertical_threshold_reached.connect(func() -> void:
		if !search_on_scroll:
			return
		
		data.page.value += 1
		WorkerThreadPool.add_task(func() -> void:
			_search_card(
				card_name_search.text, 
				setcode_search.text, 
				data.page.value, 
				data.page_size.value
			)		
		)
	)
	
	sort_by.item_selected.connect(func(index: int) -> void:
		data.sort_mode.value = SortMode.get(index)
	)
	
	data.card_width.value = 250.0
	extensible_scroll_container.item_rect_changed.connect(func() -> void:
		data.grid_width.value = extensible_scroll_container.size.x
	)

func nearest_multiple(number: float, n: float) -> float:
	return n * round(number / n)

func _search_card(
	card_name : String = "", 
	setcode: String = "",
	page: int = 1,
	page_size: int = 10,
	) -> void:
	#for child: Node in grid.get_children():
		#child.queue_free()
	
	var cards: Array[CardData] = Global.card_repository.search_cards({ 
		"name": card_name,
		"setcode": setcode,
		"page": page,
		"page_size": page_size 
	})
	cards.sort_custom(sort_algorithms.get(data.sort_mode.value, sort_card_by_name))
	
	for card_data: CardData in cards:
		var card: CardUI = CardScene.instantiate()
		card.data.card_data.value = card_data
		
		grid.add_child.call_deferred(card)
	
	search_on_scroll = cards.size() >= data.page_size.value
	
	Global.logger.info("Downloaded %d printings" % cards.size())
	Global.logger.info("Cards: %s" % str(cards))

func _on_card_name_search(card_name: String) -> void:
	data.page.value = 1
	cleanup_search()
	_search_card(
		card_name, 
		setcode_search.text, 
		data.page.value, 
		data.page_size.value
	)
	
func _on_setcode_search(setcode: String) -> void:
	data.page.value = 1
	cleanup_search()
	_search_card(
		card_name_search.text, 
		setcode, 
		data.page.value, 
		data.page_size.value
	)

func cleanup_search() -> void:
	for child: Node in grid.get_children():
		child.queue_free()

func _on_printings_download_completed(_key: String, _path: String) -> void:
	#Global.logger.info("key: %s | path: %s" % [key, path])
	pass

func sort_card_by_name(thiz: CardData, other: CardData) -> bool:
	var thiz_name: String = thiz.name
	var other_name: String = other.name
	
	return thiz_name.naturalnocasecmp_to(other_name)
	
