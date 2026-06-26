class_name URL
extends RefCounted

var _scheme: String = ""
var _host: String = ""
var _port: int = -1
var _path_parts: Array[String] = []
var _query_params: Dictionary = {}

func scheme(value: String) -> URL:
	_scheme = value
	return self

func host(value: String) -> URL:
	_host = value
	return self

func port(value: int) -> URL:
	_port = value
	return self

func path(segment: String) -> URL:
	if segment.is_empty():
		return self
	var cleaned := segment.trim_prefix("/")
	_path_parts.append(cleaned)
	return self

func query(key: String, value: String) -> URL:
	_query_params[key] = value
	return self

func build() -> String:
	var result := ""
	
	if not _scheme.is_empty():
		result += _scheme + "://"
	
	if not _host.is_empty():
		result += _host
	
	if _port > 0:
		result += ":" + str(_port)
	
	if not _path_parts.is_empty():
		result += "/" + "/".join(_path_parts)
	
	if not _query_params.is_empty():
		var pairs: Array[String] = []
		for key in _query_params:
			var encoded_key := _url_encode(str(key))
			var encoded_value := _url_encode(str(_query_params[key]))
			pairs.append(encoded_key + "=" + encoded_value)
		result += "?" + "&".join(pairs)
	
	return result

func _url_encode(text: String) -> String:
	var encoded := ""
	var valid_chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
	for i in text.length():
		var char := text[i]
		if char in valid_chars:
			encoded += char
		else:
			encoded += "%%%02X" % char.unicode_at(0)
	return encoded

func _to_string() -> String:
	return build()

func _eq(other) -> bool:
	if other is URL:
		return build() == other.build()
	elif other is String:
		return build() == other
	return false

func _hash() -> int:
	return build().hash()

static func ws() -> URL:
	return URL.new().scheme("ws")

static func wss() -> URL:
	return URL.new().scheme("wss")

static func http() -> URL:
	return URL.new().scheme("http")

static func https() -> URL:
	return URL.new().scheme("https")
