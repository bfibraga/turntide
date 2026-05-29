extends GutTest

func test_setup_populates_data() -> void:
	var repo: KeywordRepository = KeywordRepository.new()
	repo.setup()

	var all_keywords: Array[Dictionary] = repo.all()
	assert_eq(all_keywords.size(), 4)

func test_find_existing_keyword() -> void:
	var repo: KeywordRepository = KeywordRepository.new()
	repo.setup()

	var result: Result = repo.find("Flying")
	assert_true(result.is_ok())
	assert_eq(result.unwrap(), { "name": "Flying", "description": "This creature can't be blocked except by creatures with flying and/or reach." })

func test_find_non_existent_keyword() -> void:
	var repo: KeywordRepository = KeywordRepository.new()
	repo.setup()

	var result: Result = repo.find("NonExistentKeyword")
	assert_true(result.is_err())

func test_all_returns_all_keywords() -> void:
	var repo: KeywordRepository = KeywordRepository.new()
	repo.setup()

	var all_keywords: Array[Dictionary] = repo.all()
	assert_eq(all_keywords.size(), 4)

	var names: Array[String] = []
	for entry: Dictionary in all_keywords:
		names.append(entry["name"])

	assert_true("Flying" in names)
	assert_true("Haste" in names)
	assert_true("Trample" in names)
	assert_true("Convoke" in names)

func test_find_returns_correct_description_for_each() -> void:
	var repo: KeywordRepository = KeywordRepository.new()
	repo.setup()

	var haste_result: Result = repo.find("Haste")
	assert_true(haste_result.is_ok())
	assert_eq(haste_result.unwrap(), { "name": "Haste", "description": "This creature can attack and {T} as soon as it comes under your control." })

	var trample_result: Result = repo.find("Trample")
	assert_true(trample_result.is_ok())
	assert_eq(trample_result.unwrap(), { "name": "Trample", "description": "This creature can deal excess combat damage to the player or planeswalker it's attacking." })

	var convoke_result: Result = repo.find("Convoke")
	assert_true(convoke_result.is_ok())
	assert_eq(convoke_result.unwrap(), { "name": "Convoke", "description": "Your creatures can help cast this spell. Each creature you tap while casting this spell pays for {1} or one mana of that creature's color." })
