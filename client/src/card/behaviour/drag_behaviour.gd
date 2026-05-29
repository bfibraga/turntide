class_name DragBehavior extends CardBehavior

signal drag_started(card: Card)
signal drag_ended(card: Card)

@export var drag_speed: float = 5.0
@export var drag_z_index: int = 0
@export var card_container_manager: CardContainerManager

var is_dragging: bool = false
var _original_container: CardContainer
var _original_position: Vector2 = Vector2.ZERO

func _init(p_card_container_manager: CardContainerManager = null) -> void:
	card_container_manager = p_card_container_manager

func setup(card_node: Card) -> void:
	super(card_node)
	card.view.gui_input.connect(_on_gui_input)

func teardown() -> void:
	card.view.gui_input.disconnect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var me: InputEventMouseButton = event as InputEventMouseButton
		if me.button_index == MOUSE_BUTTON_LEFT:
			if me.pressed:
				_start_drag()
			elif is_dragging:
				_end_drag()

func _process(_delta: float) -> void:
	if is_dragging:
		card.global_position = card.get_global_mouse_position() - _drag_offset

var _drag_offset: Vector2 = Vector2.ZERO

func _start_drag() -> void:
	if is_dragging: return
	
	is_dragging = true

	_original_container = card.get_parent()
	_original_position = card.position
	card.z_index = drag_z_index
	
	if card.move_tween:
		card.move_tween.kill()
	
	# Suppress hover
	for child: Node in card.get_children():
		if child is HoverBehavior:
			var hb: HoverBehavior = child as HoverBehavior
			hb.suppress()
		elif child is TooltipBehaviour:
			var tb: TooltipBehaviour = child as TooltipBehaviour
			tb.suppress()
	
	_drag_offset = card.get_global_mouse_position() - card.global_position
	drag_started.emit(card)

func _end_drag() -> void:
	is_dragging = false

	card.z_index = 0
	var target: CardContainer = card_container_manager.find_nearest(
		card.get_global_mouse_position(), card
	)
	if target:
		card.move_to(target, Card.MoveConfig.new({"duration": 0.2, "stagger": 0.03}))
	else:
		card.move_to_position(_original_position, card.rotation)
	drag_ended.emit(card)
