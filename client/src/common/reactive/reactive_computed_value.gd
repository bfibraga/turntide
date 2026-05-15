class_name ComputedReactiveValue extends Reactive

var _compute: Callable
var _dependencies: Array[Reactive]

var value: Variant :
	get: return _compute.call()
	set(v): 
		push_warning("Setting value on a computed object")

func _init(compute: Callable, dependencies: Array[Reactive], initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	_compute = compute
	_dependencies = dependencies
	
	for dep: Reactive in _dependencies:
		dep.reactive_changed.connect(_propagate)

func _propagate(_reactive: Reactive = null) -> void:
	reactive_changed.emit(self)

func manually_emit() -> void:
	reactive_changed.emit(self)
