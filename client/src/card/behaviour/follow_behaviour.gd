class_name FollowBehaviour extends CardBehavior

func setup(card_node: Card) -> void:
	super(card_node)
	card.view.gui_input.connect(_on_gui_input)

func teardown() -> void:
	card.view.gui_input.disconnect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		card.view.follow()
 
