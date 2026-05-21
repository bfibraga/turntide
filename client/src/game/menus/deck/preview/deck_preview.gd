class_name DeckPreview extends TabContainer

class Data extends Reactive:
	var deck_data: ReactiveObject = ReactiveObject.new(null, self)
	var categories: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> Dictionary[String, CardCatalog]:
			var properties: Array[String] = ["types"]
			var deck: DeckData = deck_data.value
			var mainboard_cards: Array[CardData] = deck.mainboard.keys() if deck else [] 
			var sideboard_cards: Array[CardData] = deck.sideboard.keys() if deck else [] 
			
			return {
				"mainboard": CardCatalog.new(mainboard_cards, properties),
				"sideboard": CardCatalog.new(sideboard_cards, properties),
			},
		[deck_data],
		null
	)

var data: Data = Data.new()

@onready var deck_name: RichTextLabel = %"Deck Name"
@onready var color_identity: HBoxContainer = %"Color Identity"
@onready var card_categories: HBoxContainer = %"Card Categories"

@onready var close: Button = %Close

const ManaSymbolTextureScene: PackedScene = preload("res://src/common/components/mana/mana.tscn")
const CardCategoryScene: PackedScene = preload("res://src/game/menus/deck/preview/card_category/card_category.tscn")

func setup(deck_data: DeckData, on_close_callable: Callable) -> void:
	self.ready.connect(func() -> void: 
		data.deck_data.value = deck_data
		close.pressed.connect(on_close_callable)
	)
	
func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		var deck_data: DeckData = reactive.deck_data.value
		
		deck_name.text = deck_data.deck_name
		
		# Update color identity
		color_identity.get_children(true) \
			.map(func(child: Node) -> void: child.queue_free())
		
		for color_name: String in deck_data.color_identity.values():
			var mana_symbol_texture: ManaSymbolTexture = ManaSymbolTextureScene.instantiate()
			mana_symbol_texture.set_color(color_name)
			
			color_identity.add_child(mana_symbol_texture)
		
		color_identity.queue_redraw()
		
		for child: Node in card_categories.get_children(true):
			child.queue_free()
		
		_build_board(reactive.categories.value.get("mainboard"), deck_data)
		#_build_board(reactive.categories.value.get("sideboard"), deck_data)
		
		card_categories.queue_redraw()
	)

func _build_board(catalog: CardCatalog, deck_data: DeckData) -> void:
	for key: String in catalog.get_top_level_keys():
		var card_category_node: CardCategory = CardCategoryScene.instantiate().duplicate()
		var cards: Array[CardData] = catalog.get_cards_at_path([key])
		
		card_category_node.name = key
		card_category_node.data.category_name.value = key
		card_category_node.data.cards.value = cards
		card_category_node.data.quantity.value = cards.reduce(func(accum: int, card: CardData) -> int:
			var quantity: int = deck_data.mainboard[card]
			return accum + quantity,
			0
		)
		
		card_categories.add_child(card_category_node)
