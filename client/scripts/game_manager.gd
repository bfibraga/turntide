extends Node

const CREDENTIALS_PATH = "user://turntide_credentials.cfg"
const SERVER_URL = "ws://localhost:4000/ws"

var client_id: int = -1
var username: String = ""
var is_authenticated: bool = false

var _websocket: Node = null
var _credentials: Node = null
var _packet_factory: Node = null

func _ready() -> void:
	# Auto-load utilities
	_credentials = preload("res://scripts/utils/credentials.gd").new()
	_packet_factory = preload("res://scripts/network/packets/factory.gd").new()
	add_child(_packet_factory)

func initialize_websocket(websocket_client: Node) -> void:
	"""Store reference to websocket and connect signals"""
	_websocket = websocket_client
	_websocket.auth_success.connect(_on_auth_success)
	_websocket.auth_failed.connect(_on_auth_failed)

func get_websocket() -> Node:
	"""Get the websocket client"""
	return _websocket

func get_packet_factory() -> Node:
	"""Get the packet factory"""
	return _packet_factory

func login(username: String, password: String) -> void:
	"""Send login request to server"""
	if not _websocket:
		printerr("WebSocket not initialized")
		return
	
	var packet = _packet_factory.new_login_request(username, password)
	var err = _websocket.send(packet)
	if err != OK:
		printerr("Failed to send login request: ", err)

func register(username: String, password: String) -> void:
	"""Send register request to server"""
	if not _websocket:
		printerr("WebSocket not initialized")
		return
	
	var packet = _packet_factory.new_register_request(username, password)
	var err = _websocket.send(packet)
	if err != OK:
		printerr("Failed to send register request: ", err)

func save_credentials(username_val: String, password_val: String) -> void:
	"""Save credentials locally (obfuscated)"""
	if _credentials:
		_credentials.save_credentials(username_val, password_val, CREDENTIALS_PATH)

func load_saved_credentials() -> Dictionary:
	"""Load saved credentials from local storage"""
	if _credentials:
		return _credentials.load_credentials(CREDENTIALS_PATH)
	return {"username": "", "password": ""}

func clear_saved_credentials() -> void:
	"""Clear saved credentials"""
	if _credentials:
		_credentials.clear_credentials(CREDENTIALS_PATH)

func _on_auth_success(username_from_server: String) -> void:
	"""Handle successful authentication"""
	username = username_from_server
	is_authenticated = true
	# Emit or handle auth success (state machine will handle scene changes)

func _on_auth_failed(reason: String) -> void:
	"""Handle failed authentication"""
	username = ""
	is_authenticated = false
	# Emit or handle auth failure (UI will show error message)

