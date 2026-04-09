class_name FormatManager
extends RefCounted

signal added_new_deck_format(format: BaseFormat)

var formats: Array[BaseFormat] = []

func _init() -> void:
	self.added_new_deck_format.connect(_on_adding_new_deck_format)
	
func _on_adding_new_deck_format(format: BaseFormat) -> void:
	self.formats.append(format)
