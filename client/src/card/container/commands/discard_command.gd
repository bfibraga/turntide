class_name DiscardCommand extends CardContainerCommand

var hand: Hand
var graveyard: CardContainer

func _init(p_hand: Hand, p_graveyard: CardContainer) -> void:
	self.hand = p_hand
	self.graveyard = p_graveyard

func execute() -> void:
	var card: Card = hand.pop_top_card()
	if not card:
		push_warning("DrawCommand: drawing from empty library")
		return
	
	Global.add_child(card)
	card.move_to(graveyard, null)
