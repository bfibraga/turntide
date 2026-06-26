extends MarginContainer

const KEYWORD_JSON_PATH: String = "res://assets/keywords/keywords.json"


class KeywordNodeItem extends FoldableContainer:
	class KeywordItem extends Reactive:
		var name: ReactiveValue = ReactiveValue.String("", self)
		var description: ReactiveValue = ReactiveValue.String("", self)
		
		func _init(name: String = "", description: String = "", initial_owner: Reactive = null) -> void:
			self.name.value = name
			self.description.value = description
			super._init(initial_owner)
		
		func to_dict() -> Dictionary:
			return {
				"name": name.value,
				"description": description.value
			}

	var data: KeywordItem = KeywordItem.new()
	
	var description_text_edit: TextEdit = TextEdit.new()
	var save_button: Button = Button.new()
	
	func _init(name: String, description: String) -> void:
		data = KeywordItem.new()
		
		data.reactive_changed.connect(func(reactive: KeywordItem) -> void:
			self.title = reactive.name.value
			description_text_edit.text = reactive.description.value
		)
	
	func _ready() -> void:			
		description_text_edit.placeholder_text = "Description"
		description_text_edit.custom_minimum_size.y = 300
		
		save_button.text = "Save"
		save_button.pressed.connect(save)
		
		for component: Control in [description_text_edit, save_button]:
			self.add_child(component)
				
		data.manually_emit()
		
	func save() -> void:
		data.description.value = description_text_edit.text
	
class KeywordMetadata:
	var abilityWords: PackedStringArray = []
	var keywordAbilities: PackedStringArray = []
	var keywordActions: PackedStringArray = []
	
	class Builder extends RefCounted:
		var _properties: Dictionary[String, Variant] = {}

		func from_dict(data: Dictionary) -> Builder:
			_properties.merge(data, true)
			return self

		func build() -> KeywordMetadata:
			var result: KeywordMetadata = KeywordMetadata.new()

			for property: String in _properties:
				result.set(property, _properties.get(property))

			return result
	
	func to_dict() -> Dictionary:
		return {
			"abilityWords": abilityWords,
			"keywordAbilities": keywordAbilities,
			"keywordActions": keywordActions,
		}

@export var url: String = "https://mtgjson.com/api/v5/Keywords.json"
@export_file_path() var export_path: String = KEYWORD_JSON_PATH
@export_file_path() var database_path: String

var is_metadata_ready: ReactiveValue = ReactiveValue.Boolean(true)
var metadata_file_path: ReactiveValue = ReactiveValue.String(export_path)
var metadata: ComputedReactiveValue = ComputedReactiveValue.new(
	func() -> KeywordMetadata: 
		var result: Result = load_data(metadata_file_path.value)
		if result.is_ok():
			is_metadata_ready.value = true
			return KeywordMetadata.Builder.new().from_dict(result.unwrap().data).build()
		else: 
			push_warning("Not ok load result: ", result)
			
		return null,
	[metadata_file_path]
)

@onready var fetch: Button = %Fetch
@onready var save: Button = %Save
@onready var choose_file: Button = %"Choose File"

@onready var file_dialog: FileDialog = %FileDialog
@onready var keyword_container: GridContainer = %KeywordContainer
@onready var status_label: RichTextLabel = %StatusLabel

func _ready() -> void:
	metadata.reactive_changed.connect(func(reactive: ComputedReactiveValue) -> void:
		var data: KeywordMetadata = reactive.value
		
		for abilityWord: String in data.abilityWords:
			var item: KeywordNodeItem = KeywordNodeItem.new(abilityWord, "")
			item.data.owner = metadata
	)
	
	var pending_status: String = "[color=#aaaaaa][pulse]Pending[/pulse][/color]"
	var ready_status: String = "[color=#00aa10][b]Ready[/b][/color]"
	
	is_metadata_ready.reactive_changed.connect(func(reactive: ReactiveValue) -> void:
		status_label.clear()
		
		var text: String = ready_status if reactive.value else pending_status
		status_label.append_text(text)
	)
	
	choose_file.pressed.connect(func() -> void: file_dialog.popup_centered())
	
	file_dialog.file_selected.connect(func(path: String) -> void:
		metadata_file_path.value = path
	)
	
	fetch.pressed.connect(func() -> void: fetch_data())
	save.pressed.connect(func() -> void: save_data(database_path))
	
	if not FileAccess.file_exists(metadata_file_path.value):
		fetch_data()

	metadata_file_path.manually_emit()
	
func fetch_data() -> Result:
	is_metadata_ready.value = false
	HttpRequestManager.request(
		func(http: HTTPRequest) -> void:
			http.download_file = ProjectSettings.globalize_path(metadata_file_path.value),
		func(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
			if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
				push_error("Failed to download keyword data: result=%d, http=%d" % [result, response_code])
				return
			
			is_metadata_ready.value = true,
		url
	)
	
	return Result.Ok(0)

func load_data(path: String = KEYWORD_JSON_PATH) -> Result:
	if not FileAccess.file_exists(path):
		return Result.from_gderr(ERR_FILE_NOT_FOUND)
	
	return Result.parse_json_file(path)
	
func save_data(path: String = database_path) -> Result:
	if not FileAccess.file_exists(path):
		return Result.from_gderr(ERR_FILE_NOT_FOUND)
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	var data: Dictionary = metadata.value.to_dict()
	file.store_string(JSON.stringify(data))
	
	file.close()
	
	return Result.Ok(0)
