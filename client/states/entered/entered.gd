extends Control

@onready var view_cards_button: Button = $"CenterContainer/VBoxContainer/View Cards"

func _ready() -> void:
	view_cards_button.pressed.connect(_on_view_cards_button_pressed)
	
func _on_view_cards_button_pressed() -> void:
	Global.game_controller.transition_gui(CardViewerState.Name())
