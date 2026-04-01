extends Control
class_name Hand

var cards : Array[Card] = []
var initial_number_cards : int = 7

func _ready() -> void:
	for i: int in range(initial_number_cards):
		var card_data : CardData = CardData.new().random()
		var card_position : Vector2 = Vector2(i*125, 250)
		var card : Card = CardFactory.create_card_at_position(card_data, card_position)
		
		self.add_child(card)
