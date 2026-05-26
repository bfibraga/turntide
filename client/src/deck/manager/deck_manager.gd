class_name DeckManager extends Node

#region Signals

signal deck_initialized()
signal card_created(card_ui: Card, card_data: CardData)

#endregion

#region Exports

## The deck data to use
@export var deck_data: DeckData

## The pile to populate on setup
@export var starting_pile: Resource # TODO: Implement card pile object

@export_category("Setup settings")
## if [code]true[/code], calls [method setup] automatically on ready.
@export var auto_setup: bool = false

## if [code]true[/code], shuffles the starting pile after populating
@export var shuffle_on_setup: bool = true

#endregion

func _ready() -> void:
	if auto_setup:
		self.setup.call_deferred()

func setup(source_deck: DeckData = self.deck_data, target_pile: Resource = self.starting_pile) -> void:
	if source_deck:
		deck_data = source_deck
	
	if target_pile:
		starting_pile = target_pile
	
	if not starting_pile:
		#starting_pile = CardPile.new()
		#add_child(starting_pile)
		pass
	
	if not deck_data:
		push_warning("DeckManager: No deck assigned")
		return
	
	starting_pile.clear_and_free()
	
	for card_data in deck_data.get_mainboard_cards():
		var card = CardFactory.create_card(card_data)
		
