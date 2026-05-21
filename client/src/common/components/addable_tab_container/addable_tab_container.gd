class_name AddableTabContainer extends TabContainer

signal added_tab(tab: Control)
signal removed_tab(tab: Control)

var reserved_items: Dictionary[String, Control] = {}
var closable_items: Dictionary[String, Control] = {}

func _ready() -> void:
	for child: Control in self.get_children():
		if child.has_meta("closable"):
			closable_items.set(child.name, child)
		else:
			reserved_items.set(child.name, child)

func add_tab(tab_node: Control) -> void:
	tab_node.set_meta("closable", true)
	
	self.add_child(tab_node)
	
	closable_items.set(tab_node.name, tab_node)
	
	added_tab.emit(tab_node)

func remove_tab(tab_name: String) -> void:
	var tab_option: Option = self.find_tab(tab_name)
	
	if tab_option.is_none():
		return
	
	var tab_node: Control = tab_option.unwrap()
		
	tab_node.queue_free()
	
	await tab_node.tree_exited
	closable_items.erase(tab_name)
	
	removed_tab.emit(tab_node)

func find_tab(tab_name: String) -> Option:
	return Option.new(closable_items.get(tab_name))

func focus_tab(tab_name: String) -> void:
	var tab_option: Option = self.find_tab(tab_name)
	
	if tab_option.is_none():
		return
	
	var tab_node: Control = tab_option.unwrap()
	
	tab_node.visible = true
