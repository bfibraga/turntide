class_name CardCatalog extends RefCounted

# A deeply nested dictionary structure
var _catalog: Dictionary[String, Variant] = {}
var _iter_cards: Array[CardData] = []

func _init(cards: Array[CardData], properties: Array[String]) -> void:
	self.categorize_nested(cards, properties)

"""
Groups a flat array of cards by an ordered list of properties.
e.g., ["setCode", "type"]
"""
func categorize_nested(cards: Array[CardData], properties: Array[String]) -> void:
	_catalog.clear()
	
	if properties.is_empty():
		return

	for card: CardData in cards:
		var current_layer: Dictionary = _catalog
		
		# Traverse down to the second-to-last category tier
		for i: int in range(properties.size() - 1):
			var prop_name: String = properties[i]
			var prop_value: String = card.get(prop_name)
			if prop_value.is_empty(): 
				prop_value = "Unknown"
				
			if not current_layer.has(prop_value):
				current_layer[prop_value] = {}
				
			current_layer = current_layer[prop_value]
		
		# Handle the final layer, which contains the actual Array[CardData]
		var final_prop_name: String = properties[-1]
		var final_value: String = card.get(final_prop_name)
		if final_value.is_empty(): 
			final_value = "Unknown"
			
		if not current_layer.has(final_value):
			var typed_array: Array[CardData] = []
			current_layer[final_value] = typed_array
			
		current_layer[final_value].append(card)

func get_top_level_keys() -> Array[String]:
	return _catalog.keys()

## Safely fetches cards at a specific nested path.
## e.g., get_cards_at_path(["M21", "Creature"])
func get_cards_at_path(path: Array[String]) -> Array[CardData]:
	var current_layer = _catalog
	
	for i: int in range(path.size()):
		var key: String = path[i]
		if not current_layer.has(key):
			return [] # Path doesn't exist
			
		current_layer = current_layer[key]
		
	# If the path is correct, the final element found must be our Array
	if current_layer is Array:
		return current_layer
		
	return []


## Returns the dictionary structure at a given partial path.
## Useful for building UI dropdowns dynamically.
func get_branches_at_path(path: Array[String]) -> Array:
	var current_layer: Dictionary = _catalog
	for key: String in path:
		if not current_layer.has(key) or not current_layer[key] is Dictionary:
			return []
		current_layer = current_layer[key]
	return current_layer.keys()

func _to_string() -> String:
	return "%s" % _catalog
	
func _iter_init(arg: Array) -> bool:
	# 1. Clear out any data from a previous loop
	_iter_cards.clear()
	
	# 2. Extract every single card hidden inside the nested dictionary
	_flatten_dictionary(_catalog, _iter_cards)
	
	# 3. Initialize the loop state index (arg[0]) at 0
	arg[0] = 0
	
	# Return true if we actually have cards to loop over, false to skip entirely
	return _iter_cards.size() > 0


func _iter_next(arg: Array) -> bool:
	# 1. Increment the current loop index
	arg[0] += 1
	
	# 2. Keep looping as long as our index is less than the total size
	return arg[0] < _iter_cards.size()


func _iter_get(arg: Variant) -> Variant:
	# arg is the index number tracked by arg[0] in the init/next steps
	# Return the specific card at this spot in our flattened array
	return _iter_cards[arg]


## Private helper method to recursively pull CardData arrays out of nested dictionaries
func _flatten_dictionary(dict: Dictionary, out_array: Array[CardData]) -> void:
	for value in dict.values():
		if value is Dictionary:
			# Keep drilling down until we hit the leaf arrays
			_flatten_dictionary(value, out_array)
		elif value is Array:
			# We found a bucket of cards! Add them all to our flat list
			out_array.append_array(value)
