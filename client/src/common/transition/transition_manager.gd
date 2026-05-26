@icon("res://addons/icodot/node/office/icon-map.svg")
class_name TransitionManager extends Node

signal transition_completed
signal scene_instantiated(scene_instance: Node)

@export var content_container: Node = null

var _current_node: Node = null

@onready var color_rect: ColorRect = %ColorRect
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _init(container: Node = null) -> void:
	self.content_container = container

func _ready() -> void:
	if not content_container:
		push_error("TransitionManager: content node not set.")
		return
	
	color_rect.hide()
	
func transition_to(
	scene: PackedScene, 
	transition_in_animation: Animation, 
	transition_out_animation: Animation,
	parameters: Dictionary = {},
) -> void:
	if not scene:
		push_warning("transition_to() called with null scene. Aborting transition.")
		return
	
	await transition_in(transition_in_animation)
	
	_swap_scene(scene, parameters)
	
	await transition_out(transition_out_animation)
	
	transition_completed.emit()

func transition_in(animation: Animation) -> void:
	if not animation:
		push_warning("TransitionManager: no transition_in animation provided")
		return
	
	# Show the overlay
	color_rect.show()
	
	var animation_library : AnimationLibrary = animation_player.get_animation_library("")
	animation_library.add_animation("dynamic_in", animation)
	
	animation_player.play("dynamic_in")
	await animation_player.animation_finished

func transition_out(animation: Animation) -> void:
	if not animation:
		push_warning("TransitionManager: no transition_out animation provided")
		color_rect.hide()
		return
	
	var animation_library : AnimationLibrary = animation_player.get_animation_library("")
	animation_library.add_animation("dynamic_out", animation)
	
	animation_player.play_backwards("dynamic_out")
	await animation_player.animation_finished
	
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

## Verify if the [obj] has valid [code]_init[/code] method, in order to 
## initialize the target object.
func _has_valid_init_signature(obj: Object) -> bool:
	for method: Dictionary in obj.get_method_list():
		if method["name"] == "_init":
			var args: Array = method["args"]
			
			if args.size() == 1:
				var first_arg: Dictionary = args[0]
				
				if first_arg["type"] == TYPE_DICTIONARY:
					return true
					
	return false
