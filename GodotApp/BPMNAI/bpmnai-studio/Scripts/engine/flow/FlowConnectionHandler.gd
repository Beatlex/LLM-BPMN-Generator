extends Node
class_name FlowConnectionHandler

@export var flow_scene: PackedScene


func connect_flows(nodes: Dictionary) -> Array:
	var flows: Array = []

	if flow_scene == null:
		flow_scene = load("res://Assets/bpmn/nodes/FlowLine2D.tscn")

	for id in nodes.keys():
		var src = nodes[id]
		if not src.has_method("get_output_ports"):
			continue

		var outs: Array = _sorted_children(src, nodes)
		if outs.is_empty():
			continue

		var src_type: String = ""
		if "element_type" in src:
			src_type = str(src.element_type)

		var is_gateway_src: bool = src_type.ends_with("_gateway") or src_type == "gateway"
		var src_ports: Array = src.get_output_ports()
		var branch_count: int = outs.size()

		if is_gateway_src and src_type == "parallel_gateway":
			var is_split_gateway := branch_count > 1
			var is_merge_gateway := _incoming_count(id, nodes) > 1

			if src.has_method("apply_gateway_label_logic"):
				src.apply_gateway_label_logic(is_split_gateway, is_merge_gateway)


		for i in range(branch_count):
			var target_id = outs[i]
			if not nodes.has(target_id):
				continue

			var dst = nodes[target_id]
			if not dst.has_method("get_input_ports"):
				continue

			var dst_ports: Array = dst.get_input_ports()
			if dst_ports.is_empty():
				continue
			var dst_port: Node2D = dst_ports[0] 

			var is_split := branch_count > 1
			var is_merge := _incoming_count(target_id, nodes) > 1

			var dst_type: String = ""
			if "element_type" in dst:
				dst_type = str(dst.element_type)
			var is_gateway_dst: bool = dst_type.ends_with("_gateway") or dst_type == "gateway"

			var src_port_index := 0
			var route_type := 0

			if is_split and is_gateway_src:

				if src_type == "parallel_gateway" and branch_count == 3:
					match i:
						0:
							# oberer Task 
							src_port_index = 0
							route_type     = 2
						1:
							# mittlerer Task 
							src_port_index = 1
							route_type     = 0
						2:
							# unterer Task
							src_port_index = 2
							route_type     = 1

				# --- XOR-Split mit 2 Branches (Mid + Bottom) ---
				elif src_type == "exclusive_gateway" and branch_count == 2:
					if i == 0:
						src_port_index = 0    # Mid
						route_type     = 0    # horizontal
					else:
						src_port_index = 2    # Bottom
						route_type     = 1    # ↓ →

				# --- generischer Fallback ---
				else:
					src_port_index = min(i, src_ports.size() - 1)
					match src_port_index:
						0: route_type = 0     # Mitte
						1: route_type = 2     # Top
						2: route_type = 1     # Bottom

			elif is_merge and is_gateway_dst and dst_type == "parallel_gateway":

				# Eingehende Branches nach Y sortieren (oben/mid/unten)
				var incoming_order = _sorted_incoming(target_id, nodes)
				var branch_index = incoming_order.find(id)
				if branch_index == -1:
					branch_index = 1   

				# Input-Port des Gateways nutzen
				if dst.has_method("get_merge_ports"):
					var merge_ports: Array = dst.get_merge_ports()
					if branch_index < merge_ports.size():
						dst_port = merge_ports[branch_index]

				# Quelle IMMER Task-Output
				src_port_index = 0

				# Route-Typen:
				# 0 = XOR / normal
				# 1 = Split bottom
				# 2 = Split top
				# 3 = Merge top/bottom 
				# 4 = Merge Mitte 
				if branch_index == 1:
					route_type = 4      # Mitte -> horizontaler Merge
				else:
					route_type = 3      # Top oder Bottom -> vertikaler Merge

			elif is_gateway_src and not is_split:
				if src_type == "parallel_gateway":
					src_port_index = min(1, src_ports.size() - 1)   # Mid/X
				else:
					# XOR mit einem Ausgang -> Mitte reicht
					src_port_index = 0
				route_type = 0

			else:
				src_port_index = min(i, src_ports.size() - 1)
				route_type = 0

			# --- Flow erzeugen ---
			src_port_index = clamp(src_port_index, 0, src_ports.size() - 1)
			var src_port: Node2D = src_ports[src_port_index]

			var flow = flow_scene.instantiate()
			if flow and flow.has_method("setup"):
				flow.setup(src_port, dst_port, route_type)

			flows.append(flow)

	return flows

# Helper
func _incoming_count(id: String, nodes: Dictionary) -> int:
	var c := 0
	for k in nodes.keys():
		var n = nodes[k]
		if not ("flows_to" in n):
			continue
		if typeof(n.flows_to) == TYPE_ARRAY and n.flows_to.has(id):
			c += 1
		elif typeof(n.flows_to) == TYPE_STRING and n.flows_to == id:
			c += 1
	return c


func _sorted_children(src, nodes: Dictionary) -> Array:
	if not ("flows_to" in src):
		return []

	if typeof(src.flows_to) == TYPE_STRING:
		return [src.flows_to]

	if typeof(src.flows_to) != TYPE_ARRAY:
		return []

	var arr: Array = src.flows_to.duplicate()
	arr.sort_custom(func(a, b):
		return nodes[a].global_position.y < nodes[b].global_position.y
	)
	return arr


func _sorted_incoming(target_id: String, nodes: Dictionary) -> Array:
	var arr: Array = []
	for k in nodes.keys():
		var n = nodes[k]
		if not ("flows_to" in n):
			continue
		if typeof(n.flows_to) == TYPE_ARRAY and n.flows_to.has(target_id):
			arr.append(k)
		elif typeof(n.flows_to) == TYPE_STRING and n.flows_to == target_id:
			arr.append(k)

	arr.sort_custom(func(a, b):
		return nodes[a].global_position.y < nodes[b].global_position.y
	)
	return arr
