extends Control
class_name CardNode

signal clicked(card: CardNode)
signal hovered(card: CardNode)
signal unhovered(card: CardNode)
signal selected(card: CardNode)
signal deselected(card: CardNode)
signal dragged(card: CardNode, drag_data: Dictionary)
signal drag_started(card: CardNode)
signal drag_ended(card: CardNode)
signal played(card: CardNode)
signal discarded(card: CardNode)

@export var card_size: Vector2 = Vector2(250, 350)
@export var hover_offset: Vector2 = Vector2(0, -20)

var card_data: CardDisplayData

var is_selected: bool = false
var is_dragging: bool = false
var drag_start_position: Vector2
var is_playable: bool = true
var is_discarded: bool = false

#@onready var card_view: CardView = $SubViewportContainer/SubViewport/HBoxContainer/CardView

func _ready() -> void:
	if card_data == null:
		card_data = CardDisplayData.new()
	_setup_view()
	_connect_signals()

func setup_with_data() -> void:
	#if card_view != null:
	#	card_view.setup(card_data)
	pass
	
func _setup_view() -> void:
	#card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	#card_view.mouse_entered_view.connect(_on_mouse_entered)
	#card_view.mouse_exited_view.connect(_on_mouse_exited)
	#card_view.setup(card_data)
	
	custom_minimum_size = card_size

func _connect_signals() -> void:
	#card_view.gui_input.connect(_on_gui_input)
	pass

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start_position = get_global_mouse_position()
				_drag_start_check(event)
			else:
				_drag_end_check(event)
				_click_check(event)

func _drag_start_check(_event: InputEvent) -> void:
	is_dragging = true
	drag_started.emit(self)

func _drag_end_check(_event: InputEvent) -> void:
	if is_dragging:
		var drag_end_position : Vector2 = get_global_mouse_position()
		var drag_distance : float = drag_end_position.distance_to(drag_start_position)
		
		if drag_distance > 10:
			_drag_end(drag_end_position)
		else:
			_toggle_selection()
		
		is_dragging = false

func _drag_end(_end_position: Vector2) -> void:
	var drag_data : Dictionary = {
		"card": self,
		"card_data": card_data,
		"start_position": drag_start_position
	}
	dragged.emit(self, drag_data)
	drag_ended.emit(self)

func _click_check(event: InputEvent) -> void:
	if event.pressed:
		clicked.emit(self)

func _toggle_selection() -> void:
	if is_selected:
		_deselect()
	else:
		_select()

func _select() -> void:
	is_selected = true
	#card_view.set_selected(true)
	selected.emit()

func _deselect() -> void:
	is_selected = false
	#card_view.set_selected(false)
	deselected.emit()

func _on_mouse_enter() -> void:
	hovered.emit(self)

func _on_mouse_exit() -> void:
	unhovered.emit(self)

func _process(_delta: float) -> void:
	if is_dragging:
		var target_pos : Vector2 = get_global_mouse_position() - card_size / 2
		global_position = global_position.lerp(target_pos, 0.5)
	elif is_hovered and not is_selected:
		var viewport : Viewport = get_viewport()
		if viewport:
			var viewport_center : Vector2 = viewport.get_visible_rect().size / 2
			var target_pos : Vector2 = viewport_center - card_size / 2
			global_position = global_position.lerp(target_pos + hover_offset, 0.15)

var is_hovered: bool = false:
	get:
		return true

func get_drag_data(_at_position: Vector2) -> Variant:
	if not is_playable:
		return null
	
	var data : Dictionary = {
		"card": self,
		"card_data": card_data
	}
	return data

func can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("card")

func drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("card"):
		var dropped_card: CardNode = data["card"]
		_drop_card_onto(dropped_card)

func _drop_card_onto(_other_card: CardNode) -> void:
	pass

func play() -> void:
	if not is_playable or is_discarded:
		return
	is_playable = false
	played.emit(self)
	_play_animation()

func discard() -> void:
	if is_discarded:
		return
	is_discarded = true
	discarded.emit(self)
	_discard_animation()

func _play_animation() -> void:
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "position:y", position.y - 50, 0.3)
	await tween.finished
	queue_free()

func _discard_animation() -> void:
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "rotation", PI * 0.1, 0.3)
	tween.tween_property(self, "position:y", position.y + 50, 0.3)
	await tween.finished
	queue_free()

func set_playable(playable: bool) -> void:
	is_playable = playable
	modulate = Color(0.5, 0.5, 0.5) if not playable else Color.WHITE

func set_selected_state(selected: bool) -> void:
	if selected:
		_select()
	else:
		_deselect()


func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.
