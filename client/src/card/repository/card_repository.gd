class_name CardRepository extends SQLRepository

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
	
func search_cards(params: Dictionary[String, Variant] = {}) -> Array[CardData]:
	var page_size: int = params.get("page_size", 20)
	var page: int = params.get("page", 1)
	var offset: int = (page - 1) * page_size

	var sort_column: String = params.get("sort_by", "name")
	var sort_direction: String = params.get("sort_order", "ASC")
	
	# White-list valid columns to prevent SQL injection in ORDER BY
	var valid_sort_cols: Array[String] = ["name", "manaValue", "rarity", "released_at", "edhrecRank"]
	if sort_column not in valid_sort_cols:
		sort_column = "name"
	
	var direction_str: String = "DESC" if sort_direction.to_upper() == "DESC" else "ASC"

	# Build Dynamic WHERE clause
	var conditions: Array[String] = []
	var query_params: Dictionary = {"limit": page_size, "offset": offset}

	# Filter out keys that aren't database columns
	var reserved_keys: Array[String] = ["page", "page_size", "sort_by", "sort_order"]

	for key: String in params:
		if key in reserved_keys or params[key] == null: 
			continue
		
		var value: Variant = params[key]
		if value is String:
			conditions.append("%s LIKE :%s" % [key, key])
			query_params[key] = "%%%s%%" % value
		else:
			conditions.append("%s = :%s" % [key, key])
			query_params[key] = value

	var where_clause: String = "WHERE " + " AND ".join(conditions) if conditions.size() > 0 else ""

	var query: String = """
        SELECT * FROM cards 
        %s 
        ORDER BY %s %s 
        LIMIT :limit OFFSET :offset
	""" % [where_clause, sort_column, direction_str]

	if not self._db.query_with_named_bindings(query, query_params):
		push_error("Error on searching cards")
		return []

	var result: Array[CardData] = []
	for data: Dictionary in self._db.query_result:
		result.append(CardData.Builder.new().from_dict(data).build())
		
	return result

func _escape_string(value: Variant) -> Variant:
	if !value or value is not String or value.is_empty():
		return null
	
	return "%%%s%%" % value
