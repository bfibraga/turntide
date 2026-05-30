class_name CardContainerManager extends Node

@export var snap_threshold: float = 250.0 # Pixels

var available_containers: Dictionary[StringName, CardContainer] = {}

func register_container(container: CardContainer) -> void:
	available_containers[container.name] = container

func unregister_container(container: CardContainer) -> void:
	available_containers.erase(container.name)

func find_nearest(from: Vector2, for_card: Card, threshold: float = snap_threshold) -> CardContainer:
	var nearest: CardContainer = null
	var nearest_dist: float = INF
	
	for c: CardContainer in available_containers.values():
		if not c.can_accept_card(for_card):
			continue
		
		var center: Vector2 = c.get_global_rect().get_center()
		var dist: float = from.distance_to(center)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = c
	
	if nearest and nearest_dist <= threshold:
		return nearest
	
	return null
