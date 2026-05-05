class_name JSONDirectoryRepository
extends DirectoryRepository

func _serialize(file: FileAccess, data: Dictionary) -> void:
	var content: String = JSON.stringify(data, "\t")
	file.store_string(content)
	
func _deserialize(file: FileAccess) -> Variant:
	var json: JSON = JSON.new()
	var content: String = file.get_as_text()
	var error: Error = json.parse(content)
	
	if error != OK:
		push_error("Cannot deserialize json: ", content)
		return null
	
	return json.data
	
