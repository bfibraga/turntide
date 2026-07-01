class_name ReactiveArray extends Reactive

var value : Array[Variant] :
	set(v):
		value = v
		reactive_changed.emit(self)
		return value

func _init(initial_value: Array[Variant] = [], initial_owner: Reactive = null) -> void:
	value = initial_value
	super._init(initial_owner)

func size() -> int:
	return value.size()

func get_at(index: int) -> Variant:
	return value[index]

func set_at(index: int, v: Variant) -> void:
	value[index] = v
	reactive_changed.emit(self)

func append(v: Variant) -> void:
	value.append(v)
	reactive_changed.emit(self)

func append_array(array: Array[Variant]) -> void:
	value.append_array(array)
	reactive_changed.emit(self)

func assign(array: Array[Variant]) -> void:
	value.assign(array)
	reactive_changed.emit(self)

func erase(v: Variant) -> void:
	value.erase(v)
	reactive_changed.emit(self)

func insert(position: int, v: Variant) -> void:
	value.insert(position, v)
	reactive_changed.emit(self)

func pop_at(index: int) -> Variant:
	var result: Variant = value.pop_at(index)
	reactive_changed.emit(self)
	return result

func pop_back() -> Variant:
	var result: Variant = value.pop_back()
	reactive_changed.emit(self)
	return result
	
func pop_front() -> Variant:
	var result: Variant = value.pop_front()
	reactive_changed.emit(self)
	return result 

func peek() -> Variant:
	return value.get(value.size() - 1)

func push_back(v: Variant) -> void:
	append(v)

func push_front(v: Variant) -> void:
	value.push_front(v)
	reactive_changed.emit(self)

func remove_at(index: int) -> void:
	value.remove_at(index)
	reactive_changed.emit(self)

func shuffle() -> void:
	value.shuffle()
	reactive_changed.emit(self)

func sort() -> void:
	value.sort()
	reactive_changed.emit(self)

func sort_custom(callable: Callable) -> void:
	value.sort_custom(callable)
	reactive_changed.emit(self)
	
func filter(callable: Callable) -> ReactiveArray:
	var result: ReactiveArray = ReactiveArray.new(value.duplicate(), owner)
	result.value.filter(callable)
	
	result.reactive_changed.emit(result)
	return result
