extends GutTest

func test_card_data_creation() -> void:
	var metadata = CardMetadata.new("uuid1", "Lightning Bolt", "LEA", "1")
	var card_data = CardData.new(metadata)
	
	assert_not_null(card_data)
	assert_eq(card_data.metadata.name, "Lightning Bolt")
	assert_eq(card_data.metadata.uuid, "uuid1")

func test_card_data_is_reactive() -> void:
	var metadata = CardMetadata.new("uuid1", "Test Card", "TST", "1")
	var card_data = CardData.new(metadata)
	
	assert_true(card_data is Reactive)

var _test_signal_flag: bool = false

func test_reactive_signal_emits() -> void:
	var metadata = CardMetadata.new("uuid1", "Test Card", "TST", "1")
	var card_data = CardData.new(metadata)
	
	_test_signal_flag = false
	card_data.reactive_changed.connect(_on_reactive_changed)
	card_data.manually_emit()
	
	assert_true(_test_signal_flag)

func _on_reactive_changed(_r: Reactive) -> void:
	_test_signal_flag = true