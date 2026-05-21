class_name SQLRepository
extends Repository

const DEFAULT_PAGE_PARAMS : Dictionary[String, Variant] = {
	"page": 1,
	"page_size": 20
}

var _db: SQLite = null
var _is_open: bool = false

func open() -> Result:
	if _is_open:
		return Result.error(ERR_ALREADY_IN_USE)
	
	if !_db:
		return Result.error(ERR_CONNECTION_ERROR)
	
	if _db.path.strip_escapes().is_empty():
		return Result.error(ERR_INVALID_DATA)
	
	var isOpen : bool = _db.open_db()
	if !isOpen:
		return Result.error(ERR_ALREADY_IN_USE)
	
	_is_open = true
	return Result.Ok(_db)  

func close() -> Result:
	var success : bool = _db.close_db()
	if not success:
		return Result.error(ERR_BUSY)
	
	_is_open = false
	return Result.Ok(_db)

func _init(db: SQLite) -> void:
	_db = db
