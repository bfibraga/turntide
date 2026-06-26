extends Control

class SearchData extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveObject = ReactiveObject.new(null, self)
	

class PageData extends Reactive:
	var page: ReactiveValue = ReactiveValue.Int(1, self)
	var page_size: ReactiveValue = ReactiveValue.Int(20, self)

const LobbyItemScene: PackedScene = preload("res://src/common/components/lobby/item/lobby_item.tscn")
const packets := preload("res://src/common/network/packets/packets.gd")

var page_data: PageData = PageData.new()

@onready var create_button: Button = $%Create
@onready var refresh_button: Button = %Refresh

@onready var lobby_list: Control = $%LobbyList
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

func _ready() -> void:
	page_data.reactive_changed.connect(func(reactive: PageData) -> void:
		send_list_lobbies_request(reactive.page.value, reactive.page_size.value)
	)
	
	WS.packet_received.connect(_on_ws_packet_received)
	
	create_button.pressed.connect(_on_create_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	extensible_scroll_container.vertical_threshold_reached.connect(func() -> void: page_data.page.value += 1)
	
	page_data.manually_emit()
	
func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_list_lobbies_response():
		_handle_lobby_list(packet.get_list_lobbies_response())
	#elif packet.has_lobby_joined_response():
		#_handle_lobby_joined_response(packet.get_lobby_joined_response())
		
func _handle_lobby_list(response: packets.ListLobbiesResponse) -> void:
	Global.logger.info("Received lobby list %s" % response)
	var lobbies: Array[packets.LobbyData] = response.get_lobbies()

	for lobby: packets.LobbyData in lobbies:
		var item: LobbyItem = LobbyItemScene.instantiate()
		item.setup(lobby)
		
		item.join_button.pressed.connect(func() -> void: join_lobby(lobby.get_id()))
		
		lobby_list.add_child(item)

#func _handle_lobby_joined_response(response: packets.ListLobbiesResponse) -> void:
	#Global.logger.info("Joined in lobby")
	#
	#var lobby_data: Dictionary = {
		#"lobby_id": response.get_lobby_id(),
		#"lobby_name": response.get_lobby_name(),
		#"hostname": response.get_host_username(),
		#"players": response.get_players(),
	#}
	#
	#Global.game_controller.gui_transition_to(InLobbyState.Name(), lobby_data)
	
func _on_create_button_pressed() -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_create_req(
		"Host name",
		StandardFormat.display_name(),
		4,
		false,
		""
	)
	
	WS.send(packet)

func _on_refresh_button_pressed() -> void:
	# Clear existing list
	for child: Node in lobby_list.get_children():
		child.queue_free()
	
	page_data.page.value = 1

func send_list_lobbies_request(page: int = 1, page_size: int = 10) -> void:
	var packet: packets.Packet = PacketFactory.new_list_lobbies_request(page, page_size)
	WS.send(packet)

func join_lobby(lobby_id: int) -> void:
	Global.logger.info("Joining lobby %d" % lobby_id)
	
	#var packet: packets.Packet = PacketFactory.new_lobby_join_req(lobby_id)
	#WS.send(packet)
	
