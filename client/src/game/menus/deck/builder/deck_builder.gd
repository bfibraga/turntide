class_name DeckBuilder extends AddableTabContainer

@onready var deck_browser: DeckBrowser = $"Deck Browser"

const DeckTab: PackedScene = preload("res://src/game/menus/deck/preview/deck_preview.tscn")

func _ready() -> void:
	deck_browser.request_create_deck.connect(func() -> void:
		var deck_data: DeckData = DeckData.Builder.new() \
			.from_dict({ "deck_name": "New deck" }) \
			.build()
		
		Global.deck_repository.create_deck(deck_data)
		
		self.add_deck_tab(deck_data)
	)
	
	deck_browser.open_deck.connect(func(deck_data: DeckData) -> void:
		self.add_deck_tab(deck_data)
	)
	
	super._ready()

func add_deck_tab(deck_data: DeckData) -> void:
	var tab_name: String = deck_data.deck_name
	var tab: Option = self.find_tab(tab_name)
	
	if tab.is_some():
		self.focus_tab(tab_name)
	else:
		var deck_node: DeckPreview = DeckTab.instantiate()
		if deck_node.has_method("setup"):
			deck_node.setup(deck_data, remove_deck_tab.bind(tab_name))
		
		deck_node.name = tab_name
		
		self.add_tab(deck_node)
		
		self.focus_tab(tab_name)

func remove_deck_tab(deck_name: String) -> void:
	self.focus_tab(self.name)
	self.remove_tab(deck_name)
