extends Node
class_name FlowConnectionHandler

@export var flow_scene: PackedScene


# ======================================================
#              SPLIT / MERGE ERKENNUNG
# ======================================================
func _is_split(node) -> bool:
	return node.flows_to.size() > 1


func _is_merge(node_id:String, nodes:Dictionary) -> bool:
	var incoming := 0
	for other_id in nodes.keys():
		if nodes[other_id].flows_to.has(node_id):
			incoming += 1
	return incoming > 1


# ======================================================
#                FLOW RENDERING (SMART)
# ======================================================
func connect_flows(nodes: Dictionary) -> Array:
	var flows: Array = []

	if flow_scene == null:
		print("[FlowHandler ⚠] fallback → FlowLine2D loaded")
		flow_scene = load("res://Assets/bpmn/nodes/FlowLine2D.tscn")


	print("\n═══════ FLOW ROUTING START ═══════")

	for id in nodes.keys():
		var src = nodes[id]
		if not src.has_method("get_output_ports"):
			continue

		# --- flows_to normalisieren ---
		var outs:Array = []
		match typeof(src.flows_to):
			TYPE_ARRAY: outs = src.flows_to
			TYPE_STRING: outs = [src.flows_to]
		if outs.is_empty(): continue

		# --- NodeTyp bestimmen ---
		var is_gateway = false
		if "element_type" in src:
			var t=str(src.element_type)
			is_gateway = (t.ends_with("_gateway") or t=="gateway")

		var src_ports:Array = src.get_output_ports()

		# ======================================================
		#   FLOW GENERIEREN
		# ======================================================
		for i in range(outs.size()):
			var target = String(outs[i])
			if not nodes.has(target): continue
			var dst = nodes[target]
			if not dst.has_method("get_input_ports"): continue

			var flow = flow_scene.instantiate()
			var dst_port = dst.get_input_ports()[0]  # BPMN hat 1 Eingang

			# ======================================================
			# SMART-Portwahl
			# ======================================================
			var src_port_index = 0

			if is_gateway:
				var branch = outs.size()

				match branch:

					1:  # Default linear
						src_port_index = 0

					2:  # Rechts + Unten
						src_port_index = i  # 0 → rechts | 1 → unten

					3:  # Top + Right + Bottom
						src_port_index = i  # 0=top 1=mid 2=bottom

					_:
						src_port_index = i % src_ports.size()

			src_port_index = clamp(src_port_index,0,src_ports.size()-1)
			var src_port = src_ports[src_port_index]

			# ======================================================
			# ROUTING-LOGIK (NEU, BPMN-KORREKT)
			# ======================================================
			var route_type = 0  # Standard: horizontal

			var is_split = _is_split(src)
			var is_merge = _is_merge(target,nodes)

			if is_split:
				# ------------------ GATEWAY SPLIT ------------------
				# Expand → zuerst auf Task-Y-Level dann in X
				if src_port_index == 0: route_type = 0  # Mid-Right
				if src_port_index == 1: route_type = 2  # TOP-Branch
				if src_port_index == 2: route_type = 1  # BOTTOM-Branch

			elif is_merge:
				# ------------------ GATEWAY MERGE ------------------
				# sammelt ein → erst X→Gateway dann Y zentriert
				route_type = 3      # neuer smarter Merge-Routing Mode

			flow.setup(src_port,dst_port,route_type)
			flows.append(flow)

	return flows
