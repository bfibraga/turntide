class_name InLobbyState
extends SceneHolderState

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")
const IngameState := preload("res://states/ingame/ingame.gd")
const LobbyBrowserState := preload("res://states/lobby/browser.gd")

@onready var logger: Log = Global.logger

var lobby_info = null
var is_host: bool = false

static func Name() -> String:
	return "InLobby"

func _init() -> void:
	packed_scene = preload("res://scenes/lobby_room.tscn")

func enter() -> void:
	super.enter()
	logger.info("Entered InLobby")
	
	# Connect UI signals
	var leave_btn = get_node_or_null("%LeaveButton")
	if leave_btn:
		leave_btn.pressed.connect(_on_leave_pressed)
	
	var ready_btn = get_node_or_null("%ReadyButton")
	if ready_btn:
		ready_btn.toggled.connect(_on_ready_toggled)
	
	var start_btn = get_node_or_null("%StartButton")
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)

func exit() -> void:
	super.exit()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_joined_response():
		_handle_lobby_joined(packet.get_lobby_joined_response())
	elif packet.has_lobby_player_joined():
		_handle_player_joined(packet.get_lobby_player_joined())
	elif packet.has_lobby_player_left():
		_handle_player_left(packet.get_lobby_player_left())
	elif packet.has_lobby_player_ready():
		_handle_player_ready(packet.get_lobby_player_ready())
	elif packet.has_lobby_game_start():
		_handle_game_start()

func _handle_lobby_joined(msg) -> void:
	logger.info("Received lobby info: %s" % msg.get_lobby_name())
	lobby_info = msg
	
	# Set lobby title
	var title_label = get_node_or_null("%LobbyTitleLabel")
	if title_label:
		title_label.text = "Lobby: %s" % msg.get_lobby_name()
	
	# Check if we are host
	is_host = (msg.get_host_username() == Global.username)
	
	# Show/hide start button based on host
	var start_btn = get_node_or_null("%StartButton")
	if start_btn:
		start_btn.visible = is_host
	
	# Populate player list
	_update_player_list(msg.get_players())

func _handle_player_joined(msg) -> void:
	var player = msg.get_player()
	logger.info("Player joined: %s" % player.get_username())
	_update_player_list_add(player)

func _handle_player_left(msg) -> void:
	logger.info("Player left: %d" % msg.get_client_id())
	_update_player_list_remove(msg.get_client_id())

func _handle_player_ready(msg) -> void:
	logger.info("Player %d ready: %s" % [msg.get_client_id(), "yes" if msg.get_ready() else "no"])
	_update_player_ready_status(msg.get_client_id(), msg.get_ready())

func _handle_game_start() -> void:
	logger.info("Game starting!")
	Transitioned.emit(self, IngameState.Name())

func _update_player_list(players) -> void:
	var player_list = get_node_or_null("%PlayerList")
	if not player_list:
		return
	
	player_list.clear()
	var count = players.get_players_size()
	for i in range(count):
		var player = players.get_players(i)
		var text = player.get_username()
		if player.get_ready():
			text += " (Ready)"
		player_list.add_item(text)

func _update_player_list_add(player) -> void:
	var player_list = get_node_or_null("%PlayerList")
	if player_list:
		player_list.add_item(player.get_username())

func _update_player_list_remove(client_id: int) -> void:
	# This would need to map client_id to username
	# For now just refresh the list when we get the next update
	pass

func _update_player_ready_status(client_id: int, ready: bool) -> void:
	# This would need to update the item text to show ready status
	pass

func _on_leave_pressed() -> void:
	WS.send(factory.new_lobby_leave_req())
	Transitioned.emit(self, LobbyBrowserState.Name())

func _on_ready_toggled(ready: bool) -> void:
	WS.send(factory.new_lobby_ready_req(ready))
	var ready_btn = get_node_or_null("%ReadyButton")
	if ready_btn:
		ready_btn.text = "Ready" if ready else "Not Ready"

func _on_start_pressed() -> void:
	if is_host:
		WS.send(factory.new_lobby_start_req())