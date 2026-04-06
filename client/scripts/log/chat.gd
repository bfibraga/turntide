extends Control

signal on_submit(text: String)

const packets := preload("res://scripts/network/packets/packets.gd")

@onready var _log: Log = $FoldableContainer/VBoxContainer/Log/Log
@onready var _line_edit: LineEdit = $FoldableContainer/VBoxContainer/LineEdit

func _ready() -> void:
	WS.packet_received.connect(_on_packet_received)
	
	_line_edit.text_submitted.connect(_line_edit_text_submitted)

func _line_edit_text_submitted(new_text: String) -> void:
	self.on_submit.emit(new_text)
	
	var packet: packets.Packet = PacketFactory.new_chat_msg(new_text)
	WS.send(packet)

func _on_packet_received(packet: packets.Packet) -> void:
	if !packet.has_chat():
		return
	
	var sender_id : int = packet.get_sender_id()
	var chat_msg : packets.ChatMessage = packet.get_chat()
	var message : String = chat_msg.get_msg()
	
	Global.logger.chat("Client %d" % sender_id, message)
