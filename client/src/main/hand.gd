@tool @icon("res://addons/icodot/ui/hands/icon-hand-stop-ui.svg")
class_name Hand extends CardContainer

signal hand_action(type: String)

@export_category("Spacing")
@export var width_curve: Curve
@export var height_curve: Curve
@export_range(0, 1000, 5) var x_sep: float = Card.DEFAULT_SIZE.x / 2
@export_range(0, 1000, 5) var y_influence: float = 10
@export_range(-1000, 1000, 5) var y_offset: float = - (size.y - Card.DEFAULT_SIZE.y / 4) 

@export_category("Rotation")
@export var rotation_curve: Curve
@export_range(0, 30) var max_rotation_angle: float = 15

var _deck: Array[CardData] = []
var _hovered_card: Card

func _ready() -> void:
	Global.card_repository = RepositoryFactory.new_card_repository()
	Global.deck_repository = RepositoryFactory.new_deck_repository()
	
	var decks: Array[DeckData] = Global.deck_repository.list_decks()
	if decks.size() == 0:
		return
	
	_deck = decks.reduce(func(accum: DeckData, deck: DeckData) -> DeckData:
		return accum if accum.mainboard.size() > deck.mainboard.size() else deck
	, decks[0]).mainboard.keys()
	
	clip_contents = false

func draw(card_data: CardData = _deck.pick_random()) -> void:
	var new_card: Card = CardFactory.create_card(card_data)
	new_card.pivot_offset = Card.DEFAULT_SIZE / 2
	
	new_card.view.on_mouse_enter.connect(func() -> void:
		_hovered_card = new_card
		print("Hovering: ", _hovered_card)
	)
	new_card.hover_y_offset = -Card.DEFAULT_SIZE.y + size.y / 2
	
	add_child(new_card)
	organize_cards()

func discard() -> void:
	if get_child_count() < 1:
		return
	
	var child: Node = get_child(-1)
	child.reparent(get_tree().root)
	child.queue_free()
	organize_cards()

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

	for card: Card in get_children():
		if card.is_dragging:
			continue
		
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
		
		card.default_rotation = angle

		card.move_to_position(
			Vector2(x, y),
			angle,
			config
		)
