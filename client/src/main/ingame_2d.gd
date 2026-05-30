@icon("res://addons/icodot/ui/office/icon-gamepad-ui.svg")
extends Control

@export var hand: Hand
@export var library: Library
@export var graveyard: CardContainer

@export var draw_button: Button
@export var draw_7_button: Button
@export var discard_button: Button
@export var discard_hand_button: Button

func _ready() -> void:
	var draw_command: CardContainerCommand = DrawCommand.new(hand, library)
	var discard_command: CardContainerCommand = DiscardCommand.new(hand, graveyard)
	
	if draw_button:
		draw_button.pressed.connect(func() -> void: 
			draw_command.execute()
		)
	
	library.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_released("ui_accept"):
			draw_command.execute()
	)
	
	if draw_7_button:
		draw_7_button.pressed.connect(func() -> void: 
			range(7).map(func(i: int) -> void: 
				await get_tree().create_timer(0.25 * i).timeout
				
				return draw_command.execute()
			)
		)
	
	if discard_button:
		discard_button.pressed.connect(func() -> void:
			discard_command.execute()
		)
	
	if discard_hand_button:
		discard_hand_button.pressed.connect(func() -> void:
			while hand.has_cards():
				await get_tree().create_timer(0.25).timeout
				
				discard_command.execute()
		)
