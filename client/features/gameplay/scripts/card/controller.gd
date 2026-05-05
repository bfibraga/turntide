class_name CardController extends Node

signal input_event(event: InputEvent)
signal drag_started
signal drag_ended
signal clicked

const DRAG_DISTANCE_THRESHOLD: float = 10.0

var drag_start_position: Vector2
var is_dragging: bool = false

func _on_gui_input(event: InputEvent) -> void:
	input_event.emit(event)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			drag_start_position = event.position
			is_dragging = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var drag_distance = calculate_drag_distance(drag_start_position, event.position)
			if drag_distance > DRAG_DISTANCE_THRESHOLD:
				drag_ended.emit()
			else:
				clicked.emit()
			is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		var drag_distance = calculate_drag_distance(drag_start_position, event.position)
		if drag_distance > DRAG_DISTANCE_THRESHOLD:
			drag_started.emit()

func calculate_drag_distance(start: Vector2, end: Vector2) -> float:
	return start.distance_to(end)