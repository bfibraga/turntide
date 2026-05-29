class_name ClickBehavior extends CardBehavior

signal card_clicked(card: Card)

func setup(card_node: Card) -> void:
	super(card_node)
	card.view.gui_input.connect(_on_gui_input)

func teardown() -> void:
	card.view.gui_input.disconnect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var me: InputEventMouseButton = event as InputEventMouseButton
		if me.pressed and me.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(card)
