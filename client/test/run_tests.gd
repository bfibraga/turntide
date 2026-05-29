extends SceneTree

func _initialize() -> void:
	var exit_code: int = 0

	if not _test_turntide_parser():
		exit_code = 1
	if not _test_scryfall_provider():
		exit_code = 1
	if not _test_mtgjson_provider():
		exit_code = 1
	if not _test_state_can_transition_away():
		exit_code = 1
	if not _test_installation_state_format_bytes():
		exit_code = 1
	if not _test_state_machine_self_transition_guard():
		exit_code = 1
	if not _test_state_machine_blocked_transition():
		exit_code = 1


	if exit_code == 0:
		print("\nAll tests passed!")
	else:
		print("\nSome tests failed!")

	quit(exit_code)

func _assert_eq(got, expected, test_name: String) -> bool:
	if got != expected:
		print("FAIL: %s — expected '%s', got '%s'" % [test_name, str(expected), str(got)])
		return false
	print("PASS: %s" % test_name)
	return true

func _assert_true(value: bool, test_name: String) -> bool:
	if not value:
		print("FAIL: %s — expected true" % test_name)
		return false
	print("PASS: %s" % test_name)
	return true

func _assert_not_null(value, test_name: String) -> bool:
	if value == null:
		print("FAIL: %s — expected non-null" % test_name)
		return false
	print("PASS: %s" % test_name)
	return true

func _assert_null(value, test_name: String) -> bool:
	if value != null:
		print("FAIL: %s — expected null" % test_name)
		return false
	print("PASS: %s" % test_name)
	return true

# ─── TurntideParser tests ───

func _test_turntide_parser() -> bool:
	print("\n=== TurntideParser ===")
	var ok: bool = true
	var ScryfallProviderScript = load("res://src/common/download/providers/scryfall.gd")
	var MTGJSONProv = load("res://src/common/download/providers/mtgjson.gd")
	var TurntideParserScript = load("res://src/common/parsers/turntide_parser.gd")

	if not TurntideParserScript:
		push_error("Could not load TurntideParser")
		return false

	ok = ok and _assert_eq(TurntideParserScript.parse("").size(), 0, "parse empty content")

	var single: Array = TurntideParserScript.parse("Island")
	ok = ok and _assert_eq(single.size(), 1, "single card count")
	ok = ok and _assert_eq(single[0].name, "Island", "single card name")
	ok = ok and _assert_eq(single[0].set_code, "", "single card set_code")
	ok = ok and _assert_eq(single[0].card_id, "", "single card card_id")

	var with_set: Array = TurntideParserScript.parse("Island [LRW]")
	ok = ok and _assert_eq(with_set[0].name, "Island", "card with set name")
	ok = ok and _assert_eq(with_set[0].set_code, "LRW", "card with set code")

	var with_id: Array = TurntideParserScript.parse("Sokka, Tenacious Tactician [TLA] [0352]")
	ok = ok and _assert_eq(with_id[0].name, "Sokka, Tenacious Tactician", "multi-bracket name")
	ok = ok and _assert_eq(with_id[0].set_code, "TLA", "multi-bracket set")
	ok = ok and _assert_eq(with_id[0].card_id, "0352", "multi-bracket id")

	var multi: Array = TurntideParserScript.parse("Island [LRW]\nMountain [M10]\nPlains [FNM] [001]")
	ok = ok and _assert_eq(multi.size(), 3, "multiple cards count")

	var skip_empty: Array = TurntideParserScript.parse("A [X]\n\n\nB [Y]")
	ok = ok and _assert_eq(skip_empty.size(), 2, "skip empty lines")

	var trimmed: Array = TurntideParserScript.parse("  Island [LRW]  ")
	ok = ok and _assert_eq(trimmed[0].name, "Island", "trim whitespace")

	var unclosed: Array = TurntideParserScript.parse("Island [LRW")
	ok = ok and _assert_eq(unclosed[0].name, "Island [LRW", "unclosed bracket")

	var apostrophe: Array = TurntideParserScript.parse("Oko, Thief of Crowns [ELD] [0201]")
	ok = ok and _assert_eq(apostrophe[0].name, "Oko, Thief of Crowns", "apostrophe in name")

	var parse_line_null = TurntideParserScript._parse_line("")
	ok = ok and _assert_null(parse_line_null, "_parse_line empty")

	var parse_line_null2 = TurntideParserScript._parse_line("   ")
	ok = ok and _assert_null(parse_line_null2, "_parse_line whitespace")

	return ok

