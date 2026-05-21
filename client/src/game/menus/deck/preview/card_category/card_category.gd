class_name CardCategory extends VBoxContainer

class Data extends Reactive:
	var category_name: ReactiveValue = ReactiveValue.String("", self)
	var cards: ReactiveArray = ReactiveArray.new([], self)
	var quantity: ReactiveValue = ReactiveValue.Int(0, self)

var data: Data = Data.new()

@onready var label: RichTextLabel = %Label
@onready var quantity: RichTextLabel = %Quantity
@onready var cards_container: VBoxContainer = %Cards

const CardScene: PackedScene = preload("res://src/card/ui/card_ui.tscn")

func _init() -> void:
	self.ready.connect(func() -> void: data.manually_emit())

func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		label.text = reactive.category_name.value
		quantity.text = "Qty: %d" % reactive.quantity.value
		
		for child: Node in cards_container.get_children():
			child.queue_free()
		
		for card_data: CardData in reactive.cards.value:
			var card: CardUI = CardScene.instantiate()
			card.data.card_data.value = card_data
			
			card.ready.connect(func() -> void:
				card.view.on_mouse_enter.connect(func() -> void:
					print("On enter")
					card.view.tooltip_text = card.data.card_data.value.name
				)
			)
			
			cards_container.add_child.call_deferred(card)
	)
