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

@export var fps_ms : int = 16

var properties: Array[StringName] = []

@onready var container: Container = $VBoxContainer

func _ready() -> void:
	Global.debug = self
	self.hide()

	var connected: ConnectionStatus = ConnectionStatus.new("Connected", Color.WEB_GREEN)
	var disconnected: ConnectionStatus = ConnectionStatus.new("Disconnected", Color.BROWN)

	WS.connected_to_server.connect(func() -> void: add_debug_property("Connection", connected.to_string()))
	WS.connection_closed.connect(func() -> void: add_debug_property("Connection", disconnected.to_string()))

func _physics_process(_delta: float) -> void:
	add_debug_property("FPS", Engine.get_frames_per_second())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_debug"):
		visible = not visible
		get_viewport().set_input_as_handled()
	
func add_debug_property(id: StringName, value: Variant, time_in_frames: int = 60) -> void:
	if properties.has(id):
		if Time.get_ticks_msec() / fps_ms % time_in_frames == 0:
			var target: RichTextLabel = container.find_child(id, true, false) as RichTextLabel
			target.text = id + ": " + str(value)
	else:
		var property: RichTextLabel = RichTextLabel.new()
		property.name = id
		property.text = id + ": " + str(value)
		property.fit_content = true
		property.bbcode_enabled = true
		
		container.add_child(property)
		properties.append(id) 
