class_name LobbyBrowserState
extends State

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")
const InLobbyState := preload("res://states/lobby/in_lobby.gd")

@onready var logger: Log = Global.logger

var selected_lobby_index: int = -1
var lobby_ids: Array[int] = []

static func Name() -> String:
	return "LobbyBrowser"

func enter() -> void:
	logger.info("Entered Lobby Browser")
	# Request lobby list on enter
	var pkt = factory.new_lobby_list_req()
	Global.ws.send(pkt)

func exit() -> void:
	logger.info("Exiting Lobby Browser")

func _ready() -> void:
	# Get UI references
	var lobby_list = get_node_or_null("%LobbyList")
	if lobby_list:
		lobby_list.item_selected.connect(_on_lobby_selected)
	
	var create_btn = get_node_or_null("%CreateButton")
	if create_btn:
		create_btn.pressed.connect(_on_create_pressed)
	
	var join_btn = get_node_or_null("%JoinButton")
	if join_btn:
		join_btn.pressed.connect(_on_join_pressed)
	
	var private_check = get_node_or_null("%PrivateCheck")
	if private_check:
		private_check.toggled.connect(_on_private_toggled)
	
	# Populate format dropdown
	var format_select = get_node_or_null("%FormatSelect")
	if format_select:
		format_select.add_item("1v1")
		format_select.add_item("Commander")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_list_response():
		_handle_lobby_list(packet.get_lobby_list_response())
	elif packet.has_lobby_joined_response():
		_handle_lobby_joined(packet.get_lobby_joined_response())
	elif packet.has_deny_response():
		_handle_deny_response(packet.get_deny_response())

func _handle_lobby_list(response) -> void:
	logger.info("Received lobby list")
	var lobby_list = get_node_or_null("%LobbyList")
	if not lobby_list:
		return
	
	lobby_list.clear()
	lobby_ids.clear()
	
	var count = response.get_lobbies_size()
	for i in range(count):
		var lobby = response.get_lobbies(i)
		var text = "%s (%d/%d) - %s" % [lobby.get_name(), lobby.get_current_players(), lobby.get_max_players(), lobby.get_format()]
		if lobby.get_is_private():
			text = "[P] " + text
		lobby_list.add_item(text)
		lobby_ids.append(lobby.get_id())
		lobby_list.set_item_metadata(i, lobby.get_id())

func _handle_lobby_joined(msg) -> void:
	logger.info("Joined lobby: %s" % msg.get_lobby_name())
	Transitioned.emit(self, InLobbyState.Name())

func _handle_deny_response(msg) -> void:
	logger.error("Error: %s" % msg.get_reason())

func _on_lobby_selected(index: int) -> void:
	selected_lobby_index = index

func _on_create_pressed() -> void:
	var name_input = get_node_or_null("%LobbyNameInput")
	var format_select = get_node_or_null("%FormatSelect")
	var max_players_spin = get_node_or_null("%MaxPlayersSpin")
	var private_check = get_node_or_null("%PrivateCheck")
	var password_input = get_node_or_null("%PasswordInput")
	
	if not name_input or not format_select or not max_players_spin or not private_check or not password_input:
		return
		
	var name = name_input.text.strip_edges()
	if name.is_empty():
		logger.error("Please enter a lobby name")
		return
	
	var format = format_select.get_item_text(format_select.selected)
	var max_players = int(max_players_spin.value)
	var is_private = private_check.pressed
	var password = password_input.text if is_private else ""
	
	WS.send(factory.new_lobby_create_req(name, format, max_players, is_private, password))

func _on_join_pressed() -> void:
	if selected_lobby_index < 0:
		logger.error("Please select a lobby to join")
		return
	
	if selected_lobby_index >= lobby_ids.size():
		return
	
	var lobby_id = lobby_ids[selected_lobby_index]
	var password_input = get_node_or_null("%PasswordInput")
	var password = password_input.text if password_input else ""
	
	WS.send(factory.new_lobby_join_req(lobby_id, password))

func _on_private_toggled(is_private: bool) -> void:
	var password_input = get_node_or_null("%PasswordInput")
	if password_input:
		password_input.visible = is_private