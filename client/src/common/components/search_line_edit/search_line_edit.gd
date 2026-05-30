class_name SearchLineEdit extends LineEdit

signal executed_search(text: String)
signal execute_search_empty_query

@export var delay_time: float = 0.5

var _search_timer: Timer = Timer.new()

func _ready() -> void:
	_search_timer.one_shot = true
	_search_timer.wait_time = delay_time
	
	text_changed.connect(_on_text_changed)
	
	text_submitted.connect(_execute_search.bind(text))
	_search_timer.timeout.connect(_execute_search)
	
	self.add_child(_search_timer)

func _on_text_changed(_new_text: String) -> void:
	_search_timer.stop()
	_search_timer.start(delay_time)
	
func _execute_search() -> void:
	var query : String = text.strip_edges()
	
	if query.is_empty():
		execute_search_empty_query.emit()
	else:
		executed_search.emit(query)
