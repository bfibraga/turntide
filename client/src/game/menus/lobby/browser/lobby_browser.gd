extends Control

class SearchData extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveObject = ReactiveObject.new(null, self)

class PageData extends Reactive:
	var page: ReactiveValue = ReactiveValue.Int(1, self)
	var page_size: ReactiveValue = ReactiveValue.Int(20, self)

const LobbyItemScene: PackedScene = preload("res://src/common/components/lobby/item/lobby_item.tscn")
const packets := preload("res://src/common/network/packets/packets.gd")

var search_data: SearchData = SearchData.new()
var page_data: PageData = PageData.new()

@onready var create_button: Button = $%Create
@onready var refresh_button: Button = %Refresh

@onready var lobby_search_line_edit: SearchLineEdit = %Lobby
@onready var format_option: OptionButton = %Format

@onready var lobby_list: Control = $%LobbyList
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

func _ready() -> void:
	search_data.reactive_changed.connect(func(reactive: SearchData) -> void:
		send_list_lobbies_request(
			reactive.lobby_name.value,
			reactive.format.value,
			0,
			page_data.page.value, page_data.page_size.value
		)
	)
	
	page_data.reactive_changed.connect(func(reactive: PageData) -> void:
		send_list_lobbies_request(
			search_data.lobby_name.value,
			search_data.format.value,
			0,
			reactive.page.value, reactive.page_size.value
		)
	)
	
	WS.packet_received.connect(_on_ws_packet_received)
	
	create_button.pressed.connect(_on_create_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	extensible_scroll_container.vertical_threshold_reached.connect(func() -> void: page_data.page.value += 1)
	
	lobby_search_line_edit.executed_search.connect(func(lobby_name: String) -> void:
		search_data.lobby_name.value = lobby_name
	)
	format_option.item_selected.connect(func(index: int) -> void:
		search_data.format.value = Global.deck_format_manager.formats.get(index - 1) if index > 0 else null
	)
	
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

func send_list_lobbies_request(
	name: String, format: BaseFormat, state: int,
	page: int = 1, page_size: int = 10) -> void:
	var packet: packets.Packet = PacketFactory.new_list_lobbies_request(
		Option.new(name), Option.new(format.display_name() if format else null), Option.new(state),
		page, page_size
	)
	WS.send(packet)

func join_lobby(lobby_id: int) -> void:
	Global.logger.info("Joining lobby %d" % lobby_id)
	
	#var packet: packets.Packet = PacketFactory.new_lobby_join_req(lobby_id)
	#WS.send(packet)
	
