extends ClientInterfacer

signal connected_to_server()
signal connection_closed()
signal packet_received(packet: Variant)

const packets := preload("res://core/network/packets/packets.gd")
var socket : WebSocketPeer = WebSocketPeer.new()
var last_state : WebSocketPeer.State = WebSocketPeer.STATE_CLOSED

func connect_to_url(url: String, tls_options: TLSOptions = null) -> Error:
	var err : Error = socket.connect_to_url(url, tls_options)
	if err != OK:
		return err
	
	last_state = socket.get_ready_state()
	return OK

func send(content: Variant) -> Error:
	var packet : packets.Packet = content as packets.Packet
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
