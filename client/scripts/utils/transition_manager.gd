class_name TransitionManager extends Node

signal transition_completed
signal scene_instantiated(scene_instance: Node)

@export var content_container: Node

func _ready() -> void:
	if not content_container:
		call_deferred("_find_content_container")

func _find_content_container() -> void:
	var root: Node = get_tree().root
	var containers: Array = root.find_children("ContentContainer", "", true, false)

	if containers.is_empty():
		return

	var deepest: Node = null
	var max_depth: int = -1

	for node in containers:
		var depth: int = node.get_path().get_name_count()
		if depth > max_depth:
			max_depth = depth
			deepest = node

	content_container = deepest

func transition_to(scene: PackedScene) -> void:
	_swap_scene(scene)
	transition_completed.emit()

func _swap_scene(scene: PackedScene) -> void:
	if not content_container:
		get_tree().change_scene_to_packed(scene)
		return
	var new_scene = scene.instantiate()
	content_container.add_child(new_scene)
	scene_instantiated.emit(new_scene)
	for child in content_container.get_children():
		if child != new_scene:
			child.queue_free()
