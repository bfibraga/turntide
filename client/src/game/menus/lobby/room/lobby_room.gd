extends Control

class Data extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var hostname: ReactiveValue = ReactiveValue.String("", self)
	var is_ready: ReactiveValue = ReactiveValue.Boolean(false, self)
	var players: ReactiveValue = ReactiveValue.new({}, self)

	func _to_string() -> String:
		return """
		Lobby Name: {lobby_name}
		Hostname: {hostname}
		Ready: {is_ready}
		Players: {players} 
		""".format({
			"lobby_name": lobby_name.value,
			"hostname": hostname.value,
			"is_ready": is_ready.value,
			"players": players.value,
		})

const packets := preload("res://src/common/network/packets/packets.gd")

@onready var ready_button: Button = $%Ready
@onready var start_button: Button = $%Start
@onready var leave_button: Button = $%Leave

@onready var lobby_name: RichTextLabel = %"Lobby Name"
@onready var hostname: RichTextLabel = %Hostname
@onready var players_list_container: Container = $%Players

var data: Data = Data.new()

func _init(parameters: Dictionary = {}) -> void:
	data.lobby_name.value = parameters.get("lobby_name", "")
	data.hostname.value = parameters.get("hostname", "")
	#data.players.value = parameters.get("players", {})

func _ready() -> void:
	
	data.reactive_changed.connect(func(reactive: Data) -> void:
		print(reactive)
		
		lobby_name.text = reactive.lobby_name.value
		hostname.text = reactive.hostname.value
		
		_refresh_player_list(reactive.players.value)
	)
	
	WS.packet_received.connect(_on_ws_packet_received)
	WS.connection_closed.connect(func() -> void: leave_lobby())
	
	ready_button.pressed.connect(func() -> void: toggle_ready())
	start_button.pressed.connect(func() -> void: start_game())
	leave_button.pressed.connect(func() -> void: leave_lobby())
	
	data.manually_emit()

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
	Global.logger.info("Player joined: %s" % msg.get_player().get_username())
	# TODO: update UI list when scene is implemented
	if not msg.has_player():
		push_error("Empty player infomation, rolling back...")
		return
	
	var player_data: packets.LobbyPlayer = msg.get_player()
	data.players.value[player_data.get_client_id()] = player_data
	
func _handle_player_left(msg: packets.LobbyPlayerLeft) -> void:
	Global.logger.info("Player left: %d" % msg.get_client_id())
	# TODO: update UI list when scene is implemented
	if not msg.has_client_id():
		push_error("Empty player infomation, rolling back...")
		return
	
	var player_id: int = msg.get_client_id()
	data.players.value.erase(player_id)
	
func _handle_player_ready(msg: packets.LobbyPlayerReady) -> void:
	Global.logger.info("Player %d ready: %s" % [msg.get_client_id(), msg.get_ready()])

func _handle_game_start() -> void:
	Global.logger.info("Game starting!")
	#transition_requested.emit(IngameState.Name())
	Global.game_controller.gui_transition_to("ingame")

func _refresh_player_list(players: Dictionary = data.players.value) -> void:
	# Clear children
	for child: Node in players_list_container.get_children():
		child.queue_free()
	
	# Add all players to the list
	for player_data: packets.LobbyPlayer in players.values():
		var player_label: Label = Label.new()
		player_label.text = "{username} | {is_ready}".format({
			"username": player_data.get_username(),
			"is_ready": player_data.get_ready()
		})
		
		players_list_container.add_child(player_label)

func leave_lobby() -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_leave_req()
	WS.send(packet)
	
	Global.game_controller.gui_transition_to(LobbyBrowserState.Name())

func toggle_ready() -> void:
	data.is_ready.value = not data.is_ready.value
	
	var packet: packets.Packet = PacketFactory.new_lobby_ready_req(data.is_ready.value)
	WS.send(packet)

func start_game() -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_start_req()
	WS.send(packet)
