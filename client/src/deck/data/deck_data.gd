@icon("res://addons/icodot/node/fantasy/icon-book.svg")
class_name DeckData extends Resource

class Builder:
	var _properties: Dictionary[String, Variant] = {}
	
	func from_dict(data: Dictionary) -> Builder:
		_properties.merge(data, true)
		return self
	
	func _to_set(value: Variant) -> Set:
		if value is Set:
			return value
		elif value is Array:
			return Set.new(value)
		
		return Set.new()
	
	func build() -> DeckData:
		var result: DeckData = DeckData.new()
		
		for property: String in _properties:
			match property:
				"format":
					var format_name: String = _properties.get(property)
					var format_object_option: Option = Global.deck_format_manager.find_from_name(format_name)
					
					if format_object_option.is_some():
						result.set(property, format_object_option.unwrap())
				
				"color_identity", "tags":
					var property_data: Variant = _properties.get(property)
					result.set(property, _to_set(property_data))
				
				"mainboard", "sideboard":
					var cards: Dictionary = _properties.get(property)
					var card_uuids: Array[String] = []
					var cards_data: Dictionary[CardData, int] = {}
					
					if cards.size() == 0:
						continue
										
					for uuid: String in cards.keys():
						card_uuids.append(uuid) 

					var cards_data_array: Array[CardData] = Global.card_repository.get_cards_by_uuids(
						card_uuids
					)
				
					for card_data: CardData in cards_data_array:
						var quantity: int = cards[card_data.uuid]
						
						cards_data[card_data] = quantity
					
					result.set(property, cards_data)
				
				_: result.set(property, _properties.get(property))
		
		return result

#region Exports

@export_category("Identity")
@export var deck_name: String = ""
@export var format: BaseFormat
@export var tags: Set = Set.new()
@export var color_identity: Set = Set.new()

@export_category("Boards")
@export var mainboard: Dictionary[CardData, int] = {}
@export var sideboard: Dictionary[CardData, int] = {}

#endregion

## Returns a duplicate of the card list of the mainboard
func get_mainboard_cards() -> Array[CardData]:
	return mainboard.keys().duplicate(true)

## Returns a duplicate of the card list of the sideboard
func get_sideboard_cards() -> Array[CardData]:
	return mainboard.keys().duplicate(true)

## Returns a [code]Dictionary[/code] version of the deck data.
func to_dict() -> Dictionary:
	var mainboard_content: Dictionary = {}
	for card: CardData in mainboard:
		mainboard_content.set(card.uuid, mainboard[card])
	
	var sideboard_content: Dictionary = {}
	for card: CardData in sideboard:
		sideboard_content.set(card.uuid, sideboard[card])
	
	return {
		"deck_name": deck_name,
		"format": format.display_name(),
		"tags": tags.values(),
		"color_identity": color_identity.values(),
		"mainboard": mainboard_content,
		"sideboard": sideboard_content,
	}

static func from_dict(dictionary: Dictionary) -> DeckData:
	return DeckData.Builder.new() \
		.from_dict(dictionary) \
		.build()

func _to_string() -> String:
	return "{deck_name} ({color_identity})".format({
		"deck_name": deck_name,
		"color_identity": color_identity
	})
