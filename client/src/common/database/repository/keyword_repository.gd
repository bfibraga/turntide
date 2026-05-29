class_name KeywordRepository extends MemoryRepository

@warning_ignore("unused_local_constant")
const KEYWORDS_DIR: String = ""

func _init(_path: String = KEYWORDS_DIR) -> void:
	pass

func open() -> Result:
	self.setup()
	return Result.Ok(_data)

func setup() -> void:
	# Populate with common keywords
	_data = {
		"Flying" : "This creature can't be blocked except by creatures with flying and/or reach.",
		"Haste"  : "This creature can attack and {T} as soon as it comes under your control.",
		"Trample": "This creature can deal excess combat damage to the player or planeswalker it's attacking.",
	
		"Convoke": "Your creatures can help cast this spell. Each creature you tap while casting this spell pays for {1} or one mana of that creature's color."
	}

func find(keyword_name: String) -> Result:
	#var description_opt: Option = Option.dict_get(_data, keyword_name)
	#
	#return Result.new({ "name": keyword_name, "description": description }, description != null)
	
	return Option.dict_get(_data, keyword_name) \
		.ok_or(null) \
		.map(func(description: String) -> Dictionary: return { "name": keyword_name, "description": description })
		
func all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for keyword_name: String in _data:
		var description: String = _data.get(keyword_name)
		
		result.append({ "name": keyword_name, "description": description })
	
	return result
	
