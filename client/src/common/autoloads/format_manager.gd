class_name FormatManager
extends RefCounted

signal added_new_deck_format(format: BaseFormat)

var formats: Array[BaseFormat] = [
	StandardFormat.new(),
	CommanderFormat.new(),
]

func _init() -> void:
	self.added_new_deck_format.connect(_on_adding_new_deck_format)
	
func _on_adding_new_deck_format(format: BaseFormat) -> void:
	self.formats.append(format)

func find_from_name(format_name: String) -> Option:
	var index: int = formats.find_custom(func(format: BaseFormat) -> bool:
		return format.display_name() == format_name
	)
	
	if index == -1:
		return Option.None()
	
	return Option.new(formats[index])

var void_method: Callable = func() -> void: pass
