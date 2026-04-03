class_name ConsoleLogger extends Log

func _message(message: String, _color: Color = Color.TRANSPARENT) -> void:
	print(message)

func info(message: String) -> void:
	_message(message)

func warning(message: String) -> void:
	_message(message)

func error(message: String) -> void:
	_message(message)

func success(message: String) -> void:
	_message(message)
	
func chat(sender_name: String, message: String) -> void:
	_message("%s: %s" % [sender_name, message])
