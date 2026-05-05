extends LineEdit

func _ready() -> void:
	#self.editable = is_open()
	pass

func is_open() -> bool:
	return Global.client_id >= 0
	
