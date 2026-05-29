class_name MemoryRepository extends Repository

@warning_ignore("unused_private_class_variable")
var _data: Dictionary[StringName, Variant] = {}

func open() -> Result:
	return Result.Ok(true)

func close() -> Result:
	return Result.Ok(true)
