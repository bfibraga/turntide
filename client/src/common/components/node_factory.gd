extends Node

func create_format_dropdown(
	label_opt: Option,
	on_item_selected: Callable = func() -> void: pass, 
	formats: Array[BaseFormat] = [],
) -> Control:
	var container: VBoxContainer = VBoxContainer.new()
	
	# Label Node
	if label_opt.is_some():
		var label: Label = Label.new()
		label.text = label_opt.unwrap()
	
		container.add_child(label)
	
	# Dropdown Node
	var option_button: OptionButton = OptionButton.new()
	option_button.add_item("Any", 0)
		
	var index: int = 1
	for format: BaseFormat in formats:
		option_button.add_item(format.display_name(), index)
		index += 1

	option_button.item_selected.connect(on_item_selected.bind(formats))
	container.add_child(option_button)
	
	return container
