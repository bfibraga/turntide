class_name DeckData extends Resource

class Builder extends RefCounted:
	var _properties: Dictionary[String, Variant] = {}
	
	func from_dict(data: Dictionary) -> Builder:
		_properties.merge(data, true)
		return self
	
	func build() -> DeckData:
		var result: DeckData = DeckData.new()
		
		for property: String in _properties:
			if property.containsn("format"):
				var format_name: String = _properties.get(property)
				var format_object: BaseFormat = Global.deck_format_manager.find_from_name(format_name)
				result.set(property, format_object)
			else:
				result.set(property, _properties.get(property))
		
		return result
	
@export_category("Identity")
@export var deck_name: String = ""
@export var format: BaseFormat
@export var tags: Set = Set.new() :
	set(value):
		tags = _to_set(value)
		return tags

@export var color_identity: Set = Set.new() :
	set(value):
		color_identity = _to_set(value)
		return color_identity

@export_category("Boards")
@export var mainboard: Dictionary[CardData, int] = {}
@export var sideboard: Dictionary[CardData, int] = {}

func to_dict() -> Dictionary:
	var mainboard_arr: Array[Dictionary] = []
	for card: CardData in mainboard:
		mainboard_arr.append({
			"uuid": card.uuid,
			"quantity": mainboard[card]
		})
	var sideboard_arr: Array[Dictionary] = []
	for card: CardData in sideboard:
		sideboard_arr.append({
			"uuid": card.uuid,
			"quantity": sideboard[card]
		})
	return {
		"deck_name": deck_name,
		"format": format.display_name() if format else "",
		"tags": tags.values(),
		"color_identity": color_identity.values(),
		"mainboard": mainboard_arr,
		"sideboard": sideboard_arr,
	}

static func _to_set(value: Variant) -> Set:
	if value is Set:
		return value
	elif value is Array:
		return Set.new(value)
	
	return Set.new()

func _to_string() -> String:
	return "{deck_name} ({color_identity})".format({
		"deck_name": deck_name,
		"color_identity": color_identity
	})
