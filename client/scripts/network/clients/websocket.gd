extends Node

const packets := preload("res://scripts/network/packets/packets.gd")
var socket : WebSocketPeer = WebSocketPeer.new()
var last_state : WebSocketPeer.State = WebSocketPeer.STATE_CLOSED

signal connected_to_server()
signal connection_closed()
signal packet_received(packet: packets.Packet)
signal auth_success(username: String)
signal auth_failed(reason: String)

func connect_to_url(url: String, tls_options: TLSOptions = null) -> Error:
	var err : Error = socket.connect_to_url(url, tls_options)
	if err != OK:
		return err
	
	last_state = socket.get_ready_state()
	return OK

func send(packet: packets.Packet) -> Error:
	#var sender_id : int = GameManager.client_id
	#packet.set_sender_id(sender_id)
	
	var data : PackedByteArray = packet.to_bytes()
	return socket.send(data)

func get_packet() -> packets.Packet:
	if socket.get_available_packet_count() < 1:
		return null
	
	var data : PackedByteArray = socket.get_packet()
	var packet : packets.Packet = packets.Packet.new()
	var result : Error = packet.from_bytes(data) as Error
	if result != OK:
		var msg : String = "Error forming packet from data %" % data.get_string_from_utf8()
		push_error(msg)
		printerr(msg)
	
	return packet

func close(code: int = 1000, reason: String = "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()

func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()

func get_socket() -> WebSocketPeer:
	return socket

func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()

	var state : WebSocketPeer.State = socket.get_ready_state()

	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		var pkt = get_packet()
		packet_received.emit(pkt)
		_handle_auth_packet(pkt)


func _process(_delta: float) -> void:
	poll()

func _handle_auth_packet(packet: packets.Packet) -> void:
	if packet.has_ok_response():
		var resp = packet.get_ok_response()
		auth_success.emit(resp.get_message())
	elif packet.has_deny_response():
		var resp = packet.get_deny_response()
		auth_failed.emit(resp.get_reason())

