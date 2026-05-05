class_name LobbyItem extends Control

class LobbyItemData extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveValue = ReactiveValue.String("", self)
	var is_private: ReactiveValue = ReactiveValue.Boolean(false, self)
	var capacity: ReactiveValue = ReactiveValue.Int(0, self)
	var max_capacity: ReactiveValue = ReactiveValue.Int(0, self)
	
var data: LobbyItemData = LobbyItemData.new()

@export var lobby_name_label: RichTextLabel
@export var format_label: RichTextLabel
@export var public_indicator_label: RichTextLabel
@export var capacity_label: RichTextLabel

@export var join_button: Button

func _ready() -> void:
	data.lobby_name.reactive_changed.connect(func(r: Reactive) -> void: update_lobby_name_label(r.value))
	data.format.reactive_changed.connect(func(r: Reactive) -> void: update_format_label(r.value))
	data.is_private.reactive_changed.connect(func(r: Reactive) -> void: update_public_indicator_label(r.value))
	data.capacity.reactive_changed.connect(func(r: Reactive) -> void: update_capacity_label(r.value, data.max_capacity.value))
	data.max_capacity.reactive_changed.connect(func(r: Reactive) -> void: update_capacity_label(data.capacity.value, r.value))
	
	data.lobby_name.manually_emit()
	data.format.manually_emit()
	data.is_private.manually_emit()
	data.capacity.manually_emit()
	data.max_capacity.manually_emit()

func _enter_tree() -> void:
	data.lobby_name.manually_emit()
	data.format.manually_emit()
	data.is_private.manually_emit()
	data.capacity.manually_emit()
	data.max_capacity.manually_emit()
	
func update_lobby_name_label(lobby_name: String) -> void:
	print("Updating lobby name")
	lobby_name_label.clear()
	lobby_name_label.push_bold()
	lobby_name_label.append_text(lobby_name)
	lobby_name_label.pop()

func update_format_label(format: String) -> void:
	print("Updating format name")
	format_label.clear()
	format_label.push_italics()
	format_label.append_text(format)
	format_label.pop()
	
func update_public_indicator_label(is_private: bool) -> void:
	print("Updating public indicator name")
	public_indicator_label.clear()
	
	var color: Color = Color.CRIMSON if is_private else Color.WEB_GREEN
	var text: String = "Private" if is_private else "Public"
	
	public_indicator_label.append_text("[pulse][color=#%s]%s[/color][/pulse]" % [color.to_html(), text])
	
func update_capacity_label(capacity: int, max_capacity: int) -> void:
	print("Updating lobby name")
	capacity_label.clear()
	capacity_label.append_text("%d / %d" % [capacity, max_capacity])
