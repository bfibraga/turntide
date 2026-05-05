@abstract class_name Repository
extends RefCounted

@abstract func open() -> Error

@abstract func close() -> Error

func _exit_tree() -> void:
	var error : Error = self.close()
	if error != null:
		push_error("Error on closing repository ", self.name, ", reason: ", error)
