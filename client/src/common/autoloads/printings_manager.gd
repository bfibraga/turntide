class_name PrintingsManager extends Node

signal card_printing_ready(key: String, path: String)

const IMAGES_PATH: String = "user://cache/images/"
const TRACKER_FILE: String = "user://cache/printings.json"
#const DB_PATH: String = CardRepository.DEFAULT_DB_PATH
const MAX_CONCURRENT_DOWNLOADS: int = 10

#const _ScryfallProvider = preload("res://src/common/download/providers/scryfall.gd")
#const _MTGJSONProvider = preload("res://src/common/download/providers/mtgjson.gd")

var _registry: Dictionary = {}
var _registry_mutex: Mutex = Mutex.new()
var _pending_downloads: Array[Dictionary] = []
var _active_requests: int = 0

func _init() -> void:
	load_tracker()
	DirAccess.make_dir_recursive_absolute(IMAGES_PATH)
	#ensure_db_ready()

func get_card_info(key: String) -> Dictionary:
	_registry_mutex.lock()
	var data: Dictionary = _registry.get(key, {"status": "missing"}).duplicate(true)
	_registry_mutex.unlock()
	return data

func is_downloaded(key: String) -> bool:
	return get_card_info(key).status == "ready"

func request_download(card_data: CardData) -> void:
	var key: String = _make_key(
		card_data.uuid,
		card_data.setCode,
		card_data.number
	)

	if is_downloaded(key):
		card_printing_ready.emit(key, get_card_info(key).path)
		return

	_pending_downloads.append({
		"card_data": card_data,
		"key": key,
	})
	_process_queue()

func _process_queue() -> void:
	while _active_requests < MAX_CONCURRENT_DOWNLOADS and not _pending_downloads.is_empty():
		var job: Dictionary = _pending_downloads.pop_front()
		_start_image_download(job.card_data as CardData, job.key as String)

func _start_image_download(card_data: CardData, key: String) -> void:
	_active_requests += 1

	var image_path: String = get_image_path(card_data)
	var url: String = ScryfallProvider.build_image_url(card_data.scryfallId)

	#http.download_file = ProjectSettings.globalize_path(image_path)
	#http.request_completed.connect(
		#_on_image_downloaded.bind(http, card_data, key, image_path)
	#)
	#http.request(url)
	
	HttpRequestManager.request(
		func(http: HTTPRequest) -> void:
			http.download_file = ProjectSettings.globalize_path(image_path),
		func(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
			_active_requests -= 1

			if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
				push_error("Failed to download image for %s: result=%d, http=%d" % [card_data.name, result, response_code])
				_process_queue()
				return

			_registry_mutex.lock()
			_registry[key] = {
				"path": image_path,
				"status": "ready",
				"timestamp": Time.get_unix_time_from_system(),
			}
			_registry_mutex.unlock()

			card_printing_ready.emit(key, image_path)
			save_tracker.call_deferred()
			_process_queue(),
		url
	)

#func _on_image_downloaded(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest, card_data: CardData, key: String, image_path: String) -> void:
	#_active_requests -= 1
	#http.queue_free()
#
	#if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		#push_error("Failed to download image for %s: result=%d, http=%d" % [card_data.name, result, response_code])
		#_process_queue()
		#return
#
	#_registry_mutex.lock()
	#_registry[key] = {
		#"path": image_path,
		#"status": "ready",
		#"timestamp": Time.get_unix_time_from_system(),
	#}
	#_registry_mutex.unlock()
#
	#card_printing_ready.emit(key, image_path)
	#save_tracker.call_deferred()
	#_process_queue()

func _make_key(uuid: String, setcode: String, num: String) -> String:
	return "%s_%s_%s" % [uuid, setcode, num]

func get_image_path(card_data: CardData) -> String:
	var filename: String = ScryfallProvider.build_image_filename(
		card_data.name, card_data.setCode, card_data.uuid
	)
	return ProjectSettings.globalize_path(IMAGES_PATH + filename)

func save_tracker() -> void:
	_registry_mutex.lock()
	var f: FileAccess = FileAccess.open(TRACKER_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_registry))
	_registry_mutex.unlock()

func load_tracker() -> void:
	if FileAccess.file_exists(TRACKER_FILE):
		var f: FileAccess = FileAccess.open(TRACKER_FILE, FileAccess.READ)
		if f:
			var json: Variant = JSON.parse_string(f.get_as_text())
			if json:
				_registry = json
