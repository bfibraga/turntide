extends Node

const packets := preload("res://src/common/network/packets/packets.gd")

# General

func new_chat_msg(msg: String) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var chat_msg : packets.ChatMessage = packet.new_chat()
	
	packet.set_sender_id(Global.client_id)
	
	chat_msg.set_msg(msg)
	return packet

func new_ping_msg(timestamp: int) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var ping_msg : packets.PingMessage = packet.new_ping()
	
	packet.set_sender_id(Global.client_id)
	
	ping_msg.set_timestamp(timestamp)
	return packet

# Auth

func new_login_request(username: String, password: String) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var login_msg : packets.LoginRequestMessage = packet.new_login_request()
	
	packet.set_sender_id(Global.client_id)
	
	login_msg.set_username(username)
	login_msg.set_password(password)
	return packet

func new_register_request(username: String, password: String) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var register_msg : packets.RegisterRequestMessage = packet.new_register_request()
	
	packet.set_sender_id(Global.client_id)
	
	register_msg.set_username(username)
	register_msg.set_password(password)
	return packet
	
# Lobby

func new_list_lobbies_request(
	name: Option, format: Option, state: Option,
	page: int = 1, page_size: int = 10,
	) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var list_lobbies_request : packets.ListLobbiesRequest = packet.new_list_lobbies_request()
	
	packet.set_sender_id(Global.client_id)
	
	list_lobbies_request.set_page(page)
	list_lobbies_request.set_page_size(page_size)
	
	name.map(list_lobbies_request.set_name)
	format.map(list_lobbies_request.set_format)
	state.map(list_lobbies_request.set_state)
	
	return packet

func new_create_lobby_request(
	name: String, format: BaseFormat, is_private: bool = false
) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var create_request : packets.CreateLobbyRequest = packet.new_create_lobby_request()
	
	packet.set_sender_id(Global.client_id)
	
	create_request.set_name(name)
	create_request.set_format(format.display_name())
	create_request.set_is_private(is_private)

	return packet

func new_join_lobby_request(
	lobby_id: int, password: Option
) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var join_request : packets.JoinLobbyRequest = packet.new_join_lobby_request()
	
	packet.set_sender_id(Global.client_id)
	
	join_request.set_lobby_id(lobby_id)
	password.map(join_request.set_password)

	return packet

func new_leave_lobby_request() -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var _leave_request : packets.LeaveLobbyRequest = packet.new_leave_lobby_request()
	
	packet.set_sender_id(Global.client_id)
	
	return packet

func new_ready_lobby_request(is_ready: bool = false) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var ready_request : packets.ReadyLobbyRequest = packet.new_ready_lobby_request()
	
	packet.set_sender_id(Global.client_id)
	
	ready_request.set_is_ready(is_ready)
	
	return packet

#func new_list_lobbies_response(  ) -> packets.Packet:
	#var packet : packets.Packet = packets.Packet.new()
	#var list_lobbies_response : packets.ListLobbiesResponse = packet.new_list_lobbies_response()
	#
	#return packet
