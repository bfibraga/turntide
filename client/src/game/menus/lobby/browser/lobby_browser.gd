extends Control

class SearchData extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveObject = ReactiveObject.new(null, self)

class PageData extends Reactive:
	var page: ReactiveValue = ReactiveValue.Int(1, self)
	var page_size: ReactiveValue = ReactiveValue.Int(20, self)

class CreateData extends Reactive:
	var name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveObject = ReactiveObject.new(StandardFormat.new(), self)
	var max_players: ReactiveValue = ReactiveValue.Int(1, self)
	var is_private: ReactiveValue = ReactiveValue.Boolean(false, self)
	var password: ReactiveValue = ReactiveValue.String("", self)

const LobbyItemScene: PackedScene = preload("res://src/common/components/lobby/item/lobby_item.tscn")
const packets := preload("res://src/common/network/packets/packets.gd")

var search_data: SearchData = SearchData.new()
var page_data: PageData = PageData.new()
var create_data: CreateData = CreateData.new()

var format_options: Control

@onready var search_options: VBoxContainer = %SearchOptions
@onready var refresh_button: Button = %Refresh
@onready var lobby_search_line_edit: SearchLineEdit = %Lobby
@onready var count_label: Label = %Count

@onready var create_options: VBoxContainer = %CreateOptions
@onready var create_name: LineEdit = %CreateName
@onready var max_players: SpinBox = %"Max Players"
@onready var private: CheckBox = %Private
@onready var create_button: Button = $%Create

@onready var lobby_list: Control = $%LobbyList
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

func _ready() -> void:
	search_data.reactive_changed.connect(func(reactive: SearchData) -> void:
		cleanup_list()

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
	lobby_search_line_edit.execute_search_empty_query.connect(func() -> void:
		search_data.lobby_name.value = ""
	)
	
	var search_format_options : Control = NodeFactory.create_format_dropdown(
		Option.Some("Format"),
		func(index: int, formats: Array[BaseFormat]) -> void:
			search_data.format.value = formats.get(index - 1) if index > 0 else null,
		Global.deck_format_manager.formats
	)
	search_options.add_child(search_format_options)
	search_options.move_child(search_format_options, 1)
	
	
	create_name.text_changed.connect(func(text: String) -> void:
		create_data.name.value = text
	)
	
	var create_format_options : Control = NodeFactory.create_format_dropdown(
		Option.Some("Format"),
		func(index: int, formats: Array[BaseFormat]) -> void:
			create_data.format.value = formats.get(index),
		Global.deck_format_manager.formats,
		false
	)
	create_options.add_child(create_format_options)
	create_options.move_child(create_format_options, 1)

	max_players.value_changed.connect(func(value: float) -> void:
		create_data.max_players.value = int(value)
	)
	
	private.toggled.connect(func(toggled_on: bool) -> void:
		create_data.is_private.value = toggled_on
	)
	
	page_data.manually_emit()
	
func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_list_lobbies_response():
		_handle_lobby_list(packet.get_list_lobbies_response())
	#elif packet.has_create_lobby_response():
		#_handle_create_lobby(packet)
	elif packet.has_joined_lobby_response():
		_handle_player_joined_lobby(packet.get_joined_lobby_response())
		
	#elif packet.has_lobby_joined_response():
		#_handle_lobby_joined_response(packet.get_lobby_joined_response())
		
func _handle_lobby_list(response: packets.ListLobbiesResponse) -> void:
	#Global.logger.info("Received lobby list %s" % response)
	
	var count: int = response.get_count()
	count_label.text = "Loaded %d" % count
	
	var lobbies: Array[packets.LobbyData] = response.get_lobbies()
	for lobby: packets.LobbyData in lobbies:
		var item: LobbyItem = LobbyItemScene.instantiate()
		item.setup(lobby)
		
		item.join_button.pressed.connect(func() -> void: join_lobby(lobby.get_id()))
		
		lobby_list.add_child(item)

func _handle_create_lobby() -> void:
	search_data.manually_emit()

func _handle_player_joined_lobby(response: packets.JoinedLobbyResponse) -> void:
	var lobby: Dictionary = {
		"lobby_id": response.get_lobby_id(),
		"lobby_name": response.get_lobby_name(),
		"hostname": response.get_host_username(),
		"players": response.get_players(),
	}
	
	Global.game_controller.gui_transition_to(InLobbyState.Name(), lobby)

#func _handle_lobby_joined_response(response: packets.ListLobbiesResponse) -> void:
	#Global.logger.info("Joined in lobby")
	#
	#var lobby_data: Dictionary = {
		#var lobby_data: Dictionary = {
		#"lobby_id": response.get_lobby_id(),
		#"lobby_name": response.get_lobby_name(),
		#"hostname": response.get_host_username(),
		#"players": response.get_players(),
	#}
	#}
	#
	#Global.game_controller.gui_transition_to(InLobbyState.Name(), lobby_data)
	
func _on_create_button_pressed() -> void:
	var packet: packets.Packet = PacketFactory.new_create_lobby_request(
		create_data.name.value, 
		create_data.format.value, 
		create_data.is_private.value
	)
	
	WS.send(packet)

func _on_refresh_button_pressed() -> void:
	page_data.page.value = 1
	search_data.manually_emit()

func cleanup_list() -> void:
	for child: Node in lobby_list.get_children():
		child.queue_free()

func send_list_lobbies_request(
	name: String, format: BaseFormat, state: int,
	page: int = 1, page_size: int = 10) -> void:
	var packet: packets.Packet = PacketFactory.new_list_lobbies_request(
		Option.new(name), Option.new(format.display_name() if format else null), Option.new(state),
		page, page_size
	)
	
	print(packet)
	WS.send(packet)

func join_lobby(lobby_id: int) -> void:
	#Global.logger.info("Joining lobby %d" % lobby_id)
	
	var packet: packets.Packet = PacketFactory.new_join_lobby_request(lobby_id, Option.None())
	WS.send(packet)
	
