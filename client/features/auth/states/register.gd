extends Control

const packets := preload("res://core/network/packets/packets.gd")

@onready var logger : Log = Global.logger

@onready var username_input: LineEdit = $%UsernameInput
@onready var password_input: LineEdit = $%PasswordInput
@onready var confirm_password_input: LineEdit = $%ConfirmPasswordInput
@onready var error_label: Label = $%ErrorLabel
@onready var register_button: Button = $%RegisterButton
@onready var back_button: Button = $%BackButton

func _ready() -> void:
	WS.packet_received.connect(_on_ws_packet_received)
	WS.connection_closed.connect(_on_ws_connection_closed)
	
	register_button.pressed.connect(_on_register_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	confirm_password_input.text_submitted.connect(_on_confirm_password_submitted)
	
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

func _on_register_pressed() -> void:
	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text
	var confirm_password: String = confirm_password_input.text
	
	# Validate input
	if not _validate_input(username, password, confirm_password):
		return
	
	error_label.text = ""
	register_button.disabled = true
	
	var packet: packets.Packet = PacketFactory.new_register_request(username, password)
	WS.send(packet)

func _on_back_pressed() -> void:
	#transition_requested.emit(LoginState.Name())
	Global.game_controller.gui_transition_to(LoginState.Name())

func _on_confirm_password_submitted(_new_text: String) -> void:
	_on_register_pressed()

func _on_auth_success(_username: String) -> void:
	password_input.text = ""
	confirm_password_input.text = ""
	#transition_requested.emit(EnteredState.Name())
	Global.game_controller.gui_transition_to(EnteredState.Name())

func _on_auth_failed(_reason: String) -> void:
	"""Handle failed registration"""
	error_label.text = "Registration failed. Username may already exist."
	register_button.disabled = false
	password_input.clear()
	confirm_password_input.clear()
	password_input.grab_focus()

func _validate_input(username: String, password: String, confirm_password: String) -> bool:
	"""Validate registration input"""
	if username.is_empty():
		error_label.text = "Username cannot be empty"
		return false
	
	if username.length() < 3:
		error_label.text = "Username must be at least 3 characters"
		return false
	
	if password.is_empty():
		error_label.text = "Password cannot be empty"
		return false
	
	if password.length() < 6:
		error_label.text = "Password must be at least 6 characters"
		return false
	
	if password != confirm_password:
		error_label.text = "Passwords do not match"
		return false
	
	return true
