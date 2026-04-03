extends Control

signal on_submit(text: String)

@onready var _log: Log = $VBoxContainer/Log/Log
@onready var _line_edit: LineEdit = $VBoxContainer/LineEdit

func _ready() -> void:
	Global.chat = self
	_line_edit.text_submitted.connect(_line_edit_text_submitted)

func _line_edit_text_submitted(new_text: String) -> void:
	self.on_submit.emit(new_text)
