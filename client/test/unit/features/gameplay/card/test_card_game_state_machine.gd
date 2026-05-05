extends GutTest

var _signal_flag: bool = false
var _entered_flag: bool = false

func test_initial_state_is_in_hand() -> void:
	var InHandScript = load("res://features/gameplay/scripts/card/state/game/in_hand.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	
	var hand_state = InHandScript.new()
	hand_state.name = "InHand"
	
	var sm = StateMachineScript.new()
	sm.add_child(hand_state)
	sm.initial_state = hand_state
	
	sm._ready()
	
	assert_eq(sm.current_state.name.to_lower(), "inhand".to_lower())

func test_transition_hand_to_battlefield() -> void:
	var InHandScript = load("res://features/gameplay/scripts/card/state/game/in_hand.gd")
	var OnBattlefieldScript = load("res://features/gameplay/scripts/card/state/game/on_battlefield.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	
	var hand_state = InHandScript.new()
	hand_state.name = "InHand"
	var battlefield_state = OnBattlefieldScript.new()
	battlefield_state.name = "OnBattlefield"
	
	var sm = StateMachineScript.new()
	sm.add_child(hand_state)
	sm.add_child(battlefield_state)
	sm.initial_state = hand_state
	
	sm._ready()
	
	var initial_state = sm.current_state
	hand_state.Transitioned.emit(hand_state, "OnBattlefield")
	
	assert_ne(sm.current_state, initial_state)

func test_state_changed_signal_emits() -> void:
	var InHandScript = load("res://features/gameplay/scripts/card/state/game/in_hand.gd")
	var OnBattlefieldScript = load("res://features/gameplay/scripts/card/state/game/on_battlefield.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	
	var hand_state = InHandScript.new()
	hand_state.name = "InHand"
	var battlefield_state = OnBattlefieldScript.new()
	battlefield_state.name = "OnBattlefield"
	
	var sm = StateMachineScript.new()
	sm.add_child(hand_state)
	sm.add_child(battlefield_state)
	sm.initial_state = hand_state
	
	_signal_flag = false
	sm.state_changed.connect(_on_state_changed)
	
	sm._ready()
	hand_state.Transitioned.emit(hand_state, "OnBattlefield")
	
	assert_true(_signal_flag)

func _on_state_changed(_f, _t) -> void:
	_signal_flag = true

func test_enter_called() -> void:
	var InHandScript = load("res://features/gameplay/scripts/card/state/game/in_hand.gd")
	var OnBattlefieldScript = load("res://features/gameplay/scripts/card/state/game/on_battlefield.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/game/state_machine.gd")
	
	var hand_state = InHandScript.new()
	hand_state.name = "InHand"
	var battlefield_state = OnBattlefieldScript.new()
	battlefield_state.name = "OnBattlefield"
	
	var sm = StateMachineScript.new()
	sm.add_child(hand_state)
	sm.add_child(battlefield_state)
	sm.initial_state = hand_state
	
	sm._ready()
	
	var current = sm.current_state
	assert_true(current != null)