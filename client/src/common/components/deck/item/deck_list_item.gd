class_name DeckListItem extends Panel

class Data extends Reactive:
	var name: ReactiveValue = ReactiveValue.String("", self)
	var color_identity: ReactiveSet = ReactiveSet.new(Set.new(), self)
	var tags: ReactiveSet = ReactiveSet.new(Set.new(), self)
	var format: ReactiveValue = ReactiveValue.new(null, self)

	func _init() -> void:
		super._init()

var data: Data = Data.new()

@onready var deck_name: RichTextLabel = %Name
@onready var color_identity: HBoxContainer = %"Color Identity"
@onready var tags: HFlowContainer = %Tags

@onready var ManaSymbolTextureScene: PackedScene = preload("res://src/common/components/mana/mana.tscn")
@onready var ChipScene: PackedScene = preload("res://src/common/components/chip/chip.tscn")

func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		# Update deck name 
		deck_name.clear()
		deck_name.append_text(reactive.name.value)
		
		# Update color identity
		color_identity.get_children(true) \
			.map(func(child: Node) -> void: child.queue_free())
		
		for color_name: String in reactive.color_identity.values():
			var mana_symbol_texture: ManaSymbolTexture = ManaSymbolTextureScene.instantiate()
			mana_symbol_texture.set_color(color_name)
			
			color_identity.add_child(mana_symbol_texture)
		
		# Update tags 		
		tags.get_children(true) \
			.map(func(child: Node) -> void: child.queue_free())
		
		if reactive.format.value:
			var format_name: String = (reactive.format.value as BaseFormat).display_name()
			var format_chip: Chip = ChipScene.instantiate()
			format_chip._init(format_name, Color.SLATE_GRAY)
			tags.add_child(format_chip)
		
		for tag: String in reactive.tags.values():
			var chip: Chip = ChipScene.instantiate()
			chip._init(tag, Color.SEA_GREEN)
			
			tags.add_child(chip)
	)
	
	data.manually_emit()
