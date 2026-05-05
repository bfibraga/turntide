extends GutTest

func test_card_initialization() -> void:
	var card: Card = Card.new()
	assert_not_null(card)
