class_name Config extends Node

var config_file: ConfigFile = ConfigFile.new()

func put(path: String, value: Variant) -> Config:
	var stripped: PackedStringArray = path.split(".")
	
	if stripped.size() < 2:
		push_warning("Invalid path format. Expected 'section.key', got: %s" % path)
		return self
	
	var section: String = stripped[0]
	var key: String = stripped[1]
	
	config_file.set_value(section, key, value)
	
	return self

func load(path: String) -> Result:
	var error: int = config_file.load(path)
	
	return Result.from_gderr(error)

func save(path: String) -> Result:
	var error: int = config_file.save(path)
	
	return Result.from_gderr(error)
	
