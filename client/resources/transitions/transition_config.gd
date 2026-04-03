class_name TransitionConfig
extends Resource

enum TransitionEffect {
	NONE = 0,
	FADE = 1,
	FADE_COLOR = 2,
	SLIDE_LEFT = 3,
	SLIDE_RIGHT = 4,
	SLIDE_UP = 5,
	SLIDE_DOWN = 6,
	DISSOLVE = 7,
	CROSSFADE = 8,
}

## Transition animation effect
@export var effect: TransitionEffect = TransitionEffect.NONE

## Duration of transition animation in seconds
@export_range(0.1, 2.0, 0.05) var duration: float = 0.5

## Color used for fade effects
@export var fade_color: Color = Color.BLACK

## Minimum time to display loading screen (prevents flicker)
@export_range(0.1, 2.0, 0.05) var loading_min_time: float = 0.3

## Whether to show loading screen during scene load
@export var show_loading_screen: bool = true

func _init(p_effect: TransitionEffect = TransitionEffect.NONE, p_duration: float = 0.5, p_fade_color: Color = Color.BLACK, p_loading_min_time: float = 0.3, p_show_loading_screen: bool = true) -> void:
	effect = p_effect
	duration = p_duration
	fade_color = p_fade_color
	loading_min_time = p_loading_min_time
	show_loading_screen = p_show_loading_screen
