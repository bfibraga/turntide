extends GutTest

var controller: CardController
var _click_count: int = 0
var _drag_start_count: int = 0
var _drag_end_count: int = 0

func before_each() -> void:
	controller = CardController.new()
	add_child(controller)

func after_each() -> void:
	controller.free()

func test_controller_detects_mouse_click() -> void:
	_click_count = 0
	controller.clicked.connect(_on_clicked)
	
	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.pressed = true
	mouse_event.position = Vector2(100, 100)
	controller._on_gui_input(mouse_event)
	
	mouse_event.pressed = false
	mouse_event.position = Vector2(100, 100)
	controller._on_gui_input(mouse_event)
	
	assert_eq(_click_count, 1, "Click should be detected when mouse releases within threshold")

func _on_clicked() -> void:
	_click_count += 1

func test_controller_differentiates_drag() -> void:
	_drag_start_count = 0
	_drag_end_count = 0
	_click_count = 0
	
	controller.drag_started.connect(_on_drag_started)
	controller.drag_ended.connect(_on_drag_ended)
	controller.clicked.connect(_on_clicked)
	
	var mouse_down = InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(100, 100)
	controller._on_gui_input(mouse_down)
	
	var mouse_motion = InputEventMouseMotion.new()
	mouse_motion.position = Vector2(200, 200)
	controller._on_gui_input(mouse_motion)
	
	var mouse_up = InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	mouse_up.position = Vector2(200, 200)
	controller._on_gui_input(mouse_up)
	
	assert_eq(_drag_start_count, 1, "Drag start should be emitted when moving beyond threshold")
	assert_eq(_drag_end_count, 1, "Drag end should be emitted on release after drag")
	assert_eq(_click_count, 0, "Click should NOT emit when drag occurred")

func _on_drag_started() -> void:
	_drag_start_count += 1

func _on_drag_ended() -> void:
	_drag_end_count += 1

func test_controller_click_vs_drag_threshold() -> void:
	_click_count = 0
	_drag_end_count = 0
	
	controller.clicked.connect(_on_clicked)
	controller.drag_ended.connect(_on_drag_ended)
	
	var mouse_down = InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(100, 100)
	controller._on_gui_input(mouse_down)
	
	var mouse_up = InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	mouse_up.position = Vector2(105, 100)
	controller._on_gui_input(mouse_up)
	
	assert_eq(_click_count, 1, "Click should emit when drag distance is below threshold")
	assert_eq(_drag_end_count, 0, "Drag end should NOT emit when below threshold")

func test_calculate_drag_distance() -> void:
	var distance = controller.calculate_drag_distance(Vector2(0, 0), Vector2(3, 4))
	assert_eq(distance, 5.0, "Distance should be calculated correctly using distance_to")