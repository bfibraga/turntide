class_name RichTextLogger
extends Log

var _rich_text_label: RichTextLabel

func _init() -> void:
	_rich_text_label = RichTextLabel.new()
	_rich_text_label.set_anchors_preset(PRESET_FULL_RECT)
	
	self.add_child(_rich_text_label)
	Global.logger = self

func _message(message: String, color: Color = Color.WHITE) -> void:
	_rich_text_label.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), str(message)])

func info(message: String) -> void:
	_message(message, Color.WHITE)

func warning(message: String) -> void:
	_message(message, Color.YELLOW)

func error(message: String) -> void:
	_message(message, Color.ORANGE_RED)

func success(message: String) -> void:
	_message(message, Color.LAWN_GREEN)
	
func chat(sender_name: String, message: String) -> void:
	_message("[color=#%s]%s:[/color] [i]%s[/i]" % [Color.CORNFLOWER_BLUE.to_html(false), sender_name, message])
