extends GutTest

class RectangleReactive extends ReactiveObject:
	var width: ReactiveValue = ReactiveValue.Int(0, self)
	var height: ReactiveValue = ReactiveValue.Int(0, self)
	var area: Reactive = ComputedReactiveValue.new(
		func() -> int: return width.value * height.value,
		[width, height],
		self
	)
	
	func _init(initial_width: int, initial_height: int, initial_owner: Reactive = null) -> void:
		super._init(initial_owner)
		
		self.width.value = initial_width
		self.height.value = initial_height

func test_computed_value_initialization() -> void:
	var rectangle: RectangleReactive = RectangleReactive.new(10, 20)
	assert_eq(rectangle.area.value, 200)

func test_computed_value_updates_on_dependency_change() -> void:
	var rectangle: RectangleReactive = RectangleReactive.new(10, 20)
	
	rectangle.width.value = 5
	assert_eq(rectangle.area.value, 100)

func test_computed_value_emits_signal_on_dependency_change() -> void:
	var rectangle: RectangleReactive = RectangleReactive.new(10, 20)
	
	watch_signals(rectangle.area)
	rectangle.width.value = 5
	assert_signal_emitted(rectangle.area, "reactive_changed")

func test_computed_value_with_owner_propagation() -> void:
	var rectangle: RectangleReactive = RectangleReactive.new(10, 20)

	watch_signals(rectangle)
	rectangle.width.value = 5
	assert_signal_emitted(rectangle, "reactive_changed")

func test_computed_value_is_read_only() -> void:
	var rectangle: RectangleReactive = RectangleReactive.new(10, 20)

	rectangle.area.value = 999
	assert_eq(rectangle.area.value, 200)  # Still computed

func test_computed_value_multiple_dependencies() -> void:
	var a: Reactive = ReactiveValue.Int(1)
	var b: Reactive = ReactiveValue.Int(2)
	var c: Reactive = ReactiveValue.Int(3)
	var sum: Reactive = ComputedReactiveValue.new(
		func() -> int: return a.value + b.value + c.value,
		[a, b, c]
	)
	assert_eq(sum.value, 6)
	a.value = 10
	assert_eq(sum.value, 15)

func test_computed_value_nested() -> void:
	var rectangle: RectangleReactive = RectangleReactive.new(10, 20)

	var scale: Reactive = ReactiveValue.Int(2)
	var scaled_area: Reactive = ComputedReactiveValue.new(
		func() -> int: return rectangle.area.value * scale.value,
		[rectangle.area, scale]
	)
	assert_eq(scaled_area.value, 400)
	rectangle.width.value = 5
	assert_eq(scaled_area.value, 200)
