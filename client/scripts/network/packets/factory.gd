extends Node

const packets := preload("res://scripts/network/packets/packets.gd")

func new_chat_msg(msg: String) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var chat_msg : packets.ChatMessage = packet.new_chat()
	
	packet.set_sender_id(GameManager.client_id)
	
	chat_msg.set_msg(msg)
	return packet

func new_ping_msg(timestamp: int) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var ping_msg : packets.PingMessage = packet.new_ping()
	
	packet.set_sender_id(GameManager.client_id)
	
	ping_msg.set_timestamp(timestamp)
	return packet

func new_id_msg(id: int) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var id_msg : packets.IdMessage = packet.new_id()
	
	id_msg.set_id(id)
	return packet

func new_login_request(username: String, password: String) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var login_msg : packets.LoginRequestMessage = packet.new_login_request()
	
	login_msg.set_username(username)
	login_msg.set_password(password)
	return packet

func new_register_request(username: String, password: String) -> packets.Packet:
	var packet : packets.Packet = packets.Packet.new()
	var register_msg : packets.RegisterRequestMessage = packet.new_register_request()
	
	register_msg.set_username(username)
	register_msg.set_password(password)
	return packet
