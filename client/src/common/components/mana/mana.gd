class_name ManaSymbolTexture extends TextureRect

@export var mana_symbol_collection: Dictionary[String, Resource] = {
	"colorless": preload("res://assets/mana_symbols/colorless/colorless_mana_symbol.svg"),
	"white": preload("res://assets/mana_symbols/white/white_mana_symbol.png"),
	"white_phyrexian": preload("res://assets/mana_symbols/white/white_phyrexian_mana_symbol.png"),
	"blue": preload("res://assets/mana_symbols/blue/blue_mana_symbol.png"),
	"blue_phyrexian": preload("res://assets/mana_symbols/blue/blue_phyrexian_mana_symbol.png"),
	"black": preload("res://assets/mana_symbols/black/black_mana_symbol.png"),
	"black_phyrexian": preload("res://assets/mana_symbols/black/black_phyrexian_mana_symbol.png"),
	"red": preload("res://assets/mana_symbols/red/red_mana_symbol.png"),
	"red_phyrexian": preload("res://assets/mana_symbols/red/red_phyrexian_mana_symbol.png"),
	"green": preload("res://assets/mana_symbols/green/green_mana_symbol.png"),
	"green_phyrexian": preload("res://assets/mana_symbols/green/green_phyrexian_mana_symbol.png"),	
}

class Data extends Reactive:
	var color: Reactive = ReactiveValue.new("colorless", self)

var data: Data = Data.new()

func _ready() -> void:
	data.color.reactive_changed.connect(func(reactive: ReactiveValue) -> void:
		set_color(reactive.value)
	)

func set_color(color: String = "colorless") -> ManaSymbolTexture:
	var new_texture: Texture = mana_symbol_collection.get(color) 
	self.texture = new_texture
	
	return self
