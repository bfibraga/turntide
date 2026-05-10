class_name Chip
extends PanelContainer

class Data extends Reactive:
	var text: ReactiveValue = ReactiveValue.String("", self)
	var color: ReactiveValue = ReactiveValue.new(Color.DARK_GRAY, self)

signal deleted(chip_ref: Chip)

var data: Data = Data.new()

@onready var label: Label = %Label

func _init(text: String = "", color: Color = Color.DARK_GRAY) -> void:
	data.text.value = text
	data.color.value = color
	
	self.deleted.connect(func(chip: Chip) -> void: chip.queue_free())
	
func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		label.text = reactive.text.value
		set_color(reactive.color.value)
	)
	
	data.manually_emit()

func set_color(color: Color) -> void:
	var style_box: StyleBoxFlat = self.get_theme_stylebox("panel")
	style_box.bg_color = color
