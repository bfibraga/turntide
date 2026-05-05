class_name Debug extends Control

# Helper data class for connection formating
class ConnectionStatus:
	var name: String = ""
	var color: Color = Color.WHITE
	
	func _init(name: String = "", color: Color = Color.WHITE) -> void:
		self.name = name
		self.color = color

	func _to_string() -> String:
		return "[color=#%s]%s[/color]" % [color.to_html(), name]

@export var state_machine: StateMachine

var connected_label: RichTextLabel = RichTextLabel.new()
var fps_counter: FPSCounter = FPSCounter.new()
var gui_state_label: Label = Label.new()

@onready var container: Container = $VBoxContainer

func _ready() -> void:
	Global.debug = self
	
	if state_machine:
		state_machine.state_changed.connect(func(_from: State, to: State) -> void: 
			gui_state_label.text = "State: %s" % to.Name()
		)

	var connected: ConnectionStatus = ConnectionStatus.new("Connected", Color.WEB_GREEN)
	var disconnected: ConnectionStatus = ConnectionStatus.new("Disconnected", Color.BROWN)

	WS.connected_to_server.connect(func() -> void: _set_connected_status(connected))
	WS.connection_closed.connect(func() -> void: _set_connected_status(disconnected))

func _set_connected_status(status: ConnectionStatus) -> void:
	connected_label.clear()
	
	var text: String = status.to_string()
	print(text)
	connected_label.append_text(text)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_debug"):
		visible = not visible
		get_viewport().set_input_as_handled()
	
