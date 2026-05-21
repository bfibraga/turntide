@abstract class_name Repository
extends RefCounted

@abstract func open() -> Result

@abstract func close() -> Result

func _exit_tree() -> void:
	#var error : Error = self.close()
	#if error != null:
		#push_error("Error on closing repository ", self.name, ", reason: ", error)
	
	var result: Result = self.close()
	if result.is_err():
		push_error("Error on closing repository ", self.name, ", reason: ", result)
