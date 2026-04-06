class_name CardRepository
extends Repository

const _table_name : String = "cards"
const DEFAULT_DB_PATH : String = "res://../shared/resources/cards.db"

func count_cards() -> int:
	var query : String = "SELECT COUNT(*) FROM %s;" % _table_name
	
	var success : bool = self._db.query_with_bindings(query, [])
	if !success:
		push_error("Card Count not successfull!")
		return 0
	
	var result : int = self._db.query_result.get(0).get("COUNT(*)", 0)
	print(result)
	
	return result
	
const DEFAULT_SEARCH_CARD_PARAMS : Dictionary[String, Variant] = {
	"name": null,
	"setcode": null,
	"type": null,
}

func search_cards(
	params: Dictionary[String, Variant] = {}
) -> Array[CardMetadata]:
	var search_params : Dictionary[String, Variant] = DEFAULT_SEARCH_CARD_PARAMS.duplicate(true)
	search_params.merge(DEFAULT_PAGE_PARAMS)
	search_params.merge(params, true)
	
	var limit: int = search_params.get("page_size", 1)
	var offset: int = (search_params.get("page", 1) - 1) * limit

	var query: String = """
	SELECT * FROM {0}
	WHERE 1=1
		AND (:name is NULL OR name LIKE :name)
		AND (:setcode IS NULL OR setcode = :setcode)
	ORDER BY {0}.name ASC
	LIMIT :limit 
	OFFSET :offset
	;
	""".format([_table_name])

	var query_params : Dictionary[String, Variant] = {
		"name": _escape_string(search_params.get("name")),
		"setcode": _escape_string(search_params.get("setcode")),
		"limit": limit,
		"offset": offset,
	}
	
	var success : bool = self._db.query_with_named_bindings(query, query_params)
	if !success:
		push_error("Card Search not successfull!")
		return []
		
	var result : Array[CardMetadata] = []
	for data : Dictionary in self._db.query_result:
		print("Data: ", data)
		var metadata : CardMetadata = CardMetadata.from_dict(data)
		result.append(metadata)
		
	return result

func _escape_string(value: Variant) -> Variant:
	if !value or value is not String or value.is_empty():
		return null
	
	return "%%%s%%" % value
