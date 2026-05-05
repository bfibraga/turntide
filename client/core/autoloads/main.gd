extends Control

@export var gui_state_machine: StateMachine

@onready var play_button: Button = $%Play
@onready var decks_button: Button = $%Decks
@onready var account_button: Button = $%Account
@onready var settings_button: Button = $%Settings
@onready var logger: Log = ConsoleLogger.new()

func _ready() -> void:	
	Global.game_controller.gui_state_machine = gui_state_machine
	
	play_button.pressed.connect(func() -> void: _on_play_button_pressed())
	decks_button.pressed.connect(func() -> void: _on_decks_button_pressed())
	account_button.pressed.connect(func() -> void: _on_account_button_pressed())
	settings_button.pressed.connect(func() -> void: _on_settings_button_pressed())

func _on_play_button_pressed() -> void:
	
	Global.game_controller.gui_transition_to(LobbyBrowserState.Name())
	#if gui_state_machine.current_state:
		#gui_state_machine.current_state.Transitioned.emit(
			#gui_state_machine.current_state,
			#LobbyBrowserState.Name()
		#)

func _on_decks_button_pressed() -> void:
	if gui_state_machine.current_state:
		gui_state_machine.current_state.Transitioned.emit(
			gui_state_machine.current_state,
			DeckBuilderState.Name()
		)

func _on_account_button_pressed() -> void:
	pass
	
func _on_settings_button_pressed() -> void:
	if gui_state_machine.current_state:
		gui_state_machine.current_state.Transitioned.emit(
			gui_state_machine.current_state,
			"settings"
		)
