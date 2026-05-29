extends GutTest

func test_build_image_url_default_format() -> void:
	var url: String = ScryfallProvider.build_image_url("6da045f8-6278-4c84-9d39-025adf0789c1")
	assert_eq(url, "https://cards.scryfall.io/large/front/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.jpg")

func test_build_image_url_png_format() -> void:
	var url: String = ScryfallProvider.build_image_url(
		"6da045f8-6278-4c84-9d39-025adf0789c1", "png"
	)
	assert_eq(url, "https://cards.scryfall.io/png/front/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.png")

func test_build_image_url_small_format() -> void:
	var url: String = ScryfallProvider.build_image_url(
		"6da045f8-6278-4c84-9d39-025adf0789c1", "small"
	)
	assert_eq(url, "https://cards.scryfall.io/small/front/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.jpg")

func test_build_image_url_back_face() -> void:
	var url: String = ScryfallProvider.build_image_url(
		"6da045f8-6278-4c84-9d39-025adf0789c1", "large", "back"
	)
	assert_eq(url, "https://cards.scryfall.io/large/back/6/6d/6da045f8-6278-4c84-9d39-025adf0789c1.jpg")

func test_build_image_url_unknown_format_falls_back_to_jpg() -> void:
	var url: String = ScryfallProvider.build_image_url(
		"6da045f8-6278-4c84-9d39-025adf0789c1", "unknown_format"
	)
	assert_true(url.ends_with(".jpg"))

func test_build_image_url_short_id() -> void:
	var url: String = ScryfallProvider.build_image_url("ab")
	assert_true(url.contains("/a/ab/ab.jpg"))

func test_sanitize_filename_replaces_slashes() -> void:
	var result: String = ScryfallProvider.sanitize_filename("a/b")
	assert_eq(result, "a_b")

func test_sanitize_filename_replaces_spaces() -> void:
	var result: String = ScryfallProvider.sanitize_filename("Island of the Dead")
	assert_eq(result, "Island_of_the_Dead")

func test_sanitize_filename_replaces_special_chars() -> void:
	var result: String = ScryfallProvider.sanitize_filename("Oko: Thief*of\"Crowns?")
	assert_eq(result, "Oko__Thief_of_Crowns_")

func test_build_image_filename_default_format() -> void:
	var filename: String = ScryfallProvider.build_image_filename(
		"Island", "LRW", "550c853a-7e1f-4e78-9980-a1baab51f94b"
	)
	assert_eq(filename, "Island_LRW_550c853a.jpg")

func test_build_image_filename_with_special_chars() -> void:
	var filename: String = ScryfallProvider.build_image_filename(
		"Oko, Thief of Crowns", "ELD", "abc12345-0000-0000-0000-000000000000"
	)
	assert_eq(filename, "Oko,_Thief_of_Crowns_ELD_abc12345.jpg")

func test_build_image_filename_png_format() -> void:
	var filename: String = ScryfallProvider.build_image_filename(
		"Card", "SET", "uuid1234-....-....-....-............", "png"
	)
	assert_eq(filename, "Card_SET_uuid1234.png")
