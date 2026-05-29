class_name TapBehavior extends CardBehavior

func setup(card_node: Card) -> void:
	super(card_node)
	card.view.tap_card.connect(_on_tap)
	card.view.flip_card.connect(_on_flip)

func teardown() -> void:
	card.view.tap_card.disconnect(_on_tap)
	card.view.flip_card.disconnect(_on_flip)

func _on_tap() -> void:
	card.view.toggle_tap()

func _on_flip() -> void:
	card.view.toggle_flip()
