extends Node

class_name NodeFactory

# Mapping element_type → Szene
const SCENES = {
	"start_event": preload("res://Assets/bpmn/events/StartEvent2D.tscn"),
	"task": preload("res://Assets/bpmn/tasks/TaskNode2D.tscn"),
	"end_event": preload("res://Assets/bpmn/events/EndEvent2D.tscn"),
	"exclusive_gateway": preload("res://Assets/bpmn/gateways/gateway_node_2d.tscn"),
	"inclusive_gateway": preload("res://Assets/bpmn/gateways/gateway_node_2d.tscn"),
	"parallel_gateway": preload("res://Assets/bpmn/gateways/gateway_node_2d.tscn")
}


func create_node(element: Dictionary) -> Node2D:
	var type = element.get("element_type", "")
	if not SCENES.has(type):
		push_error("NodeFactory: Unknown element_type: %s" % type)
		return null

	var scene = SCENES[type].instantiate()
	
	# Setup per Node-Typ
	if scene.has_method("setup_from_element"):
		scene.setup_from_element(element)
	else:
		push_error("NodeFactory: Scene has no setup_from_element(): %s" % type)

	return scene


func build_all(elements: Array) -> Dictionary:
	var nodes := {}
	for element in elements:
		var node = create_node(element)
		if node != null:
			#debuggen: random position zum Testen
			node.global_position = Vector2(
				randi_range(50, 800),
				randi_range(50, 500)
			)

			nodes[element["element_id"]] = node
	return nodes
