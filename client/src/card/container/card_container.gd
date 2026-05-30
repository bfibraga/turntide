@tool @icon("res://addons/icodot/ui/fantasy/icon-book-ui.svg")
class_name CardContainer extends Control

#region Signals

signal card_added(card: Card, index: int)
signal card_removed(card: Card, index: int)

signal container_full()
signal container_empty()

#endregion

#region Export

@export var max_cards: int = -1 :
	set(value):
		max_cards = value

@export var cards: Array[Card] = []
@export var card_container_manager: CardContainerManager

var card_behaviours: Array[CardBehavior] = []

#endregion

func _init(p_cards: Array[Card] = [], p_card_container_manager: CardContainerManager = null) -> void:
	cards = p_cards
	card_container_manager = p_card_container_manager

func _ready() -> void:
	self.child_entered_tree.connect(func(node: Card) -> void:
		cards.append(node)
		_on_card_entered(node)
	)
	self.child_exiting_tree.connect(func(node: Card) -> void:
		cards.erase(node)
		_on_card_exited(node)
	)
	card_container_manager.register_container(self)

func _on_card_entered(card_node: Card) -> void:
	card_node.clear_behaviors()
	_setup_card_behaviors(card_node)
	card_node.visibility_changed.connect(_on_card_visibility_changed.bind(card_node))

func _on_card_exited(card_node: Card) -> void:
	if card_node.visibility_changed.is_connected(_on_card_visibility_changed):
		card_node.visibility_changed.disconnect(_on_card_visibility_changed)

func _on_card_visibility_changed(card_node: Card) -> void:
	if not card_node.visible:
		card_node.clear_behaviors()
	elif is_ancestor_of(card_node):
		_setup_card_behaviors(card_node)

func _setup_card_behaviors(card_node: Card) -> void:
	for behaviour: CardBehavior in get_context_behaviors():
		card_node.add_behavior(behaviour.duplicate())

func _exit_tree() -> void:
	card_container_manager.unregister_container(self)

# Overide with specific card behaviours
func get_context_behaviors() -> Array[CardBehavior]:
	return card_behaviours

func organize_cards() -> void:
	pass

func has_cards() -> bool:
	return cards.size() > 0

@warning_ignore("unused_parameter")
func can_accept_card(card: Card) -> bool:
	return true

func peek_top_card() -> Card:
	return cards.get(cards.size() - 1)

func pop_top_card() -> Card:
	var card: Card = cards.pop_back()
	if not card:
		return null
		
	card_removed.emit(card, cards.size() + 1)
	
	if cards.size() == 0:
		container_empty.emit()
		
	return card
