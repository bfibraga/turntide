extends Control

const packets := preload("res://scripts/network/packets/packets.gd")
const LobbyBrowserState := preload("res://states/lobby/browser.gd")

signal transition_requested(state_name: String)

@onready var logger : Log = Global.logger

@onready var username_input: LineEdit = $%UsernameInput
@onready var password_input: LineEdit = $%PasswordInput
@onready var error_label: Label = $%ErrorLabel
@onready var login_button: Button = $%LoginButton
@onready var register_button: Button = $%RegisterButton

func _ready() -> void:
	WS.packet_received.connect(_on_ws_packet_received)
	WS.connection_closed.connect(_on_ws_connection_closed)
	
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	username_input.text_submitted.connect(_on_username_submitted)
	password_input.text_submitted.connect(_on_password_submitted)
	username_input.grab_focus()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_deny_response():
		var deny_response_message : packets.DenyResponseMessage = packet.get_deny_response()
		logger.error(deny_response_message.get_reason())
		_on_auth_failed(deny_response_message.get_reason())
	elif packet.has_ok_response():
		_on_auth_success(username_input.text)

func _on_ws_connection_closed() -> void:
	pass

func _on_login_pressed() -> void:
	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text
	
	if username.is_empty() or password.is_empty():
		error_label.text = "Please enter username and password"
		return
	
	error_label.text = ""
	login_button.disabled = true
	
	var packet: packets.Packet = PacketFactory.new_login_request(username, password)
	WS.send(packet)

func _on_register_pressed() -> void:
	transition_requested.emit(RegisterState.Name())

func _on_username_submitted(_new_text: String) -> void:
	_on_login_pressed()

func _on_password_submitted(_new_text: String) -> void:
	_on_login_pressed()

func _on_auth_success(username: String) -> void:
	password_input.text = ""
	logger.success("Welcome back, %s" % username)
	transition_requested.emit(LobbyBrowserState.Name())

func _on_auth_failed(reason: String) -> void:
	error_label.text = "Login failed: " + reason
	login_button.disabled = false
	password_input.clear()
	password_input.grab_focus()
