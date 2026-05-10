class_name ReactiveSet extends Reactive

var value : Set :
	set(v):
		value = v
		reactive_changed.emit(self)
		return value

func _init(initial_value: Set = Set.new(), initial_owner: Reactive = null) -> void:
	value = initial_value
	super._init(initial_owner)

func add(item: Variant) -> void:
	value.add(item)
	reactive_changed.emit(self)

func remove(item: Variant) -> void:
	value.remove(item)
	reactive_changed.emit(self)

func has(item: Variant) -> bool:
	return value.has(item)

func size() -> int:
	return value.size()

func values() -> Array:
	return value.values()

func clear() -> void:
	value.clear()
	reactive_changed.emit(self)

func merge(items: Set) -> void:
	value.merge(items)
	reactive_changed.emit(self)

func intersect(other: ReactiveSet) -> ReactiveSet:
	var result: ReactiveSet = ReactiveSet.new(value, owner)
	result.value = result.value.intersect(other.value)
	
	return result

func contains_all(other: ReactiveSet) -> bool:
	return value.contains_all(other.value)
