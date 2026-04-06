extends Node
class_name CardData

@export_category("Card Metadata")
@export_file_path(".jpg") var image_path: String = ""
@export var card_name: String = ""

func _init(card_name: String = "", image_path: String = "") -> void:
	self.card_name = card_name
	self.image_path = image_path

func with_image_path(image_path: String) -> CardData:
	self.image_path = image_path
	return self

func with_card_name(card_name: String) -> CardData:
	self.card_name = card_name
	return self

func random() -> CardData:
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
	
	image_path = printings_dir + "/" + jpg_files[0]
	card_name = jpg_files[0].get_basename()
	
	return self
