class_name LobbyItem extends Control

class Data extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveValue = ReactiveValue.String("", self)
	var is_private: ReactiveValue = ReactiveValue.Boolean(false, self)
	var capacity: ReactiveValue = ReactiveValue.Int(0, self)
	var max_capacity: ReactiveValue = ReactiveValue.Int(0, self)
	
	func _to_string() -> String:
		return """
			Lobby Name: {lobby_name}
			Format: {format}
			Private: {is_private}
			Capacity: {capacity}
			Max Capacity: {max_capacity}
		""".format({
			"lobby_name": lobby_name.value,
			"format": format.value,
			"is_private": is_private.value,
			"capacity": capacity.value,
			"max_capacity": max_capacity.value,
		})
	
const packets : Script = preload("res://src/common/network/packets/packets.gd")

var data: Data = Data.new()

@export var lobby_name_label: RichTextLabel
@export var format_label: RichTextLabel
@export var public_indicator_label: RichTextLabel
@export var capacity_label: RichTextLabel

@export var join_button: Button

func setup(lobby_info: packets.LobbyData) -> void:
	data.lobby_name.value = lobby_info.get_name()
#	data.format.value = lobby_info.get_format()
#	data.is_private.value = lobby_info.get_is_private()
	data.capacity.value = lobby_info.get_current_players()
	data.max_capacity.value = lobby_info.get_max_players()

func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		print(reactive)
		
		# Cleanup
		lobby_name_label.clear()
		lobby_name_label.clear()
		format_label.clear()
		public_indicator_label.clear()
		
		# Build labels
		# Lobby name
		lobby_name_label.push_bold()
		lobby_name_label.append_text(reactive.lobby_name.value)
		lobby_name_label.pop_all()

		# Format
		format_label.push_italics()
		format_label.append_text(reactive.format.value)
		format_label.pop_all()
		
		# Public Indicator
		var is_private: bool = reactive.is_private.value
		var color: Color = Color.CRIMSON if is_private else Color.WEB_GREEN
		var text: String = "Private" if is_private else "Public"
	
		public_indicator_label.append_text("[pulse][color=#%s]%s[/color][/pulse]" % [color.to_html(), text])
		public_indicator_label.pop_all()
		
		# Capacity
		capacity_label.clear()
		capacity_label.append_text("%d / %d" % [data.capacity.value, data.max_capacity.value])
		capacity_label.pop_all()
	)
	
	data.manually_emit()

func _enter_tree() -> void:
	data.manually_emit()
