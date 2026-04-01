class_name IngameState
extends State

@export var _log: Log
@export var _line_edit: LineEdit

const packets := preload("res://scripts/network/packets/packets.gd")

static func Name() -> String:
	return "Ingame"

func enter() -> void:
	WS.connection_closed.connect(_on_ws_connection_closed)
	WS.packet_received.connect(_on_ws_packet_received)

	_line_edit.text_submitted.connect(_on_line_edit_text_entered)

func _on_ws_connection_closed() -> void:
	_log.error("Connection closed")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	var sender_id : int = packet.get_sender_id()
	if packet.has_chat():
		_handle_chat_msg(sender_id, packet.get_chat())

func _handle_chat_msg(sender_id: int, chat_msg: packets.ChatMessage) -> void:
	_log.chat("Client %d" % sender_id, chat_msg.get_msg())

func _on_line_edit_text_entered(text: String) -> void:
	var chat_packet : packets.Packet = PacketFactory.new_chat_msg(text)
	
	var err : Error = WS.send(chat_packet)
	if err:
		_log.error("Error sending chat message")
	else:
		_log.chat("You", text)

	_line_edit.text = ""
