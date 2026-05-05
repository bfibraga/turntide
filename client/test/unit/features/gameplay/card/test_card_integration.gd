extends GutTest

var _card_controller: CardController
var _card_data: CardData
var _card_game_state_machine: CardGameStateMachine
var _card_animation_state_machine: CardAnimationStateMachine
var _renderer: CardViewRenderer

func before_each() -> void:
	var CardControllerScript = load("res://features/gameplay/scripts/card/controller.gd")
	var CardDataScript = load("res://features/gameplay/scripts/card/data.gd")
	var CardMetadataScript = load("res://core/database/models/card_metadata.gd")
	var GameStateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	var AnimationStateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	var RendererScript = load("res://features/gameplay/scripts/card/view/renderer.gd")

	_card_controller = CardControllerScript.new()
	add_child(_card_controller)

	var metadata = CardMetadataScript.new("uuid1", "Test Card", "TST", "1")
	_card_data = CardDataScript.new(metadata)

	_card_game_state_machine = GameStateMachineScript.new()
	_card_animation_state_machine = AnimationStateMachineScript.new()
	
	_renderer = RendererScript.new()
	_renderer.observe_card_data(_card_data)
	_renderer.observe_game_state(_card_game_state_machine)
	_renderer.observe_animation_state(_card_animation_state_machine)

func test_renderer_is_reactive() -> void:
	assert_true(_renderer is Reactive)

func test_renderer_sees_all_components() -> void:
	assert_not_null(_renderer.card_data)
	assert_not_null(_renderer.game_state_machine)
	assert_not_null(_renderer.animation_state_machine)

func test_data_propagates_to_renderer() -> void:
	var signal_received = false
	_renderer.reactive_changed.connect(func(_r): signal_received = true)
	_card_data.manually_emit()
	assert_true(signal_received)

func test_game_state_change_propagates() -> void:
	var signal_received = false
	_renderer.reactive_changed.connect(func(_r): signal_received = true)
	var in_hand = _card_game_state_machine.states["inhand"]
	_card_game_state_machine.on_state_transition(in_hand, "OnBattlefield")
	assert_true(signal_received)

func test_animation_state_change_propagates() -> void:
	var signal_received = false
	_renderer.reactive_changed.connect(func(_r): signal_received = true)
	var idle = _card_animation_state_machine.states["idle"]
	_card_animation_state_machine.on_state_transition(idle, "Hovering")
	assert_true(signal_received)