class_name ReactiveValue extends Reactive

var value : Variant :
	set(v):
		if value != null and typeof(v) != typeof(value):
			push_error("""Pushing wrong type of reactive value: 
				Expected: {expected}
				Actual: {actual}""".format({
				"actual": type_string(typeof(v)),
				"expected": type_string(typeof(value))
			}))
			return value
		
		value = v
		reactive_changed.emit(self)
		return value

func _init(initial_value: Variant, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value

static func Int(initial_value: int, initial_owner: Reactive = null) -> Reactive:
	return ReactiveValue.new(initial_value, initial_owner)

static func Float(initial_value: float, initial_owner: Reactive = null) -> Reactive:
	return ReactiveValue.new(initial_value, initial_owner)

static func String(initial_value: String, initial_owner: Reactive = null) -> Reactive:
	return ReactiveValue.new(initial_value, initial_owner)

static func Boolean(initial_value: bool, initial_owner: Reactive = null) -> Reactive:
	return ReactiveValue.new(initial_value, initial_owner)
