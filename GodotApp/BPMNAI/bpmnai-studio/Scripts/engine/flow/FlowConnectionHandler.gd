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

		var src_type := ""
		if "element_type" in src:
			src_type = str(src.element_type)

		var is_gateway_src := src_type.ends_with("_gateway") or src_type == "gateway"
		var src_ports: Array = src.get_output_ports()
		var branch_count := outs.size()

		# Gateway-Label nur für PARALLEL (AND)
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

			# ---------- BACKFLOW-ERKENNUNG FEHLERHAFT ----------
			var is_backflow = dst.global_position.x <= src.global_position.x

			# Split / Merge nur wenn KEIN Backflow
			var is_split = branch_count > 1 and not is_backflow
			var is_merge = _incoming_count(target_id, nodes) > 1 and not is_backflow

			var dst_type := ""
			if "element_type" in dst:
				dst_type = str(dst.element_type)

			var is_gateway_dst := dst_type.ends_with("_gateway") or dst_type == "gateway"

			var src_port_index := 0
			var route_type := 0

			# BACKFLOW: eigene Route, KEINE Gateway-Logik Nicht final implementiert
			if is_backflow:
				# immer mittlerer Ausgang, eigener Routentyp
				src_port_index = min(1, src_ports.size() - 1)
				route_type = 99

			elif is_split and is_gateway_src:

				var mid := int(floor(branch_count / 2.0))

				# PARALLEL (AND)
				if src_type == "parallel_gateway":

					# 1 Branch → Mitte
					if branch_count == 1:
						src_port_index = 1
						route_type = 0

					# 2 Branches → Top / Bottom
					elif branch_count == 2:
						if i == 0:
							src_port_index = 0   # Top
							route_type = 2
						else:
							src_port_index = 2   # Bottom
							route_type = 1

					# 3 Branches → Top / Mid / Bottom
					elif branch_count == 3:
						match i:
							0:
								src_port_index = 0
								route_type = 2
							1:
								src_port_index = 1
								route_type = 0
							2:
								src_port_index = 2
								route_type = 1

					# >3 Branches
					else:
						# Ungerade → genau eine Mitte
						if (branch_count % 2 == 1) and (i == mid):
							src_port_index = 1
							route_type = 0
						# obere Hälfte
						elif i < mid:
							src_port_index = 0
							route_type = 2
						# untere Hälfte
						else:
							src_port_index = 2
							route_type = 1

				elif src_type == "exclusive_gateway" or src_type == "inclusive_gateway":
					# XOR / OR Regeln:
					# 1 → Mitte
					# 2 → Mitte + Unten
					# 3 → Oben + Mitte + Unten

					if branch_count == 1:
						src_port_index = 0   # Mitte
						route_type = 0

					elif branch_count == 2:
						if i == 0:
							src_port_index = 0   # Mitte
							route_type = 0
						else:
							src_port_index = 1   # Unten
							route_type = 1

					else: # 3
						match i:
							0:
								src_port_index = 0   # Oben
								route_type = 2
							1:
								src_port_index = 1   # Mitte
								route_type = 0
							2:
								src_port_index = 2   # Unten
								route_type = 1



			# MERGE-LOGIK (nur AND-Gateway)
			elif is_merge and is_gateway_dst and dst_type == "parallel_gateway":

				var incoming_order := _sorted_incoming(target_id, nodes)
				var branch_index := incoming_order.find(id)
				if branch_index == -1:
					branch_index = 0

				var incoming_count := incoming_order.size()
				var mid := int(floor(incoming_count / 2.0))

				# Default: erster Input-Port (falls get_merge_ports fehlt)
				var chosen_dst_port: Node2D = dst_port

				if dst.has_method("get_merge_ports"):
					var merge_ports: Array = dst.get_merge_ports()
					if merge_ports.size() >= 3:
						var top_port: Node2D = merge_ports[0]
						var mid_port: Node2D = merge_ports[1]
						var bot_port: Node2D = merge_ports[2]

						# ---- Regelwerk:
						# 1  Mitte
						# 2  oben/unten
						# 3  oben/mitte/unten
						# >3  oben/unten erweitern; Mitte nur bei ungerade und exakt mid
						if incoming_count == 1:
							chosen_dst_port = mid_port
						elif incoming_count == 2:
							chosen_dst_port = top_port if branch_index == 0 else bot_port
						elif incoming_count == 3:
							chosen_dst_port = top_port if branch_index == 0 else (mid_port if branch_index == 1 else bot_port)
						else:
							if (incoming_count % 2 == 1) and (branch_index == mid):
								chosen_dst_port = mid_port
							elif branch_index < mid:
								chosen_dst_port = top_port
							else:
								chosen_dst_port = bot_port

						dst_port = chosen_dst_port

				# Routing: immer sauber "seitlich rein" (kein diagonales Direct-Line)
				src_port_index = 0
				route_type = 3

			# Gateway mit nur einem Ausgang
			elif is_gateway_src and not is_split:
				if src_type == "parallel_gateway":
					src_port_index = min(1, src_ports.size() - 1)
				else:
					src_port_index = 0
				route_type = 0

			# Normaler Task-Flow
			else:
				src_port_index = min(i, src_ports.size() - 1)
				route_type = 0

			# ---------- Flow erzeugen ----------
			src_port_index = clamp(src_port_index, 0, src_ports.size() - 1)
			var src_port: Node2D = src_ports[src_port_index]

			var flow = flow_scene.instantiate()
			if flow and flow.has_method("setup"):
				flow.setup(src_port, dst_port, route_type)

			flows.append(flow)

	return flows


# ==========================================================
# Helper
# ==========================================================
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
		if not nodes.has(a) or not nodes.has(b):
			return false
		return nodes[a].global_position.y < nodes[b].global_position.y
	)

	return arr
