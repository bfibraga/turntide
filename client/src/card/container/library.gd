@tool 
class_name Library extends CardContainer

#@export var hand: Hand

var label: Label = Label.new()

func _ready() -> void:
	Global.card_repository = RepositoryFactory.new_card_repository()
	Global.deck_repository = RepositoryFactory.new_deck_repository()
	
	var decks: Array[DeckData] = Global.deck_repository.list_decks()
	if decks.size() == 0:
		return
	
	var deck: DeckData = decks.reduce(func(accum: DeckData, curr_deck: DeckData) -> DeckData:
		return accum if accum.mainboard.size() > curr_deck.mainboard.size() else curr_deck
	, decks[0])
	
	var deck_cards: Array[CardData] = deck.mainboard.keys()

	for card_data: CardData in deck_cards:
		var card: Card = CardFactory.create_card(card_data)
		cards.append(card)
	
	set_number_indicator()
	self.add_child(label)

func set_number_indicator() -> void:
	label.text = str(cards.size())
	

#func draw() -> void:
	#var card : Card = self.pop_top_card()
	#if not card:
		#return
	#
	#self.add_child(card)
	#card.move_to(hand, null)
	#set_number_indicator()
