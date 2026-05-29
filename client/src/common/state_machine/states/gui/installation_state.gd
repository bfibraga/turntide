class_name InstallationState
extends SceneHolderState

static func Name() -> String:
	return "Installation"

@onready var logger: Log = Global.logger

var _http_request: HTTPRequest = null
var _installation_scene = null
var _downloading: bool = false
var _db_path: String = CardRepository.DEFAULT_DB_PATH

func enter(data: Dictionary = {}) -> void:
	if FileAccess.file_exists(_db_path):
		logger.info("Card database found at %s" % _db_path)
		_open_and_transition()
		return

	logger.info("Card database not found, starting download...")
	_downloading = true
	can_transition_away = false

	transition_manager.scene_instantiated.connect(_on_scene_instantiated)
	super.enter(data)
	_start_download()

func exit() -> void:
	super.exit()
	if transition_manager.has_connections("scene_instantiated"):
		transition_manager.scene_instantiated.disconnect(_on_scene_instantiated)
	_installation_scene = null
	_http_request = null

func update(_delta: float) -> void:
	if not _downloading or not _http_request or not is_instance_valid(_http_request):
		return

	var downloaded: int = _http_request.get_downloaded_bytes()
	var total: int = _http_request.get_body_size()

	if not _installation_scene:
		return

	if total > 0:
		var progress: float = float(downloaded) / float(total)
		_installation_scene.set_progress(progress)
		_installation_scene.set_status("Downloading... %s / %s" % [_format_bytes(downloaded), _format_bytes(total)])
	else:
		_installation_scene.set_progress(-1.0)
		_installation_scene.set_status("Downloading... %s" % _format_bytes(downloaded))

func _on_scene_instantiated(scene_instance: Node) -> void:
	_installation_scene = scene_instance
	if _installation_scene and _installation_scene.has_signal("retry_pressed"):
		_installation_scene.retry_pressed.connect(_on_retry)
		_installation_scene.set_status("Downloading card database...")

func _start_download() -> void:
	var db_dir: String = _db_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(db_dir)

	_http_request = HttpRequestManager.request(
		func(h: HTTPRequest) -> void:
			var download_path: String = ProjectSettings.globalize_path(_db_path)
			h.download_file = download_path
			h.timeout = 0.0,
		_on_download_complete,
		MTGJSONProvider.get_download_url()
	)

func _on_download_complete(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_http_request = null

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		logger.error("Failed to download card database: result=%d, http=%d" % [result, response_code])
		_show_download_error()
		return

	logger.success("Card database downloaded successfully")
	_open_and_transition()

func _open_and_transition() -> void:
	var result: Result = Global.card_repository.open()
	if result.is_err():
		logger.error("Failed to open card database")
		if _installation_scene:
			_installation_scene.show_error("Failed to open card database: %s" % result.message())
		return

	can_transition_away = true
	Transitioned.emit(self, LoginState.Name())

func _show_download_error() -> void:
	if _installation_scene:
		_installation_scene.show_error("Download failed. Please check your connection and try again.")

func _on_retry() -> void:
	if _installation_scene:
		_installation_scene.show_downloading()
		_installation_scene.set_status("Retrying download...")
	can_transition_away = false
	_start_download()

static func _format_bytes(bytes: int) -> String:
	if bytes < 1024:
		return "%d B" % bytes
	elif bytes < 1024 * 1024:
		return "%.1f KB" % (float(bytes) / 1024.0)
	else:
		return "%.1f MB" % (float(bytes) / (1024.0 * 1024.0))
