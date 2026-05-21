class_name DeckBrowser extends Control

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

signal request_create_deck()
signal open_deck(deck_data: DeckData)

var _data: Data = Data.new()
var _deck_list: ReactiveArray = ReactiveArray.new()
#var _show_deck_list: ReactiveArray = ReactiveArray.new()
var _show_deck_list: ComputedReactiveValue = ComputedReactiveValue.new(
	func() -> Array[DeckData]:
		var filtered_deck_list: Array = _deck_list.value.filter(func(item: DeckData) -> bool:
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
		
		return filtered_deck_list,
	[_data, _deck_list]
)

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
			})
			.build()
	)
	Global.deck_repository.create_deck(
		DeckData.Builder.new() \
			.from_dict({
				"deck_name": "Temur deck",
				"color_identity": Set.new(["red", "blue", "green"]),
				"tags": Set.new(["Dragons", "Ramp"]),
				"format": StandardFormat.display_name(),
			})
			.build()
	)
	Global.deck_repository.create_deck(
		DeckData.Builder.new() \
			.from_dict({
				"deck_name": "Esper deck",
				"color_identity": Set.new(["white", "blue", "black"]),
				"format": CommanderFormat.display_name(),
				"tags": ["Control"],
				"mainboard": { 
					"c520083e-2e84-5cb1-9a68-23371df6848e": 1,
					"77767c8d-d296-51f7-b4f0-e3b8e3ce5448": 1,
					"8daf03e7-a532-5180-ac58-aa51e47035c0": 3,
					"50e420e0-f088-59a7-8ecd-b6c18692e4f8": 1,
					"fe8e3907-8669-55d2-8408-ff8fdf2721e5": 1,
					"e430ff2e-182f-5aaa-a0b2-8c6b9d2291a5": 2,
					"6ca663ba-f367-51b1-bb96-47f6b3e58d10": 1,
					"0e384fee-9537-581a-a047-9ae9b12b6940": 1
				}
			})
			.build()
	)
	pass

func _ready() -> void:
	Global.deck_repository.open()
	
	#_create_decks()

	var on_deck_selected: Callable = func(deck_data: DeckData) -> void:
		self.open_deck.emit(deck_data)

	_show_deck_list.reactive_changed.connect(func(_reactive: Reactive) -> void:
		search_result.rebuild_from_list(_show_deck_list.value, on_deck_selected)
	)
	
	#_data.reactive_changed.connect(func(_reactive: Reactive) -> void:
		#var filtered_deck_list: Array = _deck_list.filter(func(item: DeckData) -> bool:
			#var item_name: String = item.deck_name
			#var field_name: String = _data.name.value
			#
			#var same_name: bool = field_name.strip_escapes() == "" \
				#or item_name.to_lower().contains(field_name.to_lower())
			#var same_color_identity: bool = _data.color_identity.value.size() == 0 \
				#or ( item.color_identity.contains_all(_data.color_identity.value) )
			#var same_format: bool = not _data.format.value \
				#or (item.format and item.format == _data.format.value)
			#
			#return same_name and same_color_identity and same_format
		#)
#
		#_show_deck_list.value = filtered_deck_list
	#)
	
	_deck_list.value = Global.deck_repository.list_decks()
	
	Global.logger.info("Loaded %d decks" % _deck_list.value.size())
	Global.logger.info("Decks: %s " % str(_deck_list.value))
	
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
	
	create.pressed.connect(func() -> void:
		request_create_deck.emit()
		
		_deck_list.value = Global.deck_repository.list_decks()
		_data.manually_emit()
	)
	
	#_show_deck_list.value = _deck_list
	_data.manually_emit()

func change_color_identity(is_adding: bool, key: String) -> void:
	if is_adding:
		_data.color_identity.add(key)
	else: 
		_data.color_identity.remove(key)

func sort_by_name(thiz: DeckData, other: DeckData) -> bool:
	var thiz_name: String = thiz.deck_name
	var other_name: String = other.deck_name
	
	return thiz_name.naturalnocasecmp_to(other_name) < 0
