extends Control

@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var confirm_password_input = $VBoxContainer/ConfirmPasswordInput
@onready var error_label = $VBoxContainer/ErrorLabel
@onready var register_button = $VBoxContainer/RegisterButton
@onready var back_button = $VBoxContainer/BackButton

var _switching_scene: bool = false

func _ready() -> void:
	# Connect button signals
	register_button.pressed.connect(_on_register_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect auth signals from websocket
	if GameManager.get_websocket():
		GameManager.get_websocket().auth_success.connect(_on_auth_success)
		GameManager.get_websocket().auth_failed.connect(_on_auth_failed)
	
	# Allow pressing Enter to register
	confirm_password_input.text_submitted.connect(_on_confirm_password_submitted)
	
	# Focus username input
	username_input.grab_focus()

func _on_register_pressed() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text
	var confirm_password = confirm_password_input.text
	
	# Validate input
	if not _validate_input(username, password, confirm_password):
		return
	
	error_label.text = ""
	register_button.disabled = true
	
	# Send register request
	GameManager.register(username, password)

func _on_back_pressed() -> void:
	# Switch back to login scene
	if not _switching_scene:
		_switching_scene = true
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")

func _on_confirm_password_submitted(_new_text: String) -> void:
	_on_register_pressed()

func _on_auth_success(username: String) -> void:
	"""Handle successful registration - transition to game"""
	if not _switching_scene:
		_switching_scene = true
		# Clear passwords from memory
		password_input.text = ""
		confirm_password_input.text = ""
		# Transition to game (Ingame state)
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_auth_failed(reason: String) -> void:
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
	
	if username.length < 3:
		error_label.text = "Username must be at least 3 characters"
		return false
	
	if password.is_empty():
		error_label.text = "Password cannot be empty"
		return false
	
	if password.length < 6:
		error_label.text = "Password must be at least 6 characters"
		return false
	
	if password != confirm_password:
		error_label.text = "Passwords do not match"
		return false
	
	return true
