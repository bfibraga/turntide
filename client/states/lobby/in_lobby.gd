class_name InLobbyState
extends SceneHolderState

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger: Log = Global.logger

static func Name() -> String:
	return "InLobby"

func _init() -> void:
	packed_scene = preload("res://scenes/lobby_room.tscn")

func enter() -> void:
	super.enter()
	logger.info("Entered InLobby")

func exit() -> void:
	super.exit()

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_player_joined():
		_handle_player_joined(packet.get_lobby_player_joined())
	elif packet.has_lobby_player_left():
		_handle_player_left(packet.get_lobby_player_left())
	elif packet.has_lobby_player_ready():
		_handle_player_ready(packet.get_lobby_player_ready())
	elif packet.has_lobby_game_start():
		_handle_game_start()

func _handle_player_joined(msg) -> void:
	logger.info("Player joined: %s" % msg.get_player().get_username())

func _handle_player_left(msg) -> void:
	logger.info("Player left: %d" % msg.get_client_id())

func _handle_player_ready(msg) -> void:
	logger.info("Player %d ready: %s" % [msg.get_client_id(), msg.get_ready()])

func _handle_game_start() -> void:
	logger.info("Game starting!")
	Transitioned.emit(self, IngameState.Name())
