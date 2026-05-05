class_name CardViewRenderer extends Reactive

var card_data
var game_state_machine
var animation_state_machine

func _init() -> void:
	super._init()

func observe_card_data(data) -> void:
	card_data = data
	if card_data:
		card_data.reactive_changed.connect(_on_card_data_changed)

func observe_game_state(state_machine) -> void:
	game_state_machine = state_machine
	if game_state_machine:
		game_state_machine.state_changed.connect(_on_game_state_changed)

func observe_animation_state(state_machine) -> void:
	animation_state_machine = state_machine
	if animation_state_machine:
		animation_state_machine.state_changed.connect(_on_animation_state_changed)

func _on_card_data_changed(_reactive: Reactive) -> void:
	reactive_changed.emit(self)

func _on_game_state_changed(_from: State, _to: State) -> void:
	reactive_changed.emit(self)

func _on_animation_state_changed(_from: State, _to: State) -> void:
	reactive_changed.emit(self)