@icon("res://addons/icodot/ui/office/icon-map-ui.svg")
class_name TransitionManager
extends Node

signal transition_completed
signal scene_instantiated(scene_instance: Node)

@export var target_node_name: String = "ContentContainer"
@export var content_container: Node = null

var _current_node: Node = null

@onready var color_rect: ColorRect = %ColorRect
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _init(container: Node = null) -> void:
	self.content_container = container

func _ready() -> void:
	if not content_container:
		call_deferred("find_content_container")
		

func find_content_container() -> void:
	var root: Node = get_tree().root
	var containers: Array = root.find_children(target_node_name, "", true, false)

	if containers.is_empty():
		return

	var deepest: Node = null
	var max_depth: int = -1

	for node: Node in containers:
		var depth: int = node.get_path().get_name_count()
		if depth > max_depth:
			max_depth = depth
			deepest = node

	content_container = deepest

func transition_to(
	scene: PackedScene, 
	transition_in_name: String = "fade", 
	transition_out_name: String = "fade",
	parameters: Dictionary = {},
) -> void:
	# Validate scene
	if not scene:
		push_warning("transition_to() called with null scene. Aborting transition.")
		return
	
	# Play transition in (hide current scene)
	await transition_in(transition_in_name)
	
	# Swap the scene while hidden
	_swap_scene(scene, parameters)
	
	# Play transition out (reveal new scene)
	await transition_out(transition_out_name)
	
	# Signal completion
	transition_completed.emit()

func transition_in(animation: String = "fade") -> void:
	print("IN: %s" % animation)
	
	# Show the overlay
	color_rect.show()
	
	# Play the animation
	if not animation_player.has_animation(animation):
		push_warning("Animation '%s' not found. Using 'fade' as fallback." % animation)
		animation = "fade"
	
	animation_player.play(animation)
	await animation_player.animation_finished

func transition_out(animation: String = "fade") -> void:
	print("OUT: %s" % animation)
	
	# Check if animation exists, fall back if not
	if not animation_player.has_animation(animation):
		push_warning("Animation '%s' not found. Using 'fade' as fallback." % animation)
		animation = "fade"
	
	# Play animation backwards (revealing overlay)
	animation_player.play_backwards(animation)
	await animation_player.animation_finished
	
	# Hide the overlay when done
	color_rect.hide()

func _swap_scene(scene: PackedScene, parameters: Dictionary = {}) -> void:
	if not content_container:
		get_tree().change_scene_to_packed(scene)
		return
		
	if not scene:
		return
	
	var new_scene: Node = scene.instantiate()
	
	if new_scene.has_method("_init"):
		if _has_valid_init_signature(new_scene):
			new_scene.call("_init", parameters)
		else:
			push_warning("Method 'init' found on %s, but signature does not match 'init(parameters: Dictionary)'" % new_scene.name)
	
	if is_instance_valid(_current_node):
		_current_node.queue_free()
	
	content_container.add_child(new_scene)
	_current_node = new_scene
	
	scene_instantiated.emit(new_scene)

func _has_valid_init_signature(obj: Object) -> bool:
	for method: Dictionary in obj.get_method_list():
		if method["name"] == "_init":
			var args: Array = method["args"]
			
			if args.size() == 1:
				var first_arg: Dictionary = args[0]
				
				if first_arg["type"] == TYPE_DICTIONARY:
					return true
					
	return false
