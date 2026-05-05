class_name FPSCounter
extends Label

@export var delay: float = .5

var _fps : float = Engine.get_frames_per_second()

func _process(delta: float) -> void:
	var current_fps : float = Engine.get_frames_per_second()
	_fps = lerp(_fps, current_fps, delta * delay)
	text = "FPS: %.0f" % _fps
