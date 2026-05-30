@tool @icon("res://addons/icodot/ui/blocks/icon-block-isometric-ui.svg")
class_name CardData
extends Resource

class Builder extends RefCounted:
	var _properties: Dictionary[String, Variant] = {}

	func from_dict(data: Dictionary) -> Builder:
		_properties.merge(data, true)
		return self

	func build() -> CardData:
		var result: CardData = CardData.new()

		for property: String in _properties:
			result.set(property, _properties.get(property))

		return result


@export_category("Metadata")

#region Identity

@export_group("Identity")
@export var uuid: String = ""
@export var name: String = ""
@export var number: String = ""
@export var rarity: String = ""

#endregion

#region Printing & Release

@export_group("Printing & Release")
@export var setCode: String = ""
@export var printings: String = ""
@export var originalPrintings: String = ""
@export var originalReleaseDate: String = ""
@export var rebalancedPrintings: String = ""
@export var promoTypes: String = ""
@export var finishes: String = ""

#endregion

@export_group("IDs")
@export var scryfallId: String = ""


@export_category("Classification & Type")

@export_group("Classification")
@export var type: String = ""
@export var types: String = ""
@export var supertypes: String = ""
@export var subtypes: String = ""


@export_category("Face & Printing")

@export_group("Face")
@export var faceName: String = ""
@export var facePrintedName: String = ""
@export var faceFlavorName: String = ""
@export var faceConvertedManaCost: float = .0
@export var faceManaValue: float = .0
@export var otherFaceIds: String = ""

@export_group("Artist & Credits")
@export var artist: String = ""
@export var artistIds: String = ""


@export_category("Text & Rules")

@export_group("Text & Flavor")
@export var text: String = ""
@export var flavorText: String = ""
@export var flavorName: String = ""

@export_group("Rules & Text")
@export var printedText: String = ""
@export var originalText: String = ""
@export var printedType: String = ""
@export var frameEffects: String = ""
@export var frameVersion: String = ""


@export_category("Color & Mana")

@export_group("Color & Mana Details")
@export var colors: String = ""
@export var colorIdentity: String = ""
@export var colorIndicator: String = ""
@export var manaCost: String = ""
@export var manaValue: float = .0
@export var producedMana: String = ""


@export_category("Stats & Gameplay")

@export_group("Stats & Gameplay")
@export var power: String = ""
@export var toughness: String = ""
@export var life: String = ""
@export var defense: String = ""
@export var loyalty: String = ""
@export var hand: String = ""


@export_category("Aggregates & Flags")

@export_group("Aggregates & Rankings")
@export var edhrecRank: int = 0
@export var edhrecSaltiness: float = .0

@export_group("Flags")
@export var hasAlternativeDeckLimit: bool = false
@export var hasContentWarning: bool = false
@export var isAlternative: bool = false
@export var isFullArt: bool = false
@export var isFunny: bool = false
@export var isGameChanger: bool = false
@export var isOnlineOnly: bool = false
@export var isOversized: bool = false
@export var isPromo: bool = false
@export var isRebalanced: bool = false
@export var isReprint: bool = false
@export var isReserved: bool = false
@export var isStorySpotlight: bool = false
@export var isTextless: bool = false
@export var isTimeshifted: bool = false


@export_category("Metadata Extras")

@export_group("Keywords & Language")
@export var keywords: String = ""
@export var language: String = ""

@export_group("Layout & Presentation")
@export var layout: String = ""
@export var watermark: String = ""
@export var borderColor: String = ""


@export_category("Collections & Relations")

@export_group("Collections & Relations")
@export var cardParts: String = ""
@export var relatedCards: String = ""
@export var variations: String = ""
@export var subsets: String = ""
@export var sourceProducts: String = ""


@export_category("Misc")

@export_group("Misc")
@export var attractionLights: String = ""
@export var availability: String = ""
@export var boosterTypes: String = ""
@export var duelDeck: String = ""
@export var leadershipSkills: String = ""
@export var printedName: String = ""
@export var securityStamp: String = ""
@export var side: String = ""
@export var signature: String = ""
@export var skuIds: String = ""


func to_turntide_format() -> String:
	var line : String = "{name} {setCode} {number}"
	return line.format({ 
		"name": self.name, 
		"setCode": "[%s]" % self.setCode, 
		"number": ("[%s]" % self.number) if self.number else "",
	})


func _to_string() -> String:
	return "[Card: %s [%s] (%s)]" % [name, number, setCode]
