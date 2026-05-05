extends GutTest

func test_reactive_value_initialization() -> void:
	var rv: Reactive = ReactiveValue.new(42)
	assert_eq(rv.value, 42)

func test_reactive_value_set() -> void:
	var rv: Reactive = ReactiveValue.new(0)
	rv.value = 100
	assert_eq(rv.value, 100)
	
	rv.value = 10
	assert_eq(rv.value, 10)

func test_reactive_int_value_set() -> void:
	var rv: Reactive = ReactiveValue.Int(0)
	
	assert_true(rv.value is int)
	assert_eq(rv.value, 0)

func test_reactive_string_value_set() -> void:
	var rv: Reactive = ReactiveValue.String("")
	
	assert_true(rv.value is String)
	assert_eq(rv.value, "")

func test_reactive_bool_value_set() -> void:
	var rv: Reactive = ReactiveValue.Boolean(true)
	
	assert_true(rv.value is bool)
	assert_eq(rv.value, true)

func test_reactive_wrong_type_value_set() -> void:
	var rv: Reactive = ReactiveValue.Boolean(true)
	
	assert_true(rv.value is bool)
	assert_eq(rv.value, true)
	
	rv.value = ""
	rv.value = 1
	rv.value = false
	
	assert_push_error_count(2)
	assert_eq(rv.value, false) # Should not update the value
