extends Control

class SearchData extends Reactive:
	var lobby_name: ReactiveValue = ReactiveValue.String("", self)
	var format: ReactiveObject = ReactiveObject.new(null, self)
	

const LobbyItemScene: PackedScene = preload("res://src/common/components/lobby/item/lobby_item.tscn")
const packets := preload("res://src/common/network/packets/packets.gd")

@onready var logger: Log = Global.logger
@onready var create_button: Button = $%Create
@onready var lobby_list: Control = $%LobbyList
@onready var extensible_scroll_container: ExtensibleScrollContainer = %ExtensibleScrollContainer

func _ready() -> void:
	WS.packet_received.connect(_on_ws_packet_received)
	
	create_button.pressed.connect(_on_create_button_pressed)
	extensible_scroll_container.vertical_threshold_reached.connect(func() -> void: print("Reached vertical threshold"))
	extensible_scroll_container.horizontal_threshold_reached.connect(func() -> void: print("Reached horizontal threshold"))
	
	var packet: packets.Packet = PacketFactory.new_lobby_list_req()
	WS.send(packet)
	
func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_lobby_list_response():
		_handle_lobby_list(packet.get_lobby_list_response())
	elif packet.has_lobby_joined_response():
		logger.info("Joined in lobby")
		#transition_requested.emit(InLobbyState.Name())
		Global.game_controller.gui_transition_to(InLobbyState.Name())
		
func _handle_lobby_list(response: packets.LobbyListResponse) -> void:
	logger.info("Received lobby list %s" % response)
	# TODO: populate UI with response.get_lobbies()
	var lobbies: Array[packets.LobbyInfo] = response.get_lobbies()
	
	# Clear existing list
	for child: Node in lobby_list.get_children():
		child.queue_free()

	for lobby: packets.LobbyInfo in lobbies:
		#var hbox: HBoxContainer = HBoxContainer.new()
		#var label: Label = Label.new()
		#label.text = "%s (%d/%d) - %s" % [lobby.get_name(), lobby.get_current_players(), lobby.get_max_players(), lobby.get_host_username()]
		#hbox.add_child(label)
#
		#var join_btn: Button = Button.new()
		#join_btn.text = "Join (pw)" if lobby.get_is_private() else "Join"
		#join_btn.pressed.connect(func() -> void: _on_join_pressed(lobby.get_id()))
		#hbox.add_child(join_btn)

		var item: LobbyItem = LobbyItemScene.instantiate()
		item.data.lobby_name.value = lobby.get_name()
		item.data.format.value = lobby.get_format()
		item.data.is_private.value = lobby.get_is_private()
		item.data.capacity.value = lobby.get_current_players()
		item.data.max_capacity.value = lobby.get_max_players()
		
		item.join_button.pressed.connect(func() -> void: _on_join_pressed(lobby.get_id()))
		
		lobby_list.add_child(item)
		
func _on_create_button_pressed() -> void:
	var packet: packets.Packet = PacketFactory.new_lobby_create_req(
		"Host name",
		"Commander",
		4,
		false,
		""
	)
	
	WS.send(packet)

func _on_join_pressed(lobby_id: int) -> void:
	logger.info("Joining lobby %d" % lobby_id)
	var packet: packets.Packet = PacketFactory.new_lobby_join_req(lobby_id)
	WS.send(packet)
	
	
