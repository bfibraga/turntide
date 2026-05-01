extends Control

signal transition_requested(state_name: String)

@export var state_machine: StateMachine

@onready var play_button: Button = $%Play
@onready var decks_button: Button = $%Decks
@onready var account_button: Button = $%Account
@onready var settings_button: Button = $%Settings


func _ready() -> void:
	play_button.pressed.connect(func() -> void: _on_play_button_pressed())
	decks_button.pressed.connect(func() -> void: _on_decks_button_pressed())
	account_button.pressed.connect(func() -> void: _on_account_button_pressed())
	settings_button.pressed.connect(func() -> void: _on_settings_button_pressed())

func _on_play_button_pressed() -> void:
	pass

func _on_decks_button_pressed() -> void:
	transition_requested.emit(DeckBuilderState.Name())

func _on_account_button_pressed() -> void:
	transition_requested.emit(CardViewerState.Name())

func _on_settings_button_pressed() -> void:
	pass
