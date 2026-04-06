class_name CardController
extends Node

@export_category("Card components")
@export var view: CardView

func load_random_image() -> void:
	var printings_dir: String = "../shared/resources/printings"

	var dir: DirAccess = DirAccess.open(printings_dir)
	if dir == null:
		push_error("Failed to open printings directory: " + printings_dir)
		return

	var jpg_files: PackedStringArray = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".jpg") or file_name.ends_with(".jpeg"):
			jpg_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if jpg_files.is_empty():
		push_error("No jpg files found in printings directory")
		return

	var shuffled: Array = Array(jpg_files)
	shuffled.shuffle()
	jpg_files = PackedStringArray(shuffled)
	
	var card_data : CardData = CardData.new()
	card_data.image_path = printings_dir + "/" + jpg_files[0]
	card_data.card_name = jpg_files[0].get_basename()
	
	print(card_data.image_path)
	
	view.set_printing(card_data.image_path)
	
