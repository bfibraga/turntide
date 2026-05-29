class_name ScryfallProvider
extends RefCounted

const SCRYFALL_CDN_BASE: String = "https://cards.scryfall.io"
const FORMAT_EXTENSIONS: Dictionary = {
	"png": "png",
	"large": "jpg",
	"normal": "jpg",
	"small": "jpg",
	"border_crop": "jpg",
	"art_crop": "jpg",
}

static func build_image_url(scryfall_id: String, format: String = "large", face: String = "front") -> String:
	var ext: String = FORMAT_EXTENSIONS.get(format, "jpg")
	return "%s/%s/%s/%s/%s/%s.%s" % [
		SCRYFALL_CDN_BASE, format, face,
		#scryfall_id[0], scryfall_id.substr(0, 2),
		scryfall_id[0], scryfall_id[1],
		scryfall_id, ext,
	]

static func sanitize_filename(name: String) -> String:
	var invalid_chars: Array[String] = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", " "]
	var result: String = name
	for char: String in invalid_chars:
		result = result.replace(char, "_")
	return result

static func build_image_filename(card_name: String, set_code: String, uuid: String, format: String = "large") -> String:
	var ext: String = FORMAT_EXTENSIONS.get(format, "jpg")
	return "%s_%s_%s.%s" % [
		sanitize_filename(card_name),
		set_code,
		uuid.substr(0, 8),
		ext,
	]
