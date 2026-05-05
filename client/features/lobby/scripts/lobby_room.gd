extends Control

const packets := preload("res://core/network/packets/packets.gd")

@onready var logger: Log = ConsoleLogger.new()
@onready var ready_button: Button = $%Ready
@onready var start_button: Button = $%Start
@onready var leave_button: Button = $%Leave

@onready var lobby_info_label: Label = $%LobbyInfo
@onready var players_list_container: Container = $%Players

var _is_ready: bool = false
var _players: Dictionary[int, packets.LobbyPlayer] = {}

@export_category("Lobby Data")
@export var lobby_name: String :
	set(value):
		lobby_name = value
		_update_lobby_info_label()
		
@export var hostname: String :
	set(value):
		hostname = value
		_update_lobby_info_label()

func _init(parameters: Dictionary[String, Variant] = {}) -> void:
	lobby_name = parameters.get("lobby_name", "")
	hostname = parameters.get("hostname", "")

func _update_lobby_info_label() -> void:
	if lobby_info_label:
		lobby_info_label.text = "Lobby: {name} - Host: {hostname}".format({
			"name": lobby_name,
			"hostname": hostname
		})

func _ready() -> void:
	WS.packet_received.connect(_on_ws_packet_received)
	
	ready_button.pressed.connect(_on_ready_button_pressed)
	start_button.pressed.connect(func() -> void: start_game())
	leave_button.pressed.connect(func() -> void: leave_lobby())
	
	_refresh_player_list()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	print(packet)
	if packet.has_lobby_player_joined():
		_handle_player_joined(packet.get_lobby_player_joined())
	elif packet.has_lobby_player_left():
		_handle_player_left(packet.get_lobby_player_left())
	elif packet.has_lobby_player_ready():
		_handle_player_ready(packet.get_lobby_player_ready())
	elif packet.has_lobby_game_start():
		_handle_game_start()

func _handle_player_joined(msg: packets.LobbyPlayerJoined) -> void:
	logger.info("Player joined: %s" % msg.get_player().get_username())
	# TODO: update UI list when scene is implemented
	if not msg.has_player():
		push_error("Empty player infomation, rolling back...")
		return
	
	var player_data: packets.LobbyPlayer = msg.get_player()
	_players[player_data.get_client_id()] = player_data
	
	_refresh_player_list()

func _handle_player_left(msg: packets.LobbyPlayerLeft) -> void:
	logger.info("Player left: %d" % msg.get_client_id())
	# TODO: update UI list when scene is implemented
	if not msg.has_player():
		push_error("Empty player infomation, rolling back...")
		return
	
	var player_data: packets.LobbyPlayer = msg.get_player()
	_players.erase(player_data.get_client_id())
	
	_refresh_player_list()

func _handle_player_ready(msg: packets.LobbyPlayerReady) -> void:
	logger.info("Player %d ready: %s" % [msg.get_client_id(), msg.get_ready()])

func _handle_game_start() -> void:
	logger.info("Game starting!")
	#transition_requested.emit(IngameState.Name())
	Global.game_controller.gui_transition_to(IngameState.Name())

func _refresh_player_list() -> void:
	# Clear children
	for child: Node in players_list_container.get_children():
		child.queue_free()
	
	# Add all players to the list
	for player_data: packets.LobbyPlayer in _players.values():
		var player_label: Label = Label.new()
		player_label.text = "{username} | {is_ready}".format({
			"username": player_data.get_username(),
			"is_ready": player_data.get_ready()
		})
		
		players_list_container.add_child(player_label)

func _on_ready_button_pressed() -> void:
	_is_ready = !_is_ready
	toggle_ready(_is_ready)

func leave_lobby() -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_leave_req()
	WS.send(packet)
	
	#transition_requested.emit(LobbyBrowserState.Name())
	Global.game_controller.gui_transition_to(LobbyBrowserState.Name())

func toggle_ready(is_ready: bool) -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_ready_req(is_ready)
	WS.send(packet)

func start_game() -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_start_req()
	WS.send(packet)