# ─── ScryfallProvider tests ───

func _test_scryfall_provider() -> bool:
	print("\n=== ScryfallProvider ===")
	var ok: bool = true
	var SP = load("res://src/common/download/providers/scryfall.gd")

	if not SP:
		push_error("Could not load ScryfallProvider")
		return false

	ok = ok and _assert_eq(
		SP.build_image_url("6da045f8-6278-4c84-9d39-025adf0789c1"),
		"https://cards.scryfall.io/large/front/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.jpg",
		"default format URL"
	)

	ok = ok and _assert_eq(
		SP.build_image_url("6da045f8-6278-4c84-9d39-025adf0789c1", "png"),
		"https://cards.scryfall.io/png/front/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.png",
		"png format URL"
	)

	ok = ok and _assert_eq(
		SP.build_image_url("6da045f8-6278-4c84-9d39-025adf0789c1", "small"),
		"https://cards.scryfall.io/small/front/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.jpg",
		"small format URL"
	)

	ok = ok and _assert_eq(
		SP.build_image_url("6da045f8-6278-4c84-9d39-025adf0789c1", "large", "back"),
		"https://cards.scryfall.io/large/back/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.jpg",
		"back face URL"
	)

	ok = ok and _assert_true(
		SP.build_image_url("6da045f8-6278-4c84-9d39-025adf0789c1", "unknown_format").ends_with(".jpg"),
		"unknown format fallback to jpg"
	)

	ok = ok and _assert_eq(
		SP.sanitize_filename("a/b"),
		"a_b",
		"sanitize slash"
	)

	ok = ok and _assert_eq(
		SP.sanitize_filename("Island of the Dead"),
		"Island_of_the_Dead",
		"sanitize spaces"
	)

	ok = ok and _assert_eq(
		SP.sanitize_filename("Oko: Thief*of\"Crowns?"),
		"Oko__Thief_of_Crowns_",
		"sanitize special chars"
	)

	ok = ok and _assert_eq(
		SP.build_image_filename("Island", "LRW", "550c853a-7e1f-4e78-9980-a1baab51f94b"),
		"Island_LRW_550c853a.jpg",
		"default image filename"
	)

	ok = ok and _assert_eq(
		SP.build_image_filename("Card", "SET", "uuid1234-....-....-....-............", "png"),
		"Card_SET_uuid1234.png",
		"png image filename"
	)

	return ok

# ─── MTGJSONProvider tests ───

func _test_mtgjson_provider() -> bool:
	print("\n=== MTGJSONProvider ===")
	var ok: bool = true
	var MP = load("res://src/common/download/providers/mtgjson.gd")

	if not MP:
		push_error("Could not load MTGJSONProvider")
		return false

	ok = ok and _assert_eq(
		MP.get_download_url(),
		"https://mtgjson.com/api/v5/AllPrintings.sqlite",
		"download URL"
	)

	ok = ok and _assert_eq(
		MP.get_default_db_path(),
		"user://cache/database/cards.db",
		"default DB path"
	)

	ok = ok and _assert_true(
		MP.get_download_url().contains(MP.ALL_PRINTINGS_FILENAME),
		"URL contains filename"
	)

	return ok

# ─── State.can_transition_away tests ───

func _test_state_can_transition_away() -> bool:
	print("\n=== State.can_transition_away ===")
	var ok: bool = true
	var StateScript = load("res://src/common/state_machine/state.gd")

	if not StateScript:
		push_error("Could not load State")
		return false

	var state: State = StateScript.new()
	ok = ok and _assert_true(state.can_transition_away, "can_transition_away defaults to true")

	state.can_transition_away = false
	ok = ok and _assert_true(not state.can_transition_away, "can_transition_away can be set to false")

	state.free()
	return ok

