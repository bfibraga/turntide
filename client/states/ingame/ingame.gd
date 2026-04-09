class_name IngameState
extends SceneHolderState

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger : Log = Global.logger
@onready var mouse_tracker: MouseTracker = $MouseTracker

static func Name() -> String:
	return "Ingame"

func _init() -> void:
	transition_config = preload("res://resources/transitions/slide_left.tres")
	packed_scene = preload("res://states/ingame/ingame.tscn")

func enter() -> void:
	WS.connection_closed.connect(_on_ws_connection_closed)
	WS.packet_received.connect(_on_ws_packet_received)
	
	if mouse_tracker:
		mouse_tracker.mouse_position_changed.connect(_on_mouse_position_changed)
		mouse_tracker.viewport = get_viewport()

	self.enter_scene()

func _on_ws_connection_closed() -> void:
	logger.error("Connection closed")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	var sender_id : int = packet.get_sender_id()
	if packet.has_chat():
		_handle_chat_msg(sender_id, packet.get_chat())

func _handle_chat_msg(sender_id: int, chat_msg: packets.ChatMessage) -> void:
	logger.chat("Client %d" % sender_id, chat_msg.get_msg())

func _on_mouse_position_changed(normalized_pos: Vector2) -> void:
	var packet := factory.new_player_msg(normalized_pos.x, normalized_pos.y)
	var err := WS.send(packet)
	if err:
		logger.error("Error sending mouse position")

func _on_line_edit_text_entered(text: String) -> void:
	var chat_packet : packets.Packet = factory.new_chat_msg(text)
	
	var err : Error = WS.send(chat_packet)
	if err:
		logger.error("Error sending chat message")
	else:
		logger.chat("You", text)
