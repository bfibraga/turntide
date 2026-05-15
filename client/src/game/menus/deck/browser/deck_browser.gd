extends Control

enum ViewMode {
	LIST,
	GRID,
}

enum SortMode {
	NAME,
}

class Data extends Reactive:
	
	var name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveObject = ReactiveObject.new(null, self)
	var color_identity: ReactiveSet = ReactiveSet.new(Set.new(), self)
	
	var view_mode: ReactiveValue = ReactiveValue.new(ViewMode.LIST, self)
	var sort_by: ReactiveValue = ReactiveValue.new(SortMode.NAME, self)

	func _init() -> void:
		super._init()
	
	func _to_string() -> String:
		return """
			Name: {name}
			Format: {format}
			Color Identity: {color_identity}
			
			View Mode: {view_mode}
			Sort Mode: {sort_by}
		""".format({
			"name": name.value,
			"format": format.value,
			"color_identity": color_identity.value,
			"view_mode": view_mode.value,
			"sort_by": sort_by.value,
		})

@export var sort_algorithms: Dictionary[SortMode, Callable] = {
	SortMode.NAME: sort_by_name,
}

var _data: Data = Data.new()
var _deck_list: Array[DeckData] = []
var _show_deck_list: ReactiveArray = ReactiveArray.new()

# Query options
@onready var deck_name: SearchLineEdit = %Name
@onready var format: OptionButton = %Format

# Color Identity
@onready var red: CheckBox = %Red
@onready var blue: CheckBox = %Blue
@onready var white: CheckBox = %White
@onready var black: CheckBox = %Black
@onready var green: CheckBox = %Green

# Filter options
@onready var view_mode: OptionButton = %ViewMode
@onready var sort_by: OptionButton = %SortBy
@onready var create: Button = %Create

@onready var search_result: DeckList = %SearchResult
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

var DeckListItemScene : PackedScene = load("res://src/common/components/deck/item/deck_list_item.tscn")

func _create_decks() -> void:
	Global.deck_repository.create_deck(
		DeckData.Builder.new() \
			.from_dict({
				"deck_name": "Izzet deck",
				"color_identity": Set.new(["red", "blue"]),
				"tags": Set.new(["Spellslinger"]),
				"format": "Commander",
			})
			.build()
	)
	Global.deck_repository.create_deck(
		DeckData.Builder.new() \
			.from_dict({
				"deck_name": "Temur deck",
				"color_identity": Set.new(["red", "blue", "green"]),
				"tags": Set.new(["Dragons", "Ramp"]),
				"format": "Standard",
			})
			.build()
	)
	Global.deck_repository.create_deck(
		DeckData.Builder.new() \
			.from_dict({
				"deck_name": "Esper deck",
				"color_identity": Set.new(["white", "blue", "black"]),
			})
			.build()
	)

func _ready() -> void:
	Global.deck_repository.open()
	
	_create_decks()
	
	_deck_list = Global.deck_repository.list_decks()
	
	Global.logger.info("Loaded %d decks" % _deck_list.size())
	Global.logger.info("Decks: %s " % str(_deck_list))

	_show_deck_list.reactive_changed.connect(func(_reactive: Reactive) -> void:
		search_result.rebuild_from_list(_show_deck_list.value)
	)
	
	_data.reactive_changed.connect(func(_reactive: Reactive) -> void:
		var filtered_deck_list: Array = _deck_list.filter(func(item: DeckData) -> bool:
			var item_name: String = item.deck_name
			var field_name: String = _data.name.value
			
			var same_name: bool = field_name.strip_escapes() == "" \
				or item_name.to_lower().contains(field_name.to_lower())
			var same_color_identity: bool = _data.color_identity.value.size() == 0 \
				or ( item.color_identity.contains_all(_data.color_identity.value) )
			var same_format: bool = not _data.format.value \
				or (item.format and item.format == _data.format.value)
			
			return same_name and same_color_identity and same_format
		)
		filtered_deck_list.sort_custom(sort_algorithms[_data.sort_by.value])
		_show_deck_list.value = filtered_deck_list
	)
	
	deck_name.executed_search.connect(func(text: String) -> void:
		_data.name.value = text
	)
	deck_name.execute_search_empty_query.connect(func() -> void:
		_data.name.value = ""
	)
		
	(func() -> void:
		format.clear()
		format.add_item("Any", 0) # Any format
		
		var index: int = 1
		var available_formats: Array[BaseFormat] = Global.deck_format_manager.formats
		for format_object: BaseFormat in available_formats:
			format.add_item(format_object.display_name(), index)
			index += 1
	).call()
	
	format.item_selected.connect(func(index: int) -> void:
		_data.format.value = Global.deck_format_manager.formats.get(index - 1) if index > 0 else null
	)
	
	red.toggled.connect(change_color_identity.bind("red"))
	blue.toggled.connect(change_color_identity.bind("blue"))
	white.toggled.connect(change_color_identity.bind("white"))
	black.toggled.connect(change_color_identity.bind("black"))
	green.toggled.connect(change_color_identity.bind("green"))
	
	view_mode.item_selected.connect(func(index: int) -> void:
		_data.view_mode.value = index
	)
	
	sort_by.item_selected.connect(func(index: int) -> void:
		_data.sort_by.value = index
	)
	
	_deck_list.sort_custom(sort_algorithms[_data.sort_by.value])
	_show_deck_list.value = _deck_list
	

func change_color_identity(is_adding: bool, key: String) -> void:
	if is_adding:
		_data.color_identity.add(key)
	else: 
		_data.color_identity.remove(key)

func sort_by_name(thiz: DeckData, other: DeckData) -> bool:
	var thiz_name: String = thiz.deck_name
	var other_name: String = other.deck_name
	
	return thiz_name.naturalnocasecmp_to(other_name) < 0
