class_name DrawCommand extends CardContainerCommand

var hand: Hand
var library: Library

func _init(p_hand: Hand, p_library: Library) -> void:
	self.hand = p_hand
	self.library = p_library

func execute() -> void:
	var card: Card = library.pop_top_card()
	if not card:
		push_warning("DrawCommand: drawing from empty library")
		return
	
	Global.add_child(card)
	card.move_to(hand, null)
