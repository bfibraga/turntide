class_name ExtensibleScrollContainer extends ScrollContainer

signal horizontal_threshold_reached
signal vertical_threshold_reached

@export_category("Thresholds")
@export_range(0, 1) var horizontal_threshold: float = 0.8
@export_range(0, 1) var vertical_threshold: float = 0.8

# Tracking states to prevent signal spamming
var _v_reached: bool = false
var _h_reached: bool = false

func _ready() -> void:
	# Connect to the scrollbars' value_changed signals
	get_v_scroll_bar().value_changed.connect(_on_v_scroll_changed)
	get_h_scroll_bar().value_changed.connect(_on_h_scroll_changed)

func _on_v_scroll_changed(value: float) -> void:
	var scrollbar: ScrollBar = get_v_scroll_bar()
	var max_val: float = scrollbar.max_value - scrollbar.page
	
	if max_val <= 0: return # Content fits, no scrolling needed
	
	var ratio: float = value / max_val
	
	if ratio >= vertical_threshold:
		if not _v_reached:
			_v_reached = true
			vertical_threshold_reached.emit()
	else:
		_v_reached = false

func _on_h_scroll_changed(value: float) -> void:
	var scrollbar: ScrollBar = get_h_scroll_bar()
	var max_val: float = scrollbar.max_value - scrollbar.page
	
	if max_val <= 0: return
	
	var ratio: float = value / max_val
	
	if ratio >= horizontal_threshold:
		if not _h_reached:
			_h_reached = true
			horizontal_threshold_reached.emit()
	else:
		_h_reached = false
