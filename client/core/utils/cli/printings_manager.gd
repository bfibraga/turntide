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
	var data = _registry.get(key, {"status": "missing"}).duplicate(true)
	_registry_mutex.unlock()
	return data

func is_downloaded(key: String) -> bool:
	return get_card_info(key).status == "ready"

## --- THE CLI EXECUTION PIPELINE ---

var _active_fetcher: FetcherCLI = null

func request_download(metadata: CardMetadata) -> void:
	var key = _make_key(metadata.uuid, metadata.setcode, metadata.number)
	
	if is_downloaded(key):
		card_printing_ready.emit(key, get_card_info(key).path)
		return
	
	# Create a NEW instance per request to avoid argument pollution
	var fetcher: FetcherCLI = FetcherCLI.new()
	_active_fetcher = fetcher  # Keep alive until callback
	
	# Connect to the CLIWrapper signal
	fetcher.task_finished.connect(
		_on_fetcher_finished.bind(metadata, fetcher)
	)
	
	# Build and Run
	fetcher.images() \
		.db_path(DB_PATH) \
		.output_dir(IMAGES_PATH) \
		.card(metadata) \
		.run()

func _on_fetcher_finished(_output: Array, exit_code: int, metadata: CardMetadata, fetcher: FetcherCLI) -> void:
	_active_fetcher = null  # Release reference
	
	if exit_code != 0:
		push_error("FetcherCLI failed for card %s, error code: %d" % [metadata.name, exit_code])
		return
	
	# Use WorkerThreadPool to process the "Post-Download" logic
	# This keeps the main thread free for rendering/input
	WorkerThreadPool.add_task(_process_completed_download.bind(metadata))

func _process_completed_download(metadata: CardMetadata) -> void:
	var path = get_image_path(metadata)
	var key = _make_key(metadata.uuid, metadata.setcode, metadata.number)
	
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

func get_image_path(card: CardMetadata) -> String:
	var filename : String = "%s_%s_%s.jpg" % [card.name.replace(" ", "_"), card.setcode, card.uuid.substr(0, 8)]
	#var filename : String = "%s.jpg" %[card.uuid]
	
	return ProjectSettings.globalize_path(IMAGES_PATH + filename)

func save_tracker():
	_registry_mutex.lock()
	var f = FileAccess.open(TRACKER_FILE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(_registry))
	_registry_mutex.unlock()

func load_tracker():
	if FileAccess.file_exists(TRACKER_FILE):
		var f = FileAccess.open(TRACKER_FILE, FileAccess.READ)
		var json = JSON.parse_string(f.get_as_text())
		if json: 
			_registry = json

func ensure_db_ready() -> void:
	if not FileAccess.file_exists(DB_PATH):
		DirAccess.make_dir_recursive_absolute("user://cache/database")
		
		var fetcher_cli : FetcherCLI = FetcherCLI.new() 
		
		fetcher_cli.download() \
		.db_path(DB_PATH) \
		.run()
	
# ========

#func load_tracker() -> void:
	#if not FileAccess.file_exists(TRACKER_FILE):
		#return
	#
	#var file : FileAccess = FileAccess.open(TRACKER_FILE, FileAccess.READ)
	#if file == null:
		#push_warning("Failed to open tracker file, starting fresh")
		#return
	#
	#var json_string : String = file.get_as_text()
	#file.close()
	#
	#var json : JSON = JSON.new()
	#var error : Error = json.parse(json_string)
	#if error != OK:
		#push_warning("Tracker JSON corrupted, starting fresh")
		#return
	#
	#var data: Dictionary = json.get_data()
	#if data.is_empty():
		#return
	#
	#_printings = data
#
#func save_tracker() -> void:
	#var json_string : String = JSON.stringify(_printings, "  ")
	#
	#var temp_file : String = TRACKER_FILE + ".tmp"
	#var file : FileAccess = FileAccess.open(temp_file, FileAccess.WRITE)
	#if file == null:
		#push_error("Failed to write temp tracker file")
		#return
	#
	#file.store_string(json_string)
	#file.close()
	#
	#var dir : DirAccess = DirAccess.open("user://cache/")
	#if dir == null:
		#push_error("Failed to open user cache directory")
		#return
	#
	#var err : Error = dir.rename(temp_file, TRACKER_FILE)
	#if err != OK:
		#push_error("Failed to rename temp tracker file")
#
#func is_downloaded(uuid: String, setcode: String, number: String) -> bool:
	#var key : String = _make_key(uuid, setcode, number)
	#return _printings.has(key)
#
#func _make_key(uuid: String, setcode: String, number: String) -> String:
	#return "%s_%s_%s" % [uuid, setcode, number]
#
#func get_needed(printings: Array[CardMetadata]) -> Array[CardMetadata]:
	#var needed: Array[CardMetadata] = []
	#for card: CardMetadata in printings:
		#if not is_downloaded(card.uuid, card.setcode, card.number):
			#needed.append(card)
	#return needed
