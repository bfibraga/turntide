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

class LobbyCreateRequest extends _packets.LobbyCreateRequest:
	pass

class LobbyJoinRequest extends _packets.LobbyJoinRequest:
	pass

class LobbyLeaveRequest extends _packets.LobbyLeaveRequest:
	pass

class LobbyReadyRequest extends _packets.LobbyReadyRequest:
	pass

class LobbyStartRequest extends _packets.LobbyStartRequest:
	pass

class LobbyListRequest extends _packets.LobbyListRequest:
	pass

class LobbyListResponse extends _packets.LobbyListResponse:
	pass

class LobbyJoinedResponse extends _packets.LobbyJoinedResponse:
	pass

class LobbyPlayer extends _packets.LobbyPlayer:
	pass

class LobbyPlayerJoined extends _packets.LobbyPlayerJoined:
	pass

class LobbyPlayerLeft extends _packets.LobbyPlayerLeft:
	pass

class LobbyPlayerReady extends _packets.LobbyPlayerReady:
	pass

class LobbyGameStart extends _packets.LobbyGameStart:
	pass

class LobbyInfo extends _packets.LobbyInfo:
	pass
