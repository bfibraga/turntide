class_name CardView extends Control

var metadata: CardMetadata

@onready var card_texture: CardTexture = $SubViewportContainer/SubViewport/TextureRect

func _init(card_metadata: CardMetadata = null) -> void:
	metadata = card_metadata

func _ready() -> void:
	if not metadata: return
	
	# 1. Check if manager already has it
	var key : String = Global.printings_manager._make_key(metadata.uuid, metadata.setcode, metadata.number)
	var info : Dictionary = Global.printings_manager.get_card_info(key)
	
	# 2. Connect to signal for future updates
	Global.printings_manager.card_printing_ready.connect(_on_image_became_available)
	
	if info.status == "ready":
		_start_async_texture_load(info.path)
	else:
		self.modulate = Color(0.3, 0.3, 0.3) # Darken while loading
		Global.printings_manager.request_download(metadata)
	
func _on_image_became_available(key: String, path: String) -> void:
	var my_key : String = Global.printings_manager._make_key(metadata.uuid, metadata.setcode, metadata.number)
	if key == my_key:
		_start_async_texture_load(path)

func _start_async_texture_load(path: String) -> void:
	# Even if it's on disk, Image.load_from_file is slow. Do it in a worker.
	WorkerThreadPool.add_task(func() -> void: 
		if not FileAccess.file_exists(path):
			push_error("Image file does not exist: ", path)
			return

		set_printing.call_deferred(path)
	)
		

func set_printing(image_path: String) -> void:
	if image_path.strip_edges().is_empty():
		return
	
	var image : Image = Image.new()
	var err : Error = image.load(image_path)
	if err != OK:
		push_error("Failed to load card image: ", image_path, " error: ", err )
		return
	
	card_texture.texture = ImageTexture.create_from_image(image)

func set_selected(selected: bool) -> void:
	card_texture.set_selected(selected)
