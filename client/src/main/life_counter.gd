@icon("res://addons/icodot/ui/fantasy/icon-heart-piece-ui.svg")
class_name LifeCounter extends Panel

class Data extends Reactive:
	var life_total: ReactiveValue = ReactiveValue.Int(25, self)

@export_range(12, 72) var font_size: int = 26

@export_category("Danger Settings")
@export var danger_life_total: int = 10
@export var danger_life_color: Color = Color.BROWN

var data: Data = Data.new()

@onready var plus: Button = $%Plus
@onready var life: RichTextLabel = $%Life
@onready var minus: Button = $%Minus

func _init(max_life: int = 25) -> void:
	data.life_total.value = max_life

func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		var life_total: int = reactive.life_total.value
		
		if life_total <= danger_life_total:
			_update_life_label(
				life_total, 
				danger_life_color, 
				RichTextEffectPulse.new(), 
				{ "freq": 1.0, "min_alpha": 0.6, }
			)
		else:
			_update_life_label(life_total)
	)
	
	plus.pressed.connect(func() -> void:
		data.life_total.value += 1
	)
	
	minus.pressed.connect(func() -> void:
		data.life_total.value -= 1
	)
	
	data.manually_emit()

func _update_life_label(life_total: int, life_color: Color = Color.WHITE_SMOKE, 
	life_effect: RichTextEffect = RichTextEffect.new(), effect_env: Dictionary = {}) -> void:
	life.clear()
	
	life.push_color(life_color)
	life.push_font_size(font_size)
	life.push_customfx(life_effect, effect_env)
	life.push_bold()
	life.append_text(str(life_total))
	life.pop_all()
	
	life.queue_redraw()
	
