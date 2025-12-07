extends Node
class_name LayoutHandler

const H_SPACING := 400.0
const V_SPACING := 300.0
const POOL_OFFSET := 800.0

var _node_map: Dictionary
var _layer_map: Dictionary
var _visited: Dictionary

func route_between_ports(source_node: Node2D, source_port: Area2D, target_node: Node2D, target_port: Area2D) -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(source_port.global_position)
	points.append(target_port.global_position)
	return points

func apply_layout(all_nodes: Array) -> void:
	_node_map = {}
	var layer_map = assign_layers(all_nodes)
	var lane_map = assign_lanes(all_nodes)
	
	print("\n--- LAYER MAP ---")
	for node in layer_map.keys():
		print("Node ID:", node.element_id, "→ Layer:", layer_map[node])
		print("\n--- LANE MAP ---")
		
	for node in lane_map.keys():
			print("Node ID:", node.element_id, "→ Lane Index:", lane_map[node])
	for node in all_nodes:
		if "element_id" in node:
			_node_map[node.element_id] = node

	_layer_map = {}
	_visited = {}


	calculate_positions(layer_map, lane_map)

#Layer-Zuweisung
func assign_layers(all_nodes: Array) -> Dictionary:

	for node in all_nodes:
		print("TYPE CHECK:", node, typeof(node))
		if node.element_type == "start_event":
			dfs(node, 0)
			
	for node in all_nodes:
		if not _visited.has(node) and "flows_to" in node:
			dfs(node, 0)


	return _layer_map


func dfs(n, depth):
	print("[DFS] Visiting:", n.element_id, " | depth:", depth)

	if _visited.has(n):
		_layer_map[n] = max(_layer_map[n], depth)
		return

	_visited[n] = true
	_layer_map[n] = depth

	if not ("flows_to" in n):
		print("[DFS] Kein flows_to für:", n.element_id)
		return

	print("[DFS] → flows_to:", n.flows_to)

	for target_id in n.flows_to:
		if not _node_map.has(target_id):
			print("[DFS] ⚠ Ziel nicht gefunden:", target_id)
			continue
		dfs(_node_map[target_id], depth + 1)

# 2. Lane-Zuweisung
func assign_lanes(all_nodes: Array) -> Dictionary:
	var lane_map := {}
	var lane_indices := {}
	var current_index := 0

	for node in all_nodes:
		var key = node.pool_id + ":" + node.lane_id
		if not lane_indices.has(key):
			lane_indices[key] = current_index
			current_index += 1
		lane_map[node] = lane_indices[key]

	return lane_map

# 3. Positionierung
func calculate_positions(layer_map: Dictionary, lane_map: Dictionary) -> void:
	for node in lane_map.keys():
		var layer = layer_map.get(node, 0)
		var lane_index = lane_map[node]

		var x = 100.0 + layer * H_SPACING
		var y = 200.0 + lane_index * V_SPACING
		
		print("Placing Node:", node.element_id, "→ x:", x, "y:", y)

		node.position = Vector2(x, y)
