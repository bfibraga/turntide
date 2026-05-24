@tool @icon("res://addons/icodot/ui/games/icon-card-back-dark-ui.svg")
class_name CardUI extends Node

class Data extends Reactive:
	var card_data: ReactiveValue = ReactiveValue.new(
		CardData.new(),
		self
	)
	var key: ComputedReactiveValue = ComputedReactiveValue.new(
		func() -> String: 
			var data: CardData = card_data.value
			return Global.printings_manager._make_key(
				data.uuid,
				data.setCode, 
				data.number,
			),
		[card_data],
		self
	)
	var printing: ReactiveObject = ReactiveObject.new(
		preload("res://assets/card/back/back_card.png"),
		self
	)

var data: Data = Data.new()

@onready var view: CardView2 = %View

func _init(card_data: CardData = CardData.new()) -> void:
	data.card_data.value = card_data

func _ready() -> void:
	data.reactive_changed.connect(func(reactive: Data) -> void:
		view.front_art = reactive.printing.value
	)
	
	Global.printings_manager.card_printing_ready.connect(func(key: String, path: String) -> void:
		if key == data.key.value:
			_start_async_texture_load(path)
	)
	
	view.tap_card.connect(func() -> void: print("Tapping"))
	view.flip_card.connect(func() -> void: print("Flipping"))
	
	view.gui_input.connect(func(event: InputEvent) -> void:
		if view.is_mouse_entered:
			if event.is_action_pressed("tap_card"):
				view.tap_card.emit()
			
			if event.is_action_pressed("flip_card"):
				view.flip_card.emit()
	
			if event.is_action_pressed("ui_left"):
				print("Selected card %s" % data.card_data.value.name)
			
			if event is InputEventMouseMotion:
				view.follow()
	)
	
	var info: Dictionary = Global.printings_manager.get_card_info(data.key.value)
	
	if info.status == "ready":
		_start_async_texture_load(info.path)
	else:
		Global.printings_manager.request_download(data.card_data.value)
			
		
	data.manually_emit()


func _start_async_texture_load(path: String) -> void:
	# Even if it's on disk, Image.load_from_file is slow. Do it in a worker.
	WorkerThreadPool.add_task(func() -> void: 
		if not FileAccess.file_exists(path):
			push_error("Image file does not exist: ", path)
			return

		set_printing.call_deferred(path)
	)

func set_printing(printing_path: String) -> void:
	if printing_path.strip_edges().is_empty():
		push_warning("Setting empty printing path to card node ", self.name)
		return
	
	var image : Image = Image.new()
	var err : int = image.load(printing_path)
	if err != OK:
		push_error("Failed to load card image: ", printing_path, " error: ", err )
		return
	
	data.printing.value = ImageTexture.create_from_image(image)
