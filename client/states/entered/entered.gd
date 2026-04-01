class_name EnteredState
extends State

@export var _log: Log

const packets := preload("res://scripts/network/packets/packets.gd")

static func Name() -> String:
	return "Entered"

func enter() -> void:
	_log.info("Connecting to server...")
	
	# Initialize GameManager's websocket reference
	GameManager.initialize_websocket(WS)
	
	# Connect to websocket signals
	WS.connected_to_server.connect(_on_ws_connected_to_server)
	WS.connection_closed.connect(_on_ws_connection_closed)
	WS.packet_received.connect(_on_ws_packet_received)
	
	# Connect to auth result signals
	WS.auth_success.connect(_on_auth_success)
	WS.auth_failed.connect(_on_auth_failed)
	
	# Connect to server
	var url : String = GameManager.SERVER_URL
	WS.connect_to_url(url)
	
	# Show login scene
	get_tree().change_scene_to_file("res://scenes/auth/login.tscn")

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

func _on_auth_success(username: String) -> void:
	"""Handle successful authentication - user can proceed to game"""
	_log.success("Authenticated as: " + username)
	# Scene transition is handled by login.gd

func _on_auth_failed(reason: String) -> void:
	"""Handle failed authentication"""
	_log.error("Authentication failed: " + reason)
	# Error handling is done by login/register UI

