@tool @icon("res://addons/icodot/ui/games/icon-card-back-dark-ui.svg")
class_name Card extends BaseButton

#region Inner Classes

## Inner data class to store important card data (e.g [card_data], [printing])
class Data extends Reactive:
	var card_data: ReactiveValue = ReactiveValue.new(
		CardData.new(),
		self
	)
	var key: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> String: 
			var data: CardData = card_data.value
			return Global.printings_manager._make_key(
				data.uuid,
				data.setCode, 
				data.number,
			),
		[card_data],
		self
	)
	var printing: ReactiveObject = ReactiveObject.new(
		preload("res://assets/card/back/back_card.png"),
		self
	)

#endregion

#region Signals

signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)

#endregion

const DEFAULT_SIZE : Vector2 = Vector2(225, 315)

@export_category("Dependencies")
@export var card_data: CardData
@export var view: CardView

@export_category("Hover")
@export var hover_y_offset: float = -Card.DEFAULT_SIZE.y
@export var hover_duration: float = 0.15
@export var default_z_index: int = 0
@export var hover_z_index: int = 10
@export var default_rotation: float = 0
@export var hover_rotation: float = 0

@export_category("Drag")
@export var drag_offset: Vector2 = Vector2.ZERO
@export var drag_speed: float = 5.0
@export var drag_z_index: float = self.default_z_index

var _data: Data = Data.new()

var _base_position: Vector2 = Vector2.ZERO
var _move_tween: Tween

var _hover_tween: Tween
var _hovered: bool = false

var is_dragging: bool = false
var _original_container: CardContainer
var _original_position: Vector2 = Vector2.ZERO

func _init(initial_card_data: CardData = null) -> void:
	self.setup(initial_card_data)
	
func setup(initial_card_data: CardData = null) -> void:
	#if Engine.is_editor_hint(): return
	
	if initial_card_data:
		_data.card_data.value = initial_card_data
	
	self.size = DEFAULT_SIZE
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.z_index = default_z_index
	
func _ready() -> void:	
	_data.reactive_changed.connect(func(reactive: Data) -> void:
		view.front_art = reactive.printing.value
	)
	
	Global.printings_manager.card_printing_ready.connect(func(key: String, path: String) -> void:
		if key == _data.key.value:
			_start_async_texture_load(path)
	)
	view.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			view.follow()
		
		if event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				if mouse_event.pressed:
					_start_drag()
				elif is_dragging:
					_end_drag() 
	)
	view.on_mouse_enter.connect(func() -> void:
		_hovered = true
		z_index = hover_z_index
		
		_update_hover()
	)
	view.on_mouse_exit.connect(func() -> void:
		_hovered = false
		z_index = default_z_index
		
		_update_hover()
	)
	
	#view.tap_card.connect(func() -> void: print("Tapping"))
	#view.flip_card.connect(func() -> void: print("Flipping"))
	
	#button_down.connect(_on_button_down)
	#button_up.connect(_on_button_up)
	
	var info: Dictionary = Global.printings_manager.get_card_info(_data.key.value)
	
	if info.status == "ready":
		_start_async_texture_load(info.path)
	else:
		Global.printings_manager.request_download(_data.card_data.value)
			
		
	_data.manually_emit()

func _process(delta: float) -> void:
	if is_dragging:
		#global_position = lerp(global_position, get_global_mouse_position() - drag_offset, delta * drag_speed)
		global_position = get_global_mouse_position() - drag_offset

#region Hover

func _update_hover() -> void:
	if _hover_tween:
		_hover_tween.kill()

	var target_position: Vector2 = _base_position
	var target_rotation: float = default_rotation

	if _hovered:
		target_position.y += hover_y_offset
		target_rotation = hover_rotation

	_hover_tween = create_tween().set_parallel() \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)

	_hover_tween.tween_property(
		self,
		"position",
		target_position,
		hover_duration
	)
	
	_hover_tween.tween_property(
		self,
		"rotation",
		target_rotation,
		hover_duration
	)

#endregion

#region Drag

func _start_drag() -> void:
	if is_dragging:
		return

	is_dragging = true

	_original_container = get_parent()
	_original_position = position

	z_index = drag_z_index

	if _move_tween:
		_move_tween.kill()

	if _hover_tween:
		_hover_tween.kill()

	drag_offset = (
		get_global_mouse_position()
		- global_position
	)

	card_drag_started.emit(self)


func _end_drag() -> void:
	is_dragging = false

	z_index = 0

	var target := CardContainer.new() # TODO: implement find nearest card container

	if target:
		move_to(
			target,
			MoveConfig.new({
				"duration":0.2,
				"stagger":0.03
			})
		)
	else:
		move_to_position(
			_original_position,
			rotation
		)

	card_drag_ended.emit(self)

#endregion

#region Movement

class MoveConfig:
	var duration: float = 0.25
	var index: int = 0
	var stagger: float = 0.0
	var transition: Tween.TransitionType = Tween.TRANS_BACK
	var ease: Tween.EaseType = Tween.EASE_OUT
	var position_callable: Callable

	func _init(parameters: Dictionary = {}) -> void:
		for property: Dictionary in get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var property_name: String = property.name

				if parameters.has(property_name):
					set(property_name, parameters[property_name])

	func get_delay() -> float:
		return index * stagger

func move_to(target: CardContainer, config: MoveConfig = null) -> void:
	if not target: return
	#if not target.can_accept_card(self): return
	if not config: 
		config = MoveConfig.new() 

	var old_global : Vector2 = global_position
	reparent(target)
	
	global_position = old_global
	target.organize_cards()
	
func move_to_position(
	target_position: Vector2,
	target_rotation : float = 0.0,
	config: MoveConfig = null
) -> void:
	if not config:
		config = MoveConfig.new()

	if config.position_callable.is_valid():
		target_position = config.position_callable.call(
			target_position
		)

	_base_position = target_position

	if _hovered:
		target_position.y += hover_y_offset

	if _move_tween:
		_move_tween.kill()

	_move_tween = create_tween().set_parallel(true) \
		.set_trans(config.transition) \
		.set_ease(config.ease)

	_move_tween.tween_property(
		self,
		"position",
		target_position,
		config.duration
	)

	_move_tween.tween_property(
		self,
		"rotation",
		target_rotation,
		config.duration
	)

#endregion

#region Printing Management

func _start_async_texture_load(path: String) -> void:
	# Even if it's on disk, Image.load_from_file is slow. Do it in a worker.
	WorkerThreadPool.add_task(func() -> void: 
		if not FileAccess.file_exists(path):
			push_error("Image file does not exist: ", path)
			return

		set_printing.call_deferred(path)
	)

func set_printing(printing_path: String) -> void:
	if printing_path.strip_edges().is_empty():
		push_warning("Setting empty printing path to card node ", self.name)
		return
	
	var image : Image = Image.new()
	var err : int = image.load(printing_path)
	if err != OK:
		push_error("Failed to load card image: ", printing_path, " error: ", err )
		return
	
	_data.printing.value = ImageTexture.create_from_image(image)

#endregion
