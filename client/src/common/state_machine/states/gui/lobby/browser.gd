class_name LobbyBrowserState
extends SceneHolderState

const packets := preload("res://src/common/network/packets/packets.gd")

@onready var logger: Log = Global.logger

static func Name() -> String:
	return "Lobby Browser"

func enter() -> void:	
	var packet: packets.Packet = PacketFactory.new_lobby_list_req()
	WS.send(packet)
	
	super.enter()
