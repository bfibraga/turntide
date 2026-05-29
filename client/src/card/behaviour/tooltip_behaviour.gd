class_name TooltipBehaviour extends CardBehavior

@export var hover_delay: float = 0.75
@export var tooltip_offset: Vector2 = Vector2(Card.DEFAULT_SIZE.x + 10, 0)
@export var fade_duration: float = 0.15
@export var slide_offset: float = 20.0
@export var tooltip_z_index: int = 4

var _tooltip: CardTooltip
var _hover_timer: SceneTreeTimer
var _tooltip_scroll: ScrollContainer
var _scroll_tween: Tween
var _fade_tween: Tween

@onready var tooltip_scene: PackedScene = preload("res://src/card/ui/tooltip/card_tooltip.tscn")

func setup(card_node: Card) -> void:
	super(card_node)
	card.view.on_mouse_enter.connect(_on_mouse_enter)
	card.view.on_mouse_exit.connect(_on_mouse_exit)
	card.view.gui_input.connect(_on_gui_input) 

func teardown() -> void:
	card.view.on_mouse_enter.disconnect(_on_mouse_enter)
	card.view.on_mouse_exit.disconnect(_on_mouse_exit)
	card.view.gui_input.disconnect(_on_gui_input) 
	_hide_tooltip()

func _on_mouse_enter() -> void:
	print("FollowBehaviour: on mouse enter")
	_start_timer()

func _on_mouse_exit() -> void:
	_cancel_timer()
	_hide_tooltip()

func _on_gui_input(event: InputEvent) -> void:
	if not _tooltip_scroll: return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_animate_scroll(-int(mb.factor * 60))
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_animate_scroll(int(mb.factor * 60))

func _start_timer() -> void:
	_cancel_timer()
	_hover_timer = get_tree().create_timer(hover_delay)
	_hover_timer.timeout.connect(_on_timer_expired)

func _cancel_timer() -> void:
	if _hover_timer:
		_hover_timer.timeout.disconnect(_on_timer_expired)
		_hover_timer = null

func _animate_scroll(delta: int) -> void:
	if _scroll_tween:
		_scroll_tween.kill()
		
	var max_val: float = _tooltip_scroll.get_v_scroll_bar().max_value
	var target: float = clamp(_tooltip_scroll.scroll_vertical + delta, 0, max_val)
	_scroll_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_scroll_tween.tween_property(_tooltip_scroll, "scroll_vertical", target, 0.2)

func _on_timer_expired() -> void:
	_show_tooltip()

func _show_tooltip() -> void:
	if _tooltip: return
	if not tooltip_scene: return
	
	var keyword_names: PackedStringArray = card.data.card_data.value.keywords.split(",", false)
	if keyword_names.is_empty():
		return
	
	_tooltip = tooltip_scene.instantiate()
	_tooltip_scroll = _tooltip.find_child("ScrollContainer", true, false) as ScrollContainer
	
	for keyword_name: String in keyword_names:
		var trimmed: String = keyword_name.strip_edges()
		var result: Result = Global.keywords_repository.find(trimmed)
		
		if result.is_ok():
			var data: Dictionary = result.unwrap()
			var kw: CardTooltip.Keyword = CardTooltip.Keyword.new()
			
			kw.title = data.name
			kw.description = data.description
			
			_tooltip.data.keywords.add(kw)
	
	_tooltip.modulate = Color(1, 1, 1, 0)
	_tooltip.z_index = tooltip_z_index

	_fade_tween = create_tween().set_parallel()
	_fade_tween.tween_property(_tooltip, "modulate", Color.WHITE, fade_duration)
	_fade_tween.tween_property(_tooltip, "position", tooltip_offset, fade_duration)
	_fade_tween.set_trans(Tween.TRANS_CUBIC)
	_fade_tween.set_ease(Tween.EASE_OUT)
	
	card.add_child(_tooltip)
	_tooltip.position = tooltip_offset

func _hide_tooltip() -> void:
	#_fade_tween = create_tween().set_parallel()
	#_fade_tween.tween_property(_tooltip, "modulate", Color(1,1,1,0), fade_duration * 0.7)
	#_fade_tween.tween_property(_tooltip, "position", tooltip_offset + Vector2(slide_offset, 0), fade_duration * 0.7)
	#_fade_tween.set_trans(Tween.TRANS_CUBIC)
	#_fade_tween.set_ease(Tween.EASE_IN)
	#
	_tooltip_scroll = null
	if _tooltip:
		_tooltip.queue_free()
		_tooltip = null

	#_fade_tween.finished.connect(_cleanup_tooltip, CONNECT_ONE_SHOT)

func _cleanup_tooltip() -> void:
	_fade_tween = null

func suppress() -> void:
	_hide_tooltip()
