@tool @icon("res://addons/icodot/ui/hands/icon-hand-stop-ui.svg")
class_name Hand extends CardContainer

@export_category("Spacing")
@export var width_curve: Curve
@export var height_curve: Curve
@export_range(0, 1000, 5) var x_sep: float = Card.DEFAULT_SIZE.x / 2
@export_range(0, 1000, 5) var y_influence: float = 10
@export_range(-1000, 1000, 5) var y_offset: float = - (size.y - Card.DEFAULT_SIZE.y / 4) 

@export_category("Rotation")
@export var rotation_curve: Curve
@export_range(0, 30) var max_rotation_angle: float = 15

func _ready() -> void:
	clip_contents = false
	card_behaviours = [
		FollowBehaviour.new(),
		HoverBehavior.new(),
		DragBehavior.new(self.card_container_manager),
		TooltipBehaviour.new(),
	]
	
	super._ready()

func organize_cards(config: Card.MoveConfig = null) -> void:
	var hand_size: int = get_child_count()

	var final_x_sep : float = x_sep

	if hand_size == 0:
		return
	elif hand_size > 1:
		var required_width: float = Card.DEFAULT_SIZE.x + x_sep * (hand_size - 1)
		
		if required_width > size.x:
			final_x_sep = (size.x - Card.DEFAULT_SIZE.x) / (hand_size - 1)

	var spread_width: float = final_x_sep * max(hand_size - 1, 0)
	var center_x: float = size.x * 0.5

	for card: Card in self.get_children():
		var i: int = card.get_index()

		var ratio : float = 0.5
		if hand_size > 1:
			ratio = float(i) / float(hand_size - 1)

		var x: float = center_x + (i * final_x_sep) - spread_width * 0.5 - (Card.DEFAULT_SIZE.x / 2)
		var y: float = -height_curve.sample(ratio) * y_influence - y_offset

		var angle: float = 0.0
		if rotation_curve:
			angle = (
				rotation_curve.sample(ratio)
				* max_rotation_angle
			)
		
		card.move_to_position(
			Vector2(x, y),
			angle,
			config
		)
