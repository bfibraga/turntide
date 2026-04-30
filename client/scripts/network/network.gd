extends Node

const _packets := preload("res://scripts/network/packets/packets.gd")

class Packet extends _packets.Packet:
	pass

class ChatMessage extends _packets.ChatMessage:
	pass

class PingMessage extends _packets.PingMessage:
	pass

class IdMessage extends _packets.IdMessage:
	pass

class LoginRequestMessage extends _packets.LoginRequestMessage:
	pass

class RegisterRequestMessage extends _packets.RegisterRequestMessage:
	pass

class DenyResponseMessage extends _packets.DenyResponseMessage:
	pass
