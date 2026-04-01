extends Control

@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var error_label = $VBoxContainer/ErrorLabel
@onready var login_button = $VBoxContainer/LoginButton
@onready var register_button = $VBoxContainer/RegisterButton
@onready var remember_checkbox = $VBoxContainer/RememberCheckBox

var _switching_scene: bool = false

func _ready() -> void:
	# Load saved credentials
	var saved = GameManager.load_saved_credentials()
	if saved["username"] != "":
		username_input.text = saved["username"]
		password_input.text = saved["password"]
		remember_checkbox.button_pressed = true
	
	# Connect button signals
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	
	# Connect auth signals from websocket
	if GameManager.get_websocket():
		GameManager.get_websocket().auth_success.connect(_on_auth_success)
		GameManager.get_websocket().auth_failed.connect(_on_auth_failed)
	
	# Allow pressing Enter to login
	password_input.text_submitted.connect(_on_password_submitted)
	
	# Focus username input
	username_input.grab_focus()

func _on_login_pressed() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	# Validate input
	if not _validate_input(username, password):
		return
	
	error_label.text = ""
	login_button.disabled = true
	
	# Save credentials if checkbox is checked
	if remember_checkbox.button_pressed:
		GameManager.save_credentials(username, password)
	else:
		GameManager.clear_saved_credentials()
	
	# Send login request
	GameManager.login(username, password)

func _on_register_pressed() -> void:
	# Switch to register scene
	if not _switching_scene:
		_switching_scene = true
		get_tree().change_scene_to_file("res://scenes/auth/register.tscn")

func _on_password_submitted(_new_text: String) -> void:
	_on_login_pressed()

func _on_auth_success(username: String) -> void:
	"""Handle successful authentication - transition to game"""
	if not _switching_scene:
		_switching_scene = true
		# Clear password from memory
		password_input.text = ""
		# Transition to game (Ingame state)
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_auth_failed(reason: String) -> void:
	"""Handle failed authentication"""
	error_label.text = "Login failed. Please try again."
	login_button.disabled = false
	password_input.clear()
	password_input.grab_focus()

func _validate_input(username: String, password: String) -> bool:
	"""Validate login input"""
	if username.is_empty():
		error_label.text = "Username cannot be empty"
		return false
	
	if password.is_empty():
		error_label.text = "Password cannot be empty"
		return false
	
	if username.length < 3:
		error_label.text = "Username must be at least 3 characters"
		return false
	
	if password.length < 6:
		error_label.text = "Password must be at least 6 characters"
		return false
	
	return true
