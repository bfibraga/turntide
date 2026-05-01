class_name LobbyBrowserState
extends State

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger: Log = Global.logger
@onready var lobby_list: ItemList = null
@onready var lobby_name_input: LineEdit = null
@onready var format_selector: OptionButton = null
@onready var max_players_spinbox: SpinBox = null
@onready var is_private_checkbox: CheckBox = null
@onready var password_input: LineEdit = null
@onready var create_button: Button = null
@onready var join_password_input: LineEdit = null
@onready var join_button: Button = null
@onready var refresh_button: Button = null
@onready var back_button: Button = null

# Internal mapping of item index -> lobby id
var lobby_data: Array = []

static func Name() -> String:
	return "LobbyBrowser"

func enter() -> void:
	logger.info("Entered Lobby Browser")
	# Request lobby list on enter
	# Initialize UI references when scene is available
	if has_node("MainVBox/ContentHBox/LeftPane/LobbyList"):
		lobby_list = $MainVBox/ContentHBox/LeftPane/LobbyList
	if has_node("MainVBox/ContentHBox/RightPane/LobbyNameInput"):
		lobby_name_input = $MainVBox/ContentHBox/RightPane/LobbyNameInput
	if has_node("MainVBox/ContentHBox/RightPane/FormatSelector"):
		format_selector = $MainVBox/ContentHBox/RightPane/FormatSelector
	if has_node("MainVBox/ContentHBox/RightPane/MaxPlayersSpinBox"):
		max_players_spinbox = $MainVBox/ContentHBox/RightPane/MaxPlayersSpinBox
	if has_node("MainVBox/ContentHBox/RightPane/IsPrivateCheck"):
		is_private_checkbox = $MainVBox/ContentHBox/RightPane/IsPrivateCheck
	if has_node("MainVBox/ContentHBox/RightPane/PasswordInput"):
		password_input = $MainVBox/ContentHBox/RightPane/PasswordInput
	if has_node("MainVBox/ContentHBox/RightPane/CreateButton"):
		create_button = $MainVBox/ContentHBox/RightPane/CreateButton
	if has_node("MainVBox/ContentHBox/RightPane/JoinPasswordInput"):
		join_password_input = $MainVBox/ContentHBox/RightPane/JoinPasswordInput
	if has_node("MainVBox/ContentHBox/RightPane/JoinHBox/JoinButton"):
		join_button = $MainVBox/ContentHBox/RightPane/JoinHBox/JoinButton
	if has_node("MainVBox/ContentHBox/RightPane/JoinHBox/RefreshButton"):
		refresh_button = $MainVBox/ContentHBox/RightPane/JoinHBox/RefreshButton
	if has_node("MainVBox/BottomHBox/BackButton"):
		back_button = $MainVBox/BottomHBox/BackButton

	_setup_ui()
	var pkt = factory.new_lobby_list_req()
	Global.ws.send(pkt)

func exit() -> void:
	logger.info("Exiting Lobby Browser")
	_cleanup_ui()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_list_response():
		_handle_lobby_list(packet.get_lobby_list_response())

func _setup_ui() -> void:
	# Connect signals if nodes exist
	if lobby_list and not lobby_list.is_connected("item_selected", self, "_on_lobby_selected"):
		lobby_list.item_selected.connect(_on_lobby_selected)
	if create_button and not create_button.is_connected("pressed", self, "_on_create_pressed"):
		create_button.pressed.connect(_on_create_pressed)
	if join_button and not join_button.is_connected("pressed", self, "_on_join_pressed"):
		join_button.pressed.connect(_on_join_pressed)
	if refresh_button and not refresh_button.is_connected("pressed", self, "_on_refresh_pressed"):
		refresh_button.pressed.connect(_on_refresh_pressed)
	if back_button and not back_button.is_connected("pressed", self, "_on_back_pressed"):
		back_button.pressed.connect(_on_back_pressed)
	if is_private_checkbox and not is_private_checkbox.is_connected("toggled", self, "_on_private_toggled"):
		is_private_checkbox.toggled.connect(_on_private_toggled)

func _cleanup_ui() -> void:
	# Best-effort disconnects
	if lobby_list and lobby_list.is_connected("item_selected", self, "_on_lobby_selected"):
		lobby_list.item_selected.disconnect(_on_lobby_selected)
	if create_button and create_button.is_connected("pressed", self, "_on_create_pressed"):
		create_button.pressed.disconnect(_on_create_pressed)
	if join_button and join_button.is_connected("pressed", self, "_on_join_pressed"):
		join_button.pressed.disconnect(_on_join_pressed)
	if refresh_button and refresh_button.is_connected("pressed", self, "_on_refresh_pressed"):
		refresh_button.pressed.disconnect(_on_refresh_pressed)
	if back_button and back_button.is_connected("pressed", self, "_on_back_pressed"):
		back_button.pressed.disconnect(_on_back_pressed)
	if is_private_checkbox and is_private_checkbox.is_connected("toggled", self, "_on_private_toggled"):
		is_private_checkbox.toggled.disconnect(_on_private_toggled)

func _on_private_toggled(toggled: bool) -> void:
	if password_input:
		password_input.visible = toggled

func _on_lobby_selected(index: int) -> void:
	# no-op placeholder for selection; UI handlers will use lobby_data mapping
	logger.info("Selected lobby index: %d" % index)

func _on_create_pressed() -> void:
	var name = "New Lobby"
	if lobby_name_input and lobby_name_input.text != "":
		name = lobby_name_input.text
	var format = "1v1"
	if format_selector and format_selector.get_selected_id() == 1:
		format = "commander"
	var max_players = 2
	if max_players_spinbox:
		max_players = int(max_players_spinbox.value)
	var is_private = false
	if is_private_checkbox:
		is_private = is_private_checkbox.pressed
	var password = ""
	if is_private and password_input:
		password = password_input.text

	var pkt = factory.new_lobby_create_req(name, format, max_players, is_private, password)
	Global.ws.send(pkt)

func _on_join_pressed() -> void:
	if lobby_list and lobby_list.get_selected_items().size() > 0:
		var idx = lobby_list.get_selected_items()[0]
		if idx < lobby_data.size():
			var lobby_id = lobby_data[idx]
			var password = ""
			if join_password_input:
				password = join_password_input.text
			var pkt = factory.new_lobby_join_req(lobby_id, password)
			Global.ws.send(pkt)

func _on_refresh_pressed() -> void:
	var pkt = factory.new_lobby_list_req()
	Global.ws.send(pkt)

func _on_back_pressed() -> void:
	Transitioned.emit(self, "Entered")

func _handle_lobby_list(response) -> void:
	logger.info("Received lobby list")
	lobby_data.clear()
	if lobby_list:
		lobby_list.clear()
		for lobby_info in response.get_lobbies():
			var text = "%s (Format: %s, Players: %d/%d, Host: %s)" % [
				lobby_info.get_name(),
				lobby_info.get_format(),
				lobby_info.get_current_players(),
				lobby_info.get_max_players(),
				lobby_info.get_host_username()
			]
			if lobby_info.get_is_private():
				text = "🔒 " + text
			lobby_list.add_item(text)
			lobby_data.append(lobby_info.get_id())
