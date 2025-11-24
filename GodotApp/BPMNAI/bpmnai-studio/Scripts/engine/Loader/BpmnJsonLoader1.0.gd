extends Node
class_name BpmnJsonLoaderV1

# Optional: Szenen-Caching
var _cache: Dictionary = {}

# ID → Node2D
var instance_map: Dictionary = {}

#
# ---------------------------------------------------------
#  PUBLIC API
# ---------------------------------------------------------
#
func load_bpmn_from_json(json_dict: Dictionary, parent_node: Node) -> Dictionary:

	instance_map.clear()

	if not json_dict.has("elements"):
		push_error("JSON contains no 'elements' array.")
		return instance_map

	var elements: Array = json_dict["elements"]

	# PHASE 1 – Instanzen erzeugen
	for e in elements:
		_instantiate_element(e, parent_node)

	# PHASE 2 – setup_from_element aufrufen
	for e in elements:
		var id: String = e.get("id", "")
		if id == "":
			continue
		var inst: Node = instance_map.get(id, null)
		if inst and inst.has_method("setup_from_element"):
			inst.call("setup_from_element", e)

	return instance_map



#
# ---------------------------------------------------------
#  PHASE 1 – Szene instanziieren
# ---------------------------------------------------------
#
func _instantiate_element(element: Dictionary, parent_node: Node) -> void:
	var t: String = element.get("type", "")
	var id: String = element.get("id", "")

	if id == "":
		push_warning("Skipping element without ID.")
		return

	var scene_path := _resolve_scene_path(t)
	if scene_path == "":
		push_warning("Unknown BPMN type: %s" % t)
		return

	var scene: PackedScene = _load_scene(scene_path)
	if scene == null:
		push_error("Cannot load scene: " + scene_path)
		return

	var inst: Node2D = scene.instantiate() as Node2D
	parent_node.add_child(inst)

	instance_map[id] = inst



#
# ---------------------------------------------------------
#  Szene-Pfad basierend auf Typ auswählen
# ---------------------------------------------------------
#
func _resolve_scene_path(t: String) -> String:

	# TASKS (alle Varianten)
	if t.begins_with("task"):
		return "res://Assets/bpmn/tasks/TaskNode2D.tscn"

	# GATEWAYS
	if t.ends_with("_gateway"):
		return "res://Assets/bpmn/gateways/GatewayNode2D.tscn"

	# EVENTS
	if t == "start_event":
		return "res://Assets/bpmn/events/StartEvent2D.tscn"

	if t == "end_event" or t == "end_error_event":
		return "res://Assets/bpmn/events/EndEvent2D.tscn"

	return ""


#
# ---------------------------------------------------------
#  Szenen-Caching
# ---------------------------------------------------------
#
func _load_scene(path: String) -> PackedScene:

	if _cache.has(path):
		return _cache[path]

	var s: PackedScene = load(path)
	if s:
		_cache[path] = s

	return s
