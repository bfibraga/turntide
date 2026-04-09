class_name MouseTracker
extends Node

signal mouse_position_changed(normalized_pos: Vector2)

@export var threshold_px: float = 5.0
@export var viewport: Viewport

var _last_sent_raw_position: Vector2 = Vector2.ZERO
var _initialized: bool = false

func _ready() -> void:
	if viewport == null:
		viewport = get_viewport()

func _process(_delta: float) -> void:
	if viewport == null:
		return
	
	var raw_mouse := viewport.get_mouse_position()
	
	if not _initialized:
		_last_sent_raw_position = raw_mouse
		_initialized = true
		return
	
	var delta := raw_mouse - _last_sent_raw_position
	if delta.length() > threshold_px:
		_last_sent_raw_position = raw_mouse
		_emit_normalized(raw_mouse)

func _emit_normalized(raw_pos: Vector2) -> void:
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x == 0 or viewport_size.y == 0:
		return
	
	var normalized := Vector2(
		raw_pos.x / viewport_size.x,
		raw_pos.y / viewport_size.y
	)
	mouse_position_changed.emit(normalized)

func get_last_normalized() -> Vector2:
	if viewport == null:
		return Vector2.ZERO
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size.x == 0 or viewport_size.y == 0:
		return Vector2.ZERO
	return Vector2(
		_last_sent_raw_position.x / viewport_size.x,
		_last_sent_raw_position.y / viewport_size.y
	)
