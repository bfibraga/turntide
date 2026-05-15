class_name Set extends Resource

var _data: Dictionary[Variant, bool] = {}

func _init(items: Array[Variant] = []) -> void:
	for item: Variant in items:
		self.add(item)

func add(item: Variant) -> void:
	_data[item] = true

func remove(item: Variant) -> void:
	_data.erase(item)

func has(item: Variant) -> bool:
	return _data.get(item, false)

func size() -> int:
	"""Return the size of the set"""
	return _data.size()

func values() -> Array:
	return _data.keys()

func clear() -> void:
	_data.clear()

func merge(items: Set) -> void:
	for item: Variant in items:
		add(item)

func intersect(other: Set) -> Set:
	var result : Set = Set.new()
	
	var smaller: Set = self if self.size() < other.size() else other
	var larger: Set = other if self.size() < other.size() else self
	
	for item: Variant in smaller:
		if larger.has(item):
			result.add(item)
	
	return result

func contains_all(other: Set) -> bool:
	var intersection: Set = intersect(other)
	
	return intersection.size() == other.size()

func to_dict() -> Dictionary:
	return { "values": values() }

static func from_dict(data: Dictionary) -> Set:
	return Set.new(data.get("values", [])) 

func _iter_init(iter: Array) -> bool:
	iter[0] = 0
	return _data.size() > 0

func _iter_next(iter: Array) -> bool:
	iter[0] += 1
	return iter[0] < _data.size()

func _iter_get(iter: Variant) -> Variant:
	var keys: Array[Variant] = _data.keys()
	return keys[iter]

func _get(property: StringName) -> Variant:
	if property == "_data":
		return _data.values()
	
	return null

# Overriding the built-in string representation
func _to_string() -> String:
	if _data.is_empty():
		return "{}"
	
	var items: Array = _data.keys()
	var result: String = "{"
	
	for i: int in range(items.size()):
		var val: Variant = items[i]
		# Wrap strings in quotes for clarity, otherwise use default string cast
		if val is String:
			result += '"' + val + '"'
		else:
			result += str(val)
			
		# Add a comma unless it's the last item
		if i < items.size() - 1:
			result += ", "
			
	result += "}"
	return result
