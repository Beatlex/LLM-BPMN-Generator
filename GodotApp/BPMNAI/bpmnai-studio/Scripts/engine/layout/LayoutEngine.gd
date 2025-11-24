extends Node

const NODE_SPACING_X := 450
const LANE_Y := 200
const LANE_SPACING_Y := 350

func apply_layout(node_map: Dictionary) -> void:
	var ordered_ids := _resolve_linear_order(node_map)

	var x_pos := 100
	for id in ordered_ids:
		var n: Node2D = node_map[id]
		if n:
			n.global_position = Vector2(x_pos, LANE_Y)
			x_pos += NODE_SPACING_X

	_apply_gateway_vertical_offsets(node_map)


# ---------------------------------------------------
# Y-Offset für Gateways
# ---------------------------------------------------
func _apply_gateway_vertical_offsets(node_map: Dictionary) -> void:
	for id in node_map.keys():
		var node = node_map[id]

		# Typ lesen
		var type: String = ""
		if node is Node and "element_type" in node:
			type = node.element_type

		# Nur Gateways
		if type != "exclusive_gateway" and type != "gateway":
			continue

		# flows_to lesen
		var flows_to: Array = []
		var raw = node.flows_to

		if typeof(raw) == TYPE_ARRAY:
			flows_to = raw
		elif typeof(raw) == TYPE_STRING:
			flows_to = [raw]

		if flows_to.size() <= 1:
			continue   # Kein Split → alles bleibt linear

		print("[LayoutEngine] Gateway %s hat %s Children" % [id, flows_to.size()])

		# Basisposition (von Gateway)
		var base_x = node.global_position.x + NODE_SPACING_X
		var base_y = node.global_position.y

		for i in range(flows_to.size()):
			var child_id = flows_to[i]

			if not node_map.has(child_id):
				continue

			var child = node_map[child_id]

			# X immer gleich für alle Zweige
			var new_x = base_x

			# Y verlagert nach Lane
			var new_y = base_y + (i * LANE_SPACING_Y)

			child.global_position = Vector2(new_x, new_y)

			print("[LayoutEngine]   Child %s → (%s, %s)" %
				  [child_id, new_x, new_y])

# ---------------------------------------------------
# Linear durch das Prozessmodell
# ---------------------------------------------------
func _resolve_linear_order(node_map: Dictionary) -> Array:
	var start_id := _find_start(node_map)
	if start_id == "":
		push_warning("LayoutEngine: No start_event found!")
		return node_map.keys()

	var order := []
	var current := start_id
	var visited := {}

	while current != "" and not visited.has(current):
		visited[current] = true
		order.append(current)

		var node = node_map[current]

		# flows_to existiert IMMER, da export var flows_to = []
		var raw = node.flows_to

		var flows: Array = []
		if typeof(raw) == TYPE_ARRAY:
			flows = raw
		elif typeof(raw) == TYPE_STRING:
			flows = [raw]
		else:
			flows = []

		current = flows[0] if flows.size() > 0 else ""

	return order


func _find_start(node_map: Dictionary) -> String:
	for id in node_map.keys():
		var n = node_map[id]
		if n.element_type == "start_event":
			return id
	return ""
