class_name LobbyBrowserState
extends State

const packets := preload("res://scripts/network/packets/packets.gd")
const factory := preload("res://scripts/network/packets/factory.gd")

@onready var logger: Log = Global.logger

static func Name() -> String:
	return "LobbyBrowser"

func enter() -> void:
	logger.info("Entered Lobby Browser")
	# Request lobby list on enter
	var pkt = factory.new_lobby_list_req()
	Global.ws.send(pkt)

func exit() -> void:
	logger.info("Exiting Lobby Browser")

func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_list_response():
		_handle_lobby_list(packet.get_lobby_list_response())

func _handle_lobby_list(response) -> void:
	logger.info("Received lobby list")
	# TODO: populate UI with response.get_lobbies()
