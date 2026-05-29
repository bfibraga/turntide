extends GutTest

func test_parse_empty_content() -> void:
	var result: Array = TurntideParser.parse("")
	assert_eq(result.size(), 0)

func test_parse_single_card_name_only() -> void:
	var result: Array = TurntideParser.parse("Island")
	assert_eq(result.size(), 1)
	assert_eq(result[0].name, "Island")
	assert_eq(result[0].set_code, "")
	assert_eq(result[0].card_id, "")

func test_parse_single_card_with_set_code() -> void:
	var result: Array = TurntideParser.parse("Island [LRW]")
	assert_eq(result.size(), 1)
	assert_eq(result[0].name, "Island")
	assert_eq(result[0].set_code, "LRW")
	assert_eq(result[0].card_id, "")

func test_parse_single_card_with_set_code_and_id() -> void:
	var result: Array = TurntideParser.parse("Sokka, Tenacious Tactician [TLA] [0352]")
	assert_eq(result.size(), 1)
	assert_eq(result[0].name, "Sokka, Tenacious Tactician")
	assert_eq(result[0].set_code, "TLA")
	assert_eq(result[0].card_id, "0352")

func test_parse_multiple_cards() -> void:
	var decklist: String = "Island [LRW]\nMountain [M10]\nPlains [FNM] [001]"
	var result: Array = TurntideParser.parse(decklist)
	assert_eq(result.size(), 3)
	assert_eq(result[0].name, "Island")
	assert_eq(result[0].set_code, "LRW")
	assert_eq(result[1].name, "Mountain")
	assert_eq(result[1].set_code, "M10")
	assert_eq(result[2].name, "Plains")
	assert_eq(result[2].set_code, "FNM")
	assert_eq(result[2].card_id, "001")

func test_parse_skips_empty_lines() -> void:
	var decklist: String = "Island [LRW]\n\n\nMountain [M10]"
	var result: Array = TurntideParser.parse(decklist)
	assert_eq(result.size(), 2)

func test_parse_trims_whitespace() -> void:
	var decklist: String = "  Island [LRW]  \n  Mountain [M10]  "
	var result: Array = TurntideParser.parse(decklist)
	assert_eq(result.size(), 2)
	assert_eq(result[0].name, "Island")
	assert_eq(result[1].name, "Mountain")

func test_parse_handles_unclosed_bracket() -> void:
	var result: Array = TurntideParser.parse("Island [LRW")
	assert_eq(result.size(), 1)
	assert_eq(result[0].name, "Island [LRW")
	assert_eq(result[0].set_code, "")

func test_parse_card_name_with_apostrophe() -> void:
	var result: Array = TurntideParser.parse("Oko, Thief of Crowns [ELD] [0201]")
	assert_eq(result.size(), 1)
	assert_eq(result[0].name, "Oko, Thief of Crowns")
	assert_eq(result[0].set_code, "ELD")
	assert_eq(result[0].card_id, "0201")

func test_parse_card_name_with_dashes() -> void:
	var result: Array = TurntideParser.parse("A-Bomb [XYZ] [001]")
	assert_eq(result.size(), 1)
	assert_eq(result[0].name, "A-Bomb")
	assert_eq(result[0].set_code, "XYZ")
	assert_eq(result[0].card_id, "001")

func test_parse_line_no_brackets() -> void:
	var card = TurntideParser._parse_line("Island")
	assert_not_null(card)
	assert_eq(card.name, "Island")

func test_parse_line_only_brackets() -> void:
	var card = TurntideParser._parse_line("   [LRW]   ")
	assert_not_null(card)
	assert_eq(card.name, "")

func test_parse_line_empty_returns_null() -> void:
	var card = TurntideParser._parse_line("")
	assert_null(card)

func test_parse_line_whitespace_only_returns_null() -> void:
	var card = TurntideParser._parse_line("   ")
	assert_null(card)
