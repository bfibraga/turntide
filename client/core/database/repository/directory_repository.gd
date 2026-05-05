@abstract class_name DirectoryRepository
extends Repository

var _directory_path: String
var _extension_name: String
var _is_open: bool = false 

func _init(path: String, extension_name: String) -> void:
	_directory_path = ProjectSettings.globalize_path(path)
	_extension_name = extension_name

# Implementation of the abstract open method
func open() -> Error:
	var dir : DirAccess = DirAccess.open(_directory_path)
	if not dir:
		# Attempt to create the directory if it doesn't exist
		var err : Error = DirAccess.make_dir_recursive_absolute(_directory_path)
		if err != OK:
			return err
	
	_is_open = true
	return OK

# Implementation of the abstract close method
func close() -> Error:
	_is_open = false
	return OK

@abstract func _serialize(file: FileAccess, data: Dictionary) -> void

@abstract func _deserialize(file: FileAccess) -> Variant

func save_data(filename: String, data: Dictionary) -> Error:
	if not _is_open: return ERR_CANT_OPEN
	
	var full_path = _directory_path.path_join(filename + _extension_name)
	var file: FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
	
	if not file: return FileAccess.get_open_error()
	
	_serialize(file, data) # Call the specific implementation
	return OK

func load_data(filename: String) -> Variant:
	if not _is_open: return null
	
	var full_path = _directory_path.path_join(filename + _extension_name)
	if not FileAccess.file_exists(full_path): return null
		
	var file: FileAccess = FileAccess.open(full_path, FileAccess.READ)
	return _deserialize(file) # Call the specific implementation

func list() -> PackedStringArray:
	var dir : DirAccess = DirAccess.open(_directory_path)
	if not dir: return []
		
	var ids : PackedStringArray = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(_extension_name):
			ids.append(file_name.replace(_extension_name, ""))
		file_name = dir.get_next()
	return ids

## Checks if a specific data key (filename) exists
func exists(filename: String) -> bool:
	var global_filepath: String = ProjectSettings.globalize_path(filename)

	return FileAccess.file_exists(global_filepath)

## Deletes a specific JSON file
func delete(filename: String) -> Error:
	if not exists(filename):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(filename)

## Wipes the entire repository (Deletes all files in the directory)
func clear_all() -> void:
	for filepath: String in list():
		delete(filepath)
