extends GutTest

var _test_signal_flag: bool = false

func test_renderer_is_reactive() -> void:
	var RendererScript = load("res://features/gameplay/scripts/card/view/renderer.gd")
	var renderer = RendererScript.new()
	assert_true(renderer is Reactive)

func test_renderer_observes_card_data() -> void:
	var RendererScript = load("res://features/gameplay/scripts/card/view/renderer.gd")
	var CardDataScript = load("res://features/gameplay/scripts/card/data.gd")
	var CardMetadataScript = load("res://core/database/models/card_metadata.gd")
	
	var metadata = CardMetadataScript.new("uuid1", "Test Card", "TST", "1")
	var data = CardDataScript.new(metadata)
	var renderer = RendererScript.new()

	_test_signal_flag = false
	renderer.reactive_changed.connect(_on_renderer_changed)

	renderer.observe_card_data(data)
	data.manually_emit()

	assert_true(_test_signal_flag)

func test_renderer_observes_game_state_changes() -> void:
	var RendererScript = load("res://features/gameplay/scripts/card/view/renderer.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	var renderer = RendererScript.new()

	var state_machine = StateMachineScript.new()
	add_child(state_machine)

	_test_signal_flag = false
	renderer.reactive_changed.connect(_on_renderer_changed)

	renderer.observe_game_state(state_machine)
	state_machine.state_changed.emit(null, null)

	assert_true(_test_signal_flag)

func test_renderer_observes_animation_state_changes() -> void:
	var RendererScript = load("res://features/gameplay/scripts/card/view/renderer.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	var renderer = RendererScript.new()

	var state_machine = StateMachineScript.new()
	add_child(state_machine)

	_test_signal_flag = false
	renderer.reactive_changed.connect(_on_renderer_changed)

	renderer.observe_animation_state(state_machine)
	state_machine.state_changed.emit(null, null)

	assert_true(_test_signal_flag)

func _on_renderer_changed(_r) -> void:
	_test_signal_flag = true