#
#func ensure_db_ready() -> void:
	#if not FileAccess.file_exists(DB_PATH):
		#DirAccess.make_dir_recursive_absolute("user://cache/database")
		#_fetcher_cli.download().db_path(DB_PATH).run()
#
#func queue_download(metadata: CardMetadata, card_view: CardView) -> void:
	#if is_downloaded(metadata.uuid, metadata.setcode, metadata.number):
		#card_view.set_printing(get_image_path(metadata))
		#download_progress.emit(metadata.name, "cached")
		#return
	#
	#_download_queue.append({
		#"metadata": metadata,
		#"card": card_view
	#})
	#download_progress.emit(metadata.name, "queued")
#
#func download_queued() -> void:
	#if _download_queue.is_empty() or _is_downloading:
		#return
	#
	#var needed: Array[CardMetadata] = []
	#for item: Dictionary in _download_queue:
		#needed.append(item["metadata"])
	#
	#var to_download : Array[CardMetadata] = get_needed(needed)
	#if to_download.is_empty():
		#_download_queue.clear()
		#download_completed.emit(true, "All printings already downloaded")
		#return
	#
	#_is_downloading = true
	#DirAccess.make_dir_recursive_absolute(IMAGES_PATH)
	#
	#_fetcher_cli.images() \
		#.db_path(DB_PATH) \
		#.output_dir(IMAGES_PATH) \
		#.card_list(to_download) \
		#.run()
	#
	#_fetcher_cli.task_finished.connect(_on_download_finished.bind(to_download))
#
#func download(printings: Array[CardMetadata]) -> void:
	#var needed : Array[CardMetadata] = get_needed(printings)
	#if needed.is_empty():
		#download_completed.emit(true, "All printings already downloaded")
		#return
	#
	#DirAccess.make_dir_recursive_absolute(IMAGES_PATH)
	#
	#_fetcher_cli.images() \
		#.db_path(DB_PATH) \
		#.output_dir(IMAGES_PATH) \
		#.card_list(needed) \
		#.run()
	#
	#_fetcher_cli.task_finished.connect(_on_download_finished.bind(needed))
#
#func _on_download_finished(output: Array[String], exit_code: int, downloaded: Array[CardMetadata]) -> void:
	#_fetcher_cli.task_finished.disconnect(_on_download_finished)
	#_is_downloading = false
	#
	#for card: CardMetadata in downloaded:
		#var key := _make_key(card.uuid, card.setcode, card.number)
		#var image_path := ProjectSettings.globalize_path(get_image_path(card))
		#_printings[key] = {
			#"path": image_path,
			#"downloaded_at": Time.get_datetime_string_from_system(true),
			#"format": "png"
		#}
		#
		#for item: Dictionary in _download_queue:
			#if item["metadata"].uuid == card.uuid and item["metadata"].setcode == card.setcode:
				#item["card"].set_printing(image_path)
				#_download_queue.erase(item)
				#break
	#
	#_save_counter += 1
	#if _save_counter >= SAVE_INTERVAL:
		#save_tracker()
		#_save_counter = 0
	#
	#if exit_code != 0:
		#push_error("Download failed with exit code: ", exit_code)
		#download_completed.emit(false, "Download failed: " + str(exit_code))
	#else:
		#download_completed.emit(true, "Downloaded %d printings" % downloaded.size())
		#
		#if not _download_queue.is_empty():
			#download_queued()
#
#func get_image_path(card: CardMetadata) -> String:
	#var filename := "%s_%s_%s.png" % [card.name.replace(" ", "_"), card.setcode, card.uuid.substr(0, 8)]
	#print("filename: ", filename)
	#return IMAGES_PATH + filename
#
#func rebuild() -> void:
	#_printings.clear()
	#
	#if not DirAccess.dir_exists_absolute(IMAGES_PATH):
		#return
	#
	#var dir := DirAccess.open(IMAGES_PATH)
	#if dir == null:
		#return
	#
	#dir.list_dir_begin()
	#var filename := dir.get_next()
	#while filename != "":
		#if filename.ends_with(".png") or filename.ends_with(".jpg") or filename.ends_with(".webp"):
			#var parts := filename.split("_")
			#if parts.size() >= 3:
				#var uuid := parts[parts.size() - 2]
				#var setcode := parts[parts.size() - 3]
				#var key := _make_key(uuid, setcode, "")
				#_printings[key] = {
					#"path": IMAGES_PATH + filename,
					#"downloaded_at": "rebuilt",
					#"format": filename.get_extension()
				#}
		#filename = dir.get_next()
	#dir.list_dir_end()
	#
	#save_tracker()
#
#func clear() -> void:
	#_printings.clear()
	#save_tracker()
#
#func _exit_tree() -> void:
	#save_tracker()
