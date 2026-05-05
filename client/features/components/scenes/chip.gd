class_name Chip
extends PanelContainer

signal deleted(chip_ref: Chip)

@onready var label: Label = $%Label
@onready var delete_button: BaseButton = $%CloseButton

func _init(text: String = "", show_close: bool = true) -> void:
	setup(text, show_close)
	
	self.delete_button.pressed.connect(_on_delete_button_pressed)

func setup(text: String, show_close: bool = true) -> void:
	label.text = text
	delete_button.visible = show_close

func _on_delete_button_pressed() -> void:
	emit_signal("deleted", self)
	queue_free() # Removes the chip from the scene
