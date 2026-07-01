extends Control

class Data extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var hostname: ReactiveValue = ReactiveValue.String("", self)
	var is_ready: ReactiveValue = ReactiveValue.Boolean(false, self)
	var players: ReactiveArray = ReactiveArray.new([], self)

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
	data.is_ready.value = parameters.get("is_ready", false)
	data.players.value = parameters.get("players", [])

func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
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
	if packet.has_joined_lobby_response():
		_handle_joined_lobby(packet.get_joined_lobby_response())
	elif packet.has_left_lobby_response():
		_handle_left_lobby(packet.get_left_lobby_response())
	elif packet.has_update_player_lobby_status():
		_handle_update_player_lobby_status(packet.get_update_player_lobby_status())
	elif packet.has_lobby_game_started_response():
		_handle_lobby_game_started()
	
func _handle_joined_lobby(msg: packets.JoinedLobbyResponse) -> void:
	data.players.value = msg.get_players()

func _handle_left_lobby(msg: packets.LeftLobbyResponse) -> void:
	if Global.client_id == msg.get_client_id():
		Global.game_controller.gui_transition_to(LobbyBrowserState.Name())
		return
	
	var updated_players: Array = data.players.value.filter(
		func(player: packets.LobbyPlayerData) -> bool:
			return player.get_client_id() != msg.get_client_id()
	)
	
	data.players.value = updated_players.duplicate()

func _handle_update_player_lobby_status(msg: packets.UpdatePlayerLobbyStatus) -> void:
	var updated_player: packets.LobbyPlayerData = msg.get_updated_player()
	
	var updated_players: Array = data.players.value.map(
		func(player: packets.LobbyPlayerData) -> packets.LobbyPlayerData:
			if player.get_client_id() == updated_player.get_client_id():
				return updated_player
			
			return player
	)
	
	data.players.value = updated_players.duplicate()

func _handle_lobby_game_started() -> void:
	Global.game_controller.rollback_state_machine()
	Global.game_controller.gui_transition_to("ingame")

func _refresh_player_list(players: Array = data.players.value) -> void:
	# Clear children
	for child: Node in players_list_container.get_children():
		child.queue_free()
	
	# Add all players to the list
	for player_data: packets.LobbyPlayerData in players:
		var player_label: Label = Label.new()
		
		var me_prefix: String = " (me)" if player_data.get_client_id() == Global.client_id else ""
		
		player_label.text = "{username} | {is_ready}".format({
			"username": player_data.get_username() + me_prefix,
			"is_ready": player_data.get_is_ready(),
		})
		
		players_list_container.add_child(player_label)
#
func leave_lobby() -> void:
	var packet: packets.Packet = PacketFactory.new_leave_lobby_request()
	WS.send(packet)
	
func toggle_ready() -> void:
	data.is_ready.value = not data.is_ready.value
	
	var packet: packets.Packet = PacketFactory.new_ready_lobby_request(data.is_ready.value)
	WS.send(packet)
#
func start_game() -> void:
	var packet: packets.Packet = PacketFactory.new_start_game_request()
	WS.send(packet)
