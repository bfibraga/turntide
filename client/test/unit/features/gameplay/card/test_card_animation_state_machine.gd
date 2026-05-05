extends GutTest

var _signal_flag: bool = false

func test_initial_state_is_idle() -> void:
	var IdleScript = load("res://features/gameplay/scripts/card/state/animation/idle.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	
	var idle_state = IdleScript.new()
	idle_state.name = "Idle"
	
	var sm = StateMachineScript.new()
	sm.add_child(idle_state)
	sm.initial_state = idle_state
	
	sm._ready()
	
	assert_eq(sm.current_state.name.to_lower(), "idle".to_lower())

func test_transition_idle_to_hovering() -> void:
	var IdleScript = load("res://features/gameplay/scripts/card/state/animation/idle.gd")
	var HoveringScript = load("res://features/gameplay/scripts/card/state/animation/hovering.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	
	var idle_state = IdleScript.new()
	idle_state.name = "Idle"
	var hovering_state = HoveringScript.new()
	hovering_state.name = "Hovering"
	
	var sm = StateMachineScript.new()
	sm.add_child(idle_state)
	sm.add_child(hovering_state)
	sm.initial_state = idle_state
	
	sm._ready()
	
	var initial_state = sm.current_state
	idle_state.Transitioned.emit(idle_state, "Hovering")
	
	assert_ne(sm.current_state, initial_state)
	assert_eq(sm.current_state.name.to_lower(), "hovering".to_lower())

func test_transition_hovering_to_dragging() -> void:
	var IdleScript = load("res://features/gameplay/scripts/card/state/animation/idle.gd")
	var HoveringScript = load("res://features/gameplay/scripts/card/state/animation/hovering.gd")
	var DraggingScript = load("res://features/gameplay/scripts/card/state/animation/dragging.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	
	var idle_state = IdleScript.new()
	idle_state.name = "Idle"
	var hovering_state = HoveringScript.new()
	hovering_state.name = "Hovering"
	var dragging_state = DraggingScript.new()
	dragging_state.name = "Dragging"
	
	var sm = StateMachineScript.new()
	sm.add_child(idle_state)
	sm.add_child(hovering_state)
	sm.add_child(dragging_state)
	sm.initial_state = idle_state
	
	sm._ready()
	
	idle_state.Transitioned.emit(idle_state, "Hovering")
	
	assert_eq(sm.current_state.name.to_lower(), "hovering".to_lower())
	
	hovering_state.Transitioned.emit(hovering_state, "Dragging")
	
	assert_eq(sm.current_state.name.to_lower(), "dragging".to_lower())

func test_transition_dragging_to_playing() -> void:
	var IdleScript = load("res://features/gameplay/scripts/card/state/animation/idle.gd")
	var DraggingScript = load("res://features/gameplay/scripts/card/state/animation/dragging.gd")
	var PlayingScript = load("res://features/gameplay/scripts/card/state/animation/playing.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	
	var idle_state = IdleScript.new()
	idle_state.name = "Idle"
	var dragging_state = DraggingScript.new()
	dragging_state.name = "Dragging"
	var playing_state = PlayingScript.new()
	playing_state.name = "Playing"
	
	var sm = StateMachineScript.new()
	sm.add_child(idle_state)
	sm.add_child(dragging_state)
	sm.add_child(playing_state)
	sm.initial_state = idle_state
	
	sm._ready()
	
	idle_state.Transitioned.emit(idle_state, "Dragging")
	
	assert_eq(sm.current_state.name.to_lower(), "dragging".to_lower())
	
	dragging_state.Transitioned.emit(dragging_state, "Playing")
	
	assert_eq(sm.current_state.name.to_lower(), "playing".to_lower())

func test_can_transition_back_to_idle() -> void:
	var IdleScript = load("res://features/gameplay/scripts/card/state/animation/idle.gd")
	var HoveringScript = load("res://features/gameplay/scripts/card/state/animation/hovering.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	
	var idle_state = IdleScript.new()
	idle_state.name = "Idle"
	var hovering_state = HoveringScript.new()
	hovering_state.name = "Hovering"
	
	var sm = StateMachineScript.new()
	sm.add_child(idle_state)
	sm.add_child(hovering_state)
	sm.initial_state = idle_state
	
	sm._ready()
	
	idle_state.Transitioned.emit(idle_state, "Hovering")
	
	assert_eq(sm.current_state.name.to_lower(), "hovering".to_lower())
	
	hovering_state.Transitioned.emit(hovering_state, "Idle")
	
	assert_eq(sm.current_state.name.to_lower(), "idle".to_lower())

func test_state_changed_signal_emits_on_transition() -> void:
	var IdleScript = load("res://features/gameplay/scripts/card/state/animation/idle.gd")
	var HoveringScript = load("res://features/gameplay/scripts/card/state/animation/hovering.gd")
	var StateMachineScript = load("res://features/gameplay/scripts/card/state/animation/state_machine.gd")
	
	var idle_state = IdleScript.new()
	idle_state.name = "Idle"
	var hovering_state = HoveringScript.new()
	hovering_state.name = "Hovering"
	
	var sm = StateMachineScript.new()
	sm.add_child(idle_state)
	sm.add_child(hovering_state)
	sm.initial_state = idle_state
	
	_signal_flag = false
	sm.state_changed.connect(_on_state_changed)
	
	sm._ready()
	idle_state.Transitioned.emit(idle_state, "Hovering")
	
	assert_true(_signal_flag)

func _on_state_changed(_f, _t) -> void:
	_signal_flag = true