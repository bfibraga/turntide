class_name DeckFormat
extends RefCounted

enum Format {
	COMMANDER = 0,
	STANDARD = 1,
	MODERN = 2,
	PIONEER = 3,
	LEGACY = 4,
	VINTAGE = 5,
	PAUPER = 6,
	CASUAL = 7,
	CUSTOM = 8,
}

static func get_display_name(format: Format) -> String:
	match format:
		Format.COMMANDER: return "Commander"
		Format.STANDARD: return "Standard"
		Format.MODERN: return "Modern"
		Format.PIONEER: return "Pioneer"
		Format.LEGACY: return "Legacy"
		Format.VINTAGE: return "Vintage"
		Format.PAUPER: return "Pauper"
		Format.CASUAL: return "Casual"
		Format.CUSTOM: return "Custom"
		_: return "Unknown"

static func get_all_display_names() -> PackedStringArray:	
	return Format.keys().map(
		func(format) -> String: 
			return get_display_name(Format[format])
	) as PackedStringArray
	

static func from_string(str: String) -> Format:
	var upper: String = str.to_upper().replace(" ", "_")
	for format in Format.keys():
		if format == upper:
			return Format[format]
	return Format.CUSTOM
