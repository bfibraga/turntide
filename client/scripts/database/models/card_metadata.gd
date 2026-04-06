class_name CardMetadata 
extends RefCounted

var uuid: String = ""
var name: String = ""
var setcode: String = ""
var number: String = ""
var rarity: String = ""
var type_line: String = ""
var mana_value: float = .0
var colors: String = ""
var text: String = ""
var power: String = ""
var toughness: String = ""
var scryfall_id: String = ""

func _init(
	uuid: String = "",
	name: String = "",
	setcode: String = "",
	number: String = "",
	rarity: String = "",
	type_line: String = "",
	mana_value: float = .0,
	colors: String = "",
	text: String = "",
	power: String = "",
	toughness: String = "",
	scryfall_id: String = "",
) -> void:
	self.uuid = uuid 
	self.name = name 
	self.setcode = setcode 
	self.number = number 
	self.rarity = rarity 
	self.type_line = type_line 
	self.mana_value = mana_value 
	self.colors = colors 
	self.text = text 
	self.power = power 
	self.toughness = toughness 
	self.scryfall_id = scryfall_id 

static func from_dict(data: Dictionary) -> CardMetadata:
	return CardMetadata.new(
		data.get("uuid", ""),
		data.get("name", ""),
		data.get("setCode", ""),
		data.get("number", ""),
		data.get("rarity", ""),
		data.get("types", ""),
		data.get("manaValue", 0.0),
		data.get("colors", ""),
		data.get("text", ""),
		#data.get("power", ""),
		#data.get("toughness", ""),
		#data.get("scryfall_id", ""),
	)

func to_dict() -> Dictionary:
	return {
		"uuid": self.uuid,
		"name": self.name,
		"setcode": self.setcode,
		"number": self.number,
		"rarity": self.rarity,
		"type_line": self.type_line,
		"mana_value": self.mana_value,
		"colors": self.colors,
		"text": self.text,
		"power": self.power,
		"toughness": self.toughness,
		"scryfall_id": self.scryfall_id,
	}

func to_turntide_format() -> String:
	var line : String = "{name} {setcode} {number}"
	return line.format({ 
		"name": self.name, 
		"setcode": "[%s]" % self.setcode, 
		"number": ("[%s]" % self.number) if self.number else "",
	})
	
func _to_string() -> String:
	return "[Card: %s (%s)]" % [name, setcode]
	
