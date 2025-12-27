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


func _apply_gateway_vertical_offsets(node_map: Dictionary) -> void:
	for id in node_map.keys():
		var gw = node_map[id]

		# element_type sicher lesen
		if !("element_type" in gw):
			continue
		var type: String = String(gw.element_type)

		if !type.ends_with("_gateway"):
			continue

		var raw = gw.flows_to
		var flows_to: Array = []
		if typeof(raw) == TYPE_ARRAY:
			for e in raw:
				flows_to.append(String(e))
		elif typeof(raw) == TYPE_STRING:
			flows_to = [String(raw)]

		var count := flows_to.size()
		if count <= 1:
			continue

		print("\n[LayoutEngine] Gateway", id, "→", count, "Branches")

		var base_x = gw.global_position.x + NODE_SPACING_X
		var base_y = gw.global_position.y
		var mid = floor(count / 2.0)

		for i in range(count):
			var child_id = flows_to[i]
			if not node_map.has(child_id):
				continue

			var child = node_map[child_id]

			var x = base_x
			var y = base_y

			match count:
				1:
					y = base_y
				2:
					if type == "exclusive_gateway" or type == "inclusive_gateway":
						# XOR / OR → Mitte + Unten
						y = base_y if i == 0 else base_y + LANE_SPACING_Y
					else:
						# AND → Oben + Unten
						y = base_y + (-LANE_SPACING_Y / 2 if i == 0 else LANE_SPACING_Y / 2)
				3:
					# alle Gateways → Oben / Mitte / Unten
					y = base_y + (i - 1) * LANE_SPACING_Y

				_:
	# >= 4 Branches
					if count % 2 == 0:
						# GERADE Anzahl (4,6,8…)
						# → KEINE Mitte, symmetrisch um base_y
						# Index wird bewusst um 0.5 verschoben
						var half := count / 2
						var offset := (i - half) + 0.5
						y = base_y + offset * LANE_SPACING_Y
					else:
						# UNGERADE Anzahl (5,7,9…)
						# → EINE echte Mitte
						y = base_y + (i - mid) * LANE_SPACING_Y

			child.global_position = Vector2(x, y)
			print("[LayoutEngine]   Child %s → (%s, %s)" %
				[child_id, x, y])

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
