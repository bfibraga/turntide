class_name SQLRepository
extends Repository

const DEFAULT_PAGE_PARAMS : Dictionary[String, Variant] = {
	"page": 1,
	"page_size": 20
}

var _db: SQLite = null
var _is_open: bool = false

func open() -> Error:
	if _is_open:
		return OK
	
	if !_db:
		return Error.ERR_CONNECTION_ERROR
	
	if _db.path.strip_escapes().is_empty():
		return Error.ERR_INVALID_DATA
	
	var isOpen : bool = _db.open_db()
	if !isOpen:
		return Error.ERR_ALREADY_IN_USE
	
	_is_open = true
	return OK  

func close() -> Error:
	var success : bool = _db.close_db()
	if not success:
		return Error.ERR_BUSY
	
	_is_open = false
	return OK

func _init(db: SQLite) -> void:
	_db = db
