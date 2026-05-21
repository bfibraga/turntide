class_name CardAtlas
extends Control

enum SortMode {
	NAME,
	MANA_VALUE,
}

class SearchData extends Reactive:
	var card_name: ReactiveValue = ReactiveValue.String("", self)
	var setCode: ReactiveValue = ReactiveValue.String("", self)

	var sort_mode: ReactiveValue = ReactiveValue.new(SortMode.NAME, self)
	var sort_by: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> String:
			match sort_mode.value:
				SortMode.NAME: return "name"
				SortMode.MANA_VALUE: return "manaValue"
			return "name",
		[sort_mode],
		self
	)

class ViewData extends Reactive:
	var page: ReactiveValue = ReactiveValue.Int(1, self)
	
	var card_width: ReactiveValue = ReactiveValue.Float(250, self)
	var grid_width: ReactiveValue = ReactiveValue.Float(1, self)
	var columns: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> int: return int(grid_width.value / card_width.value),
		[grid_width, card_width],
		self
	)
	var page_size: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> int: return int(_nearest_multiple(10, columns.value)),
		[columns],
		self
	)

	
	func _nearest_multiple(number: float, n: float) -> float:
		return n * round(number / n)

var search_data: SearchData = SearchData.new()
var view_data: ViewData = ViewData.new()
var search_on_scroll: bool = false

@onready var card_name_search : SearchLineEdit = $%CardName
@onready var setcode_search : SearchLineEdit = $%Set

@onready var grid : Control = $%Grid
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

@onready var sort_by: OptionButton = %SortBy

#@onready var card_content: RichTextLabel = $"MarginContainer/VBoxContainer/Main/Card Details/Content"

@onready var CardScene: PackedScene = preload("res://src/card/ui/card_ui.tscn")

func _ready() -> void:
	card_name_search.executed_search.connect(func(query: String) -> void:
		search_data.card_name.value = query
	)
	card_name_search.execute_search_empty_query.connect(func() -> void:
		search_data.card_name.value = ""
	)
	card_name_search.text_submitted.connect(func(_text: String) -> void:
		search_data.reactive_changed.emit(search_data)
	)
	
	setcode_search.executed_search.connect(func(query: String) -> void:
		search_data.setCode.value = query
	)
	setcode_search.execute_search_empty_query.connect(func() -> void:
		search_data.setCode.value = ""
	)
	setcode_search.text_submitted.connect(func(_text: String) -> void:
		search_data.reactive_changed.emit(search_data)
	)

	search_data.reactive_changed.connect(func(reactive: SearchData) -> void:
		if search_data.card_name.value == "" \
			or search_data.setCode.value == "":
			return
		
		cleanup_search()
		
		WorkerThreadPool.add_task(func() -> void:
			_search_card({
					"name": search_data.card_name.value, 
					"setCode": search_data.setCode.value,
					"sort_by": search_data.sort_by.value, 
					"page": reactive.page.value,
					"page_size": reactive.page_size.value,
				} 
			)
		)
	)
	
	view_data.reactive_changed.connect(func(reactive: ViewData) -> void:
		WorkerThreadPool.add_task(func() -> void:
			_search_card({
					"name": search_data.card_name.value, 
					"setCode": search_data.setCode.value,
					"sort_by": search_data.sort_by.value, 
					"page": reactive.page.value,
					"page_size": reactive.page_size.value,
				} 
			)
		)
	)

	Global.printings_manager.card_printing_ready.connect(_on_printings_download_completed)

	Global.card_repository = RepositoryFactory.new_card_repository()
	Global.card_repository.open()
	
	extensible_scroll_container.vertical_threshold_reached.connect(func() -> void:
		if !search_on_scroll:
			return
		
		view_data.page.value += 1
	)
	
	sort_by.item_selected.connect(func(index: int) -> void:
		search_data.sort_mode.value = index
	)
	
	extensible_scroll_container.item_rect_changed.connect(func() -> void:
		view_data.grid_width.value = extensible_scroll_container.size.x
	)

func nearest_multiple(number: float, n: float) -> float:
	return n * round(number / n)

func _search_card(
	params: Dictionary[String, Variant]
	) -> void:
	var cards: Array[CardData] = Global.card_repository.search_cards(params)
	
	for card_data: CardData in cards:
		var card: CardUI = CardScene.instantiate()
		card.data.card_data.value = card_data
		
		grid.add_child.call_deferred(card)
	
	search_on_scroll = cards.size() >= view_data.page_size.value
	
	Global.logger.info("Downloaded %d printings" % cards.size())
	Global.logger.info("Cards: %s" % str(cards))

#func _on_card_name_search(card_name: String) -> void:
	#data.page.value = 1
	#cleanup_search()
	#_search_card({"name": card_name, "setCode": setcode_search.text }, data.page.value, data.page_size.value)
	#
#func _on_setcode_search(setcode: String) -> void:
	#data.page.value = 1
	#cleanup_search()
	#_search_card({"name": card_name_search.text, "setCode": setcode }, data.page.value, data.page_size.value)


func cleanup_search() -> void:
	for child: Node in grid.get_children():
		child.queue_free()

func _on_printings_download_completed(_key: String, _path: String) -> void:
	#Global.logger.info("key: %s | path: %s" % [key, path])
	pass
