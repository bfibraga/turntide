class_name FPSCounter
extends Label

var _fps : float = Engine.get_frames_per_second()

func _process(delta: float) -> void:
	var current_fps : float = Engine.get_frames_per_second()
	_fps = lerp(_fps, current_fps, delta * .5)
	text = "FPS %.2f" % _fps
