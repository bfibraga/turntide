@abstract class_name Repository
extends RefCounted

const DEFAULT_PAGE_PARAMS : Dictionary[String, Variant] = {
	"page": 1,
	"page_size": 20
}

var _db: SQLite = null

func open() -> Error:
	if !_db:
		return Error.ERR_CONNECTION_ERROR
	
	if _db.path.strip_escapes().is_empty():
		return Error.ERR_INVALID_DATA
	
	var isOpen : bool = _db.open_db()
	
	return OK if isOpen else Error.ERR_ALREADY_IN_USE 

func close() -> Error:
	var success : bool = _db.close_db()
	return OK if success else Error.ERR_BUSY

func _init(db: SQLite) -> void:
	_db = db

func _exit_tree() -> void:
	var error : Error = self.close()
	if error != null:
		push_error("Error on closing repository ", self.name, ", reason: ", error)
