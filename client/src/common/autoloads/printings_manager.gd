class_name PrintingsManager extends Node

signal card_printing_ready(key: String, path: String)

const IMAGES_PATH: String = "user://cache/images/"
const TRACKER_FILE: String = "user://cache/printings.json"
const DB_PATH: String = "user://cache/database/cards.db"

var _registry: Dictionary = {}
var _registry_mutex: Mutex = Mutex.new()

func _ready() -> void:
	load_tracker()
	DirAccess.make_dir_recursive_absolute(IMAGES_PATH)

## --- THREAD-SAFE ACCESSORS ---

func get_card_info(key: String) -> Dictionary:
	_registry_mutex.lock()
	var data: Dictionary = _registry.get(key, {"status": "missing"}).duplicate(true)
	_registry_mutex.unlock()
	return data

func is_downloaded(key: String) -> bool:
	return get_card_info(key).status == "ready"

## --- THE CLI EXECUTION PIPELINE ---

var _active_fetcher: FetcherCLI = null

func request_download(card_data: CardData) -> void:
	var key: String = _make_key(
		card_data.uuid, 
		card_data.setCode, 
		card_data.number
	)
	
	if is_downloaded(key):
		card_printing_ready.emit(key, get_card_info(key).path)
		return
	
	# Create a NEW instance per request to avoid argument pollution
	var fetcher: FetcherCLI = FetcherCLI.new()
	_active_fetcher = fetcher  # Keep alive until callback
	
	# Connect to the CLIWrapper signal
	fetcher.task_finished.connect(
		_on_fetcher_finished.bind(card_data, fetcher)
	)
	
	# Build and Run
	fetcher.images()\
		.db_path(DB_PATH)\
		.output_dir(IMAGES_PATH)\
		.card(card_data)\
		.run()

func _on_fetcher_finished(_output: Array, exit_code: int, card_data: CardData, _fetcher: FetcherCLI) -> void:
	_active_fetcher = null  # Release reference
	
	if exit_code != 0:
		push_error("FetcherCLI failed for card %s, error code: %d" % [card_data.name, exit_code])
		return
	
	# Use WorkerThreadPool to process the "Post-Download" logic
	# This keeps the main thread free for rendering/input
	WorkerThreadPool.add_task(_process_completed_download.bind(card_data))

func _process_completed_download(card_data: CardData) -> void:
	var path: String = get_image_path(card_data)
	var key: String = _make_key(
		card_data.uuid,
		card_data.setCode, 
		card_data.number
	)
	
	_registry_mutex.lock()
	_registry[key] = {
		"path": path,
		"status": "ready",
		"timestamp": Time.get_unix_time_from_system()
	}
	_registry_mutex.unlock()
	
	# Notify any CardView nodes that the image is now on disk
	card_printing_ready.emit.call_deferred(key, path)
	
	save_tracker.call_deferred()

## --- DATA HELPERS ---

func _make_key(uuid: String, setcode: String, num: String) -> String:
	return "%s_%s_%s" % [uuid, setcode, num]

func get_image_path(card_data: CardData) -> String:
	var filename : String = "%s_%s_%s.jpg" % [
		card_data.name.replace(" ", "_"), 
		card_data.setCode, 
		card_data.uuid.substr(0, 8)
	]
	
	return ProjectSettings.globalize_path(IMAGES_PATH + filename)

func save_tracker() -> void:
	_registry_mutex.lock()
	var f: FileAccess = FileAccess.open(TRACKER_FILE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(_registry))
	_registry_mutex.unlock()

func load_tracker() -> void:
	if FileAccess.file_exists(TRACKER_FILE):
		var f: FileAccess = FileAccess.open(TRACKER_FILE, FileAccess.READ)
		var json: Variant = JSON.parse_string(f.get_as_text())
		if json: 
			_registry = json

func ensure_db_ready() -> void:
	if not FileAccess.file_exists(DB_PATH):
		DirAccess.make_dir_recursive_absolute("user://cache/database")
		
		var fetcher_cli : FetcherCLI = FetcherCLI.new() 
		
		fetcher_cli.download() \
		.db_path(DB_PATH) \
		.run()
