extends Control

@export var hand: Hand
@export var draw_button: Button
@export var draw_7_button: Button
@export var discard_button: Button
@export var discard_hand_button: Button

func _ready() -> void:
	if draw_button:
		draw_button.pressed.connect(func() -> void: hand.draw())
	
	if draw_7_button:
		draw_7_button.pressed.connect(func() -> void: 
			range(7).map(func(i: int) -> void: 
				await get_tree().create_timer(0.25 * i).timeout
				return hand.draw()
			)
		)
	
	if discard_button:
		discard_button.pressed.connect(func() -> void: hand.discard())
