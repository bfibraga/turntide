extends GutTest

var _card_controller: CardController
var _card_data: CardData
var _card_game_state_machine: CardGameStateMachine
var _card_animation_state_machine: CardAnimationStateMachine

func before_each() -> void:
	var CardControllerScript = load("res://features/gameplay/scripts/card/controller.gd")
	var CardDataScript = load("res://features/gameplay/scripts/card/data.gd")
	var CardMetadataScript = load("res://core/database/models/card_metadata.gd")
	var GameStateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	var AnimationStateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")

	_card_controller = CardControllerScript.new()
	add_child(_card_controller)

	var metadata = CardMetadataScript.new("uuid1", "Test Card", "TST", "1")
	_card_data = CardDataScript.new(metadata)

	_card_game_state_machine = GameStateMachineScript.new()
	add_child(_card_game_state_machine)

	_card_animation_state_machine = AnimationStateMachineScript.new()
	add_child(_card_animation_state_machine)

func test_full_card_lifecycle() -> void:
	assert_eq(_card_data.current_state, CardState.IN_HAND)
	
	_card_game_state_machine.set_state(CardState.ON_BATTLEFIELD)
	await _card_game_state_machine.state_changed
	
	assert_eq(_card_data.current_state, CardState.ON_BATTLEFIELD)
	
	_card_game_state_machine.set_state(CardState.IN_GRAVEYARD)
	await _card_game_state_machine.state_changed
	
	assert_eq(_card_data.current_state, CardState.IN_GRAVEYARD)

func test_input_to_state_change() -> void:
	var state_change_triggered = false
	
	_card_controller.clicked.connect(func() -> void:
		state_change_triggered = true
	)
	
	var mock_input = InputEventMouseButton.new()
	mock_input.button_index = MOUSE_BUTTON_LEFT
	mock_input.pressed = true
	
	_card_controller._on_gui_input(mock_input)
	
	mock_input.pressed = false
	_card_controller._on_gui_input(mock_input)
	
	assert_true(state_change_triggered)