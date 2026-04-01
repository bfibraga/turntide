class_name EnteredState
extends State

@export var _log: Log

const packets := preload("res://scripts/network/packets/packets.gd")

static func Name() -> String:
	return "Entered"

func enter() -> void:
	WS.connected_to_server.connect(_on_ws_connected_to_server)
	WS.connection_closed.connect(_on_ws_connection_closed)
	WS.packet_received.connect(_on_ws_packet_received)
	
	_log.info("Connecting to server...")
	var url : String = UrlBuilder.ws().host("localhost").port(4000).path("/ws").build()
	WS.connect_to_url(url)

func _on_ws_connected_to_server() -> void:
	_log.success("Connected to server")

func _on_ws_connection_closed() -> void:
	_log.error("Connection closed")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	var sender_id : int = packet.get_sender_id()
	if packet.has_id():
		_handle_id_msg(sender_id, packet.get_id())

func _handle_id_msg(_sender_id: int, id_msg: packets.IdMessage) -> void:
	var client_id: int = id_msg.get_id()
	GameManager.client_id = client_id
	
	Transitioned.emit(self, IngameState.Name())
