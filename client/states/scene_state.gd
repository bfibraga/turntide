class_name SceneHolderState extends State

@export var packed_scene: PackedScene
@export var transition_manager: TransitionManager

var _scene_instance: Node = null

func enter() -> void:
	enter_scene()

func enter_scene() -> void:
	if !packed_scene:
		push_error("Packed scene not registered in state %s" % self.Name())
		return

	var tm: TransitionManager = transition_manager if transition_manager else Global.transition_manager
	if tm:
		if not tm.scene_instantiated.is_connected(_on_scene_instantiated):
			tm.scene_instantiated.connect(_on_scene_instantiated)
		tm.transition_to(packed_scene)
	else:
		push_error("No TransitionManager found for state %s" % self.Name())

func _on_scene_instantiated(scene_instance: Node) -> void:
	if _scene_instance and _scene_instance.has_signal("transition_requested"):
		if _scene_instance.transition_requested.is_connected(_on_transition_requested):
			_scene_instance.transition_requested.disconnect(_on_transition_requested)
	
	_scene_instance = scene_instance
	
	if scene_instance.has_signal("transition_requested"):
		scene_instance.transition_requested.connect(_on_transition_requested)

func _on_transition_requested(state_name: String) -> void:
	Transitioned.emit(self, state_name)

func exit() -> void:
	if _scene_instance and _scene_instance.has_signal("transition_requested"):
		if _scene_instance.transition_requested.is_connected(_on_transition_requested):
			_scene_instance.transition_requested.disconnect(_on_transition_requested)
	_scene_instance = null
	
	var tm: TransitionManager = transition_manager if transition_manager else Global.transition_manager
	if tm and tm.scene_instantiated.is_connected(_on_scene_instantiated):
		tm.scene_instantiated.disconnect(_on_scene_instantiated)
