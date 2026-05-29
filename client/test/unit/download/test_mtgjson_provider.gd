extends GutTest

func test_get_download_url() -> void:
	var url: String = MTGJSONProvider.get_download_url()
	assert_eq(url, "https://mtgjson.com/api/v5/AllPrintings.sqlite")

func test_get_default_db_path() -> void:
	var path: String = MTGJSONProvider.get_default_db_path()
	assert_eq(path, "user://cache/database/cards.db")

func test_constants_match_paths() -> void:
	assert_true(MTGJSONProvider.get_download_url().contains(MTGJSONProvider.ALL_PRINTINGS_FILENAME))
