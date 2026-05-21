class_name DeckList extends VBoxContainer

@onready var DeckListItemScene: PackedScene = preload("res://src/common/components/deck/item/deck_list_item.tscn")

var selection: ReactiveValue = ReactiveValue.new(null)

func on_selection_changed(_reactive: Reactive) -> void:
	for child: Control in get_children():
		child.queue_redraw()

func rebuild_from_list(decks: Array[DeckData], pressed_callback: Callable) -> void:
	for child: Node in self.get_children():
		child.queue_free()
	
	var deck_list_item: PackedScene = DeckListItemScene.duplicate(true)
	for deck: DeckData in decks:
		var item: DeckListItem = deck_list_item.instantiate()
		item.data.name.value = deck.deck_name
		item.data.color_identity.value = deck.color_identity
		item.data.tags.value = deck.tags
		item.data.format.value = deck.format
		
		item.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton \
				and event.is_action_pressed("select"):
				selection.value = item
				pressed_callback.call(deck)
		)
		
		self.add_child(item)
