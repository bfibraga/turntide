extends Node
class_name CardController

@export var texture_rect : CardTexture

func set_printing(image_path: String) -> void:
	if image_path.is_empty():
		return
	
	var image : Image = Image.new()
	var err : Error = image.load(image_path)
	if err != OK:
		push_error("Failed to load card image: " + image_path)
		return
	
	texture_rect.texture = ImageTexture.create_from_image(image)

func set_selected(selected: bool) -> void:
	texture_rect.set_selected(selected)

func get_card_size() -> Vector2:
	return texture_rect.card_size
	
func get_hover_offset() -> Vector2:
	return texture_rect.hover_offset

func is_hovered() -> bool:
	return texture_rect.is_hovered if texture_rect else false

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
	
	self.set_printing(card_data.image_path)
	
