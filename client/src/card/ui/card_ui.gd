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

const DEFAULT_SIZE : Vector2 = Vector2(225, 315)

@export_category("Dependencies")
@export var card_data: CardData
@export var view: CardView

var data: Data = Data.new()

var base_position: Vector2 = Vector2.ZERO
var move_tween: Tween

func _init(initial_card_data: CardData = null) -> void:
	self.setup(initial_card_data)
	
func setup(initial_card_data: CardData = null) -> void:	
	if initial_card_data:
		data.card_data.value = initial_card_data
	
	self.custom_minimum_size = DEFAULT_SIZE
	#self.size = DEFAULT_SIZE
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	
func _ready() -> void:	
	data.reactive_changed.connect(func(reactive: Data) -> void:
		view.front_art = reactive.printing.value
	)
	
	Global.printings_manager.card_printing_ready.connect(func(key: String, path: String) -> void:
		if key == data.key.value:
			_start_async_texture_load(path)
	)
	
	var info: Dictionary = Global.printings_manager.get_card_info(data.key.value)
	
	if info.status == "ready":
		_start_async_texture_load(info.path)
	else:
		Global.printings_manager.request_download(data.card_data.value)
		
	data.manually_emit()

#region Behaviour Management

func add_behavior(behavior: CardBehavior) -> Card:
	add_child(behavior)
	behavior.setup(self)
	
	return self

func clear_behaviors() -> void:
	for child: Node in get_children():
		if child is CardBehavior:
			var behaviour: CardBehavior = child as CardBehavior
			
			behaviour.teardown()
			behaviour.queue_free()

#endregion

#region Movement

class MoveConfig:
	var duration: float = 0.25
	var index: int = 0
	var stagger: float = 0.0
	var transition: Tween.TransitionType = Tween.TRANS_BACK
	var ease_type: Tween.EaseType = Tween.EASE_OUT
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
	if not target.can_accept_card(self): return
	if not config: 
		config = MoveConfig.new() 

	var old_global : Vector2 = global_position

	reparent(target)
	#global_position = old_global
	position = Vector2.ZERO
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

	base_position = target_position

	for child: Node in self.get_children():
		if child is HoverBehavior:
			var hb: HoverBehavior = child as HoverBehavior
			hb.default_rotation = target_rotation

	if move_tween:
		move_tween.kill()

	move_tween = create_tween().set_parallel(true) \
		.set_trans(config.transition) \
		.set_ease(config.ease_type)

	move_tween.tween_property(
		self,
		"position",
		target_position,
		config.duration
	)

	move_tween.tween_property(
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
	
	data.printing.value = ImageTexture.create_from_image(image)

#endregion
