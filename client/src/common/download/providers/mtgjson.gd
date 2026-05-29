class_name MTGJSONProvider
extends RefCounted

const MTGJSON_BASE_URL: String = "https://mtgjson.com/api/v5"
const ALL_PRINTINGS_FILENAME: String = "AllPrintings.sqlite"
const DEFAULT_DB_PATH: String = "user://cache/database/cards.db"

static func get_download_url() -> String:
	return "%s/%s" % [MTGJSON_BASE_URL, ALL_PRINTINGS_FILENAME]

static func get_default_db_path() -> String:
	return DEFAULT_DB_PATH
