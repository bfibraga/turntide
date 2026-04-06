class_name ConnectedState
extends State

const packets := preload("res://scripts/network/packets/packets.gd")

@onready var logger: Log = Global.logger

func _ready() -> void:
	logger.info("Connecting to server...")
	
	# Connect to websocket signals
	WS.connected_to_server.connect(_on_ws_connected_to_server)
	WS.connection_closed.connect(_on_ws_connection_closed)
	WS.packet_received.connect(_on_ws_packet_received)
	
	# Connect to server
	var url : String = UrlBuilder.ws().host("localhost").port(4000).path("ws").build()
	WS.connect_to_url(url)
	
	RepositoryFactory.new_card_repository()
	Global.card_repository.open()
	
	var count: int = Global.card_repository.count_cards()
	
	Global.logger.info("Total of cards: %d" % count)

func _on_ws_connected_to_server() -> void:
	logger.success("Connected to server")
	self.Transitioned.emit(self, LoginState.Name())

func _on_ws_connection_closed() -> void:
	logger.error("Connection closed")
	self.Transitioned.emit(self, ClosedState.Name())

func _on_ws_packet_received(packet: packets.Packet) -> void:
	var sender_id : int = packet.get_sender_id()
	if packet.has_id():
		_handle_id_msg(sender_id, packet.get_id())

func _handle_id_msg(_sender_id: int, id_msg: packets.IdMessage) -> void:
	var client_id: int = id_msg.get_id()
	Global.client_id = client_id
