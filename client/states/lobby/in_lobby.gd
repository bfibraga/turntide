class_name InLobbyState
extends SceneHolderState

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger: Log = Global.logger
@onready var lobby_name_label: Label = null
@onready var player_list_container: VBoxContainer = null
@onready var ready_button: Button = null
@onready var start_button: Button = null
@onready var leave_button: Button = null
@onready var back_button: Button = null
@onready var status_label: Label = null

# Internal state
var current_lobby_id: int = 0
var is_host: bool = false
var is_ready: bool = false
var players: Array = []
var host_id: int = 0

static func Name() -> String:
	return "InLobby"

func _init() -> void:
	packed_scene = preload("res://scenes/lobby_room.tscn")

func enter() -> void:
	super.enter()
	logger.info("Entered InLobby")
	# Resolve node references from the instanced scene
	if has_node("LobbyNameLabel"):
		lobby_name_label = $LobbyNameLabel
	if has_node("PlayerList"):
		player_list_container = $PlayerList
	if has_node("Actions/ReadyButton"):
		ready_button = $Actions/ReadyButton
	if has_node("Actions/StartButton"):
		start_button = $Actions/StartButton
	if has_node("Header/LeaveButton"):
		leave_button = $Header/LeaveButton
	if has_node("Actions/BackButton"):
		back_button = $Actions/BackButton
	if has_node("StatusLabel"):
		status_label = $StatusLabel

	_setup_ui()

func exit() -> void:
	super.exit()
	_cleanup_ui()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_player_joined():
		_handle_player_joined(packet.get_lobby_player_joined())
	elif packet.has_lobby_player_left():
		_handle_player_left(packet.get_lobby_player_left())
	elif packet.has_lobby_player_ready():
		_handle_player_ready(packet.get_lobby_player_ready())
	elif packet.has_lobby_game_start():
		_handle_game_start()

func _setup_ui() -> void:
	if ready_button and not ready_button.is_connected("pressed", self, "_on_ready_pressed"):
		ready_button.pressed.connect(_on_ready_pressed)
	if start_button and not start_button.is_connected("pressed", self, "_on_start_pressed"):
		start_button.pressed.connect(_on_start_pressed)
	if leave_button and not leave_button.is_connected("pressed", self, "_on_leave_pressed"):
		leave_button.pressed.connect(_on_leave_pressed)
	if back_button and not back_button.is_connected("pressed", self, "_on_back_pressed"):
		back_button.pressed.connect(_on_back_pressed)

func _cleanup_ui() -> void:
	if ready_button and ready_button.is_connected("pressed", self, "_on_ready_pressed"):
		ready_button.pressed.disconnect(_on_ready_pressed)
	if start_button and start_button.is_connected("pressed", self, "_on_start_pressed"):
		start_button.pressed.disconnect(_on_start_pressed)
	if leave_button and leave_button.is_connected("pressed", self, "_on_leave_pressed"):
		leave_button.pressed.disconnect(_on_leave_pressed)
	if back_button and back_button.is_connected("pressed", self, "_on_back_pressed"):
		back_button.pressed.disconnect(_on_back_pressed)

func _on_ready_pressed() -> void:
	is_ready = not is_ready
	if ready_button:
		ready_button.text = "Not Ready" if is_ready else "Ready"
	var pkt = factory.new_lobby_ready_req(is_ready)
	Global.ws.send(pkt)

func _on_start_pressed() -> void:
	if not is_host:
		logger.warn("Only host can start the game")
		return
	var pkt = factory.new_lobby_start_req()
	Global.ws.send(pkt)

func _on_leave_pressed() -> void:
	var pkt = factory.new_lobby_leave_req()
	Global.ws.send(pkt)
	Transitioned.emit(self, "LobbyBrowser")

func _on_back_pressed() -> void:
	_on_leave_pressed()

func _handle_player_joined(msg) -> void:
	logger.info("Player joined: %s" % msg.get_player().get_username())
	# Add to players and update list
	players.append(msg.get_player())
	_update_player_list()

func _handle_player_left(msg) -> void:
	logger.info("Player left: %d" % msg.get_client_id())
	players = players.filter(func(p): return p.get_client_id() != msg.get_client_id())
	_update_player_list()

func _handle_player_ready(msg) -> void:
	logger.info("Player %d ready: %s" % [msg.get_client_id(), msg.get_ready()])
	for p in players:
		if p.get_client_id() == msg.get_client_id():
			p.set_ready(msg.get_ready())
			break
	_update_player_list()

func _handle_game_start() -> void:
	logger.info("Game starting!")
	Transitioned.emit(self, "Ingame")

func _update_player_list() -> void:
	if not player_list_container:
		return
	# Clear existing entries
	for child in player_list_container.get_children():
		child.queue_free()
	# Add player entries
	var ready_count = 0
	for player in players:
		var hbox = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = player.get_username()
		hbox.add_child(name_label)
		var ready_label = Label.new()
		ready_label.text = "✓ Ready" if player.get_ready() else "✗ Not Ready"
		ready_label.modulate = Color.GREEN if player.get_ready() else Color.RED
		hbox.add_child(ready_label)
		if player.get_client_id() == _get_host_id():
			var host_label = Label.new()
			host_label.text = " (HOST)"
			hbox.add_child(host_label)
		player_list_container.add_child(hbox)
		if player.get_ready():
			ready_count += 1
	# Update status
	if status_label:
		status_label.text = "Players: %d | Ready: %d/%d" % [players.size(), ready_count, players.size()]

func _get_host_id() -> int:
	return host_id
