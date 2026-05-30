@tool
class_name RichTextEffectPulse
extends RichTextEffect

var bbcode: String = "mypulse"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var freq: float = char_fx.env.get("freq", 2.0)
	var min_alpha: float = char_fx.env.get("min_alpha", 0.2) 
	
	var wave: float = sin(char_fx.elapsed_time * freq * PI)
	var normalized_wave: float = (wave + 1.0) / 2.0
	
	var target_alpha: float = lerp(min_alpha, 1.0, normalized_wave)
	
	char_fx.color.a *= target_alpha
	
	return true