# ─── InstallationState._format_bytes tests ───

func _test_installation_state_format_bytes() -> bool:
	print("\n=== InstallationState._format_bytes ===")
	var ok: bool = true
	var IS = load("res://src/common/state_machine/states/gui/installation_state.gd")

	if not IS:
		push_error("Could not load InstallationState")
		return false

	ok = ok and _assert_eq(IS._format_bytes(0), "0 B", "format_bytes 0")
	ok = ok and _assert_eq(IS._format_bytes(512), "512 B", "format_bytes bytes")
	ok = ok and _assert_eq(IS._format_bytes(1024), "1.0 KB", "format_bytes 1 KB")
	ok = ok and _assert_eq(IS._format_bytes(2048), "2.0 KB", "format_bytes 2 KB")
	ok = ok and _assert_eq(IS._format_bytes(1048576), "1.0 MB", "format_bytes 1 MB")
	ok = ok and _assert_eq(IS._format_bytes(1100000), "1.0 MB", "format_bytes ~1 MB")

	return ok

# ─── StateMachine guard tests ───

class TestTrackedState:
	extends State

	var exit_called: bool = false
	var enter_called: bool = false

	func exit() -> void:
		exit_called = true

	func enter(data: Dictionary = {}) -> void:
		enter_called = true

func _test_state_machine_self_transition_guard() -> bool:
	print("\n=== StateMachine self-transition guard ===")
	var ok: bool = true
	var SM = load("res://src/common/state_machine/state_machine.gd")

	if not SM:
		push_error("Could not load StateMachine")
		return false

	var sm: StateMachine = SM.new()
	var state_a: TestTrackedState = TestTrackedState.new()
	state_a.name = "TestA"
	sm.add_child(state_a)
	sm.initial_state = state_a
	sm._ready()

	ok = ok and _assert_eq(sm.current_state, state_a, "initial state is TestA")
	# _ready() calls initial_state.enter(), reset flags
	state_a.exit_called = false
	state_a.enter_called = false

	state_a.Transitioned.emit(state_a, "TestA")

	ok = ok and _assert_true(not state_a.exit_called, "exit not called on self-transition")
	ok = ok and _assert_true(not state_a.enter_called, "enter not called on self-transition")
	ok = ok and _assert_eq(sm.current_state, state_a, "current state unchanged after self-transition")

	sm.queue_free()
	return ok

func _test_state_machine_blocked_transition() -> bool:
	print("\n=== StateMachine blocked transition ===")
	var ok: bool = true
	var SM = load("res://src/common/state_machine/state_machine.gd")

	if not SM:
		push_error("Could not load StateMachine")
		return false

	var sm: StateMachine = SM.new()
	var state_a: TestTrackedState = TestTrackedState.new()
	state_a.name = "TestA"
	var state_b: TestTrackedState = TestTrackedState.new()
	state_b.name = "TestB"
	sm.add_child(state_a)
	sm.add_child(state_b)
	sm.initial_state = state_a
	sm._ready()

	ok = ok and _assert_eq(sm.current_state, state_a, "initial state is TestA")
	# _ready() calls initial_state.enter(), reset flags
	state_a.exit_called = false
	state_a.enter_called = false

	state_a.can_transition_away = false

	state_a.Transitioned.emit(state_a, "TestB")

	ok = ok and _assert_true(not state_a.exit_called, "exit not called when blocked")
	ok = ok and _assert_true(not state_b.enter_called, "enter not called when blocked")
	ok = ok and _assert_eq(sm.current_state, state_a, "current state unchanged when blocked")

	state_a.can_transition_away = true
	state_a.Transitioned.emit(state_a, "TestB")

	ok = ok and _assert_true(state_a.exit_called, "exit called after unblock")
	ok = ok and _assert_true(state_b.enter_called, "enter called after unblock")
	ok = ok and _assert_eq(sm.current_state, state_b, "current state is TestB after unblock")

	sm.queue_free()
	return ok
