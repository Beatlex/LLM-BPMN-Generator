extends Node
class_name FlowConnectionHandler

@export var flow_scene: PackedScene


func connect_flows(nodes: Dictionary) -> Array:
	var flow_instances: Array = []

	# ----------------------------------------------------------
	# 0) Fallback laden, falls keine Scene gesetzt wurde
	# ----------------------------------------------------------
	if flow_scene == null:
		print("[FlowHandler] WARN: flow_scene=null → Lade Fallback FlowLine2D.tscn...")
		flow_scene = load("res://Assets/bpmn/nodes/FlowLine2D.tscn")
		if flow_scene == null:
			push_error("[FlowHandler] FATAL: FlowLine2D.tscn konnte nicht geladen werden!")
			return flow_instances

	print("[FlowHandler] Starte Flow-Verarbeitung…")

	# ----------------------------------------------------------
	# 1) Über alle Nodes iterieren
	# ----------------------------------------------------------
	for id in nodes.keys():
		var src = nodes[id]

		# Prüfen ob Node Ausgänge hat
		if not src.has_method("get_output_ports"):
			continue

		# flows_to direkt lesen (export Variable)
		var flows_to: Array = []
		var raw = src.flows_to

		match typeof(raw):
			TYPE_ARRAY:
				for e in raw:
					flows_to.append(String(e))
			TYPE_STRING:
				flows_to = [String(raw)]
			_:
				continue

		if flows_to.is_empty():
			continue

		# ------------------------------------------------------
		# 2) Gateway erkennen
		# ------------------------------------------------------
		var element_type: String = ""
		if "element_type" in src:
			element_type = String(src.element_type)

		var is_gateway := false
		# für: "exclusive_gateway", "parallel_gateway"
		if element_type == "gateway" or element_type.ends_with("_gateway"):
			is_gateway = true
		# ------------------------------------------------------
		# 3) Für jeden Ausgang einen Flow erzeugen
		# ------------------------------------------------------
		for idx in range(flows_to.size()):
			var target_id: String = flows_to[idx]

			if not nodes.has(target_id):
				push_warning("[FlowHandler] Ziel '%s' nicht gefunden!" % target_id)
				continue

			var dst = nodes[target_id]

			if not dst.has_method("get_input_ports"):
				push_warning("[FlowHandler] Ziel '%s' hat keine get_input_ports()" % target_id)
				continue

			# Flow instanzieren
			var flow = flow_scene.instantiate()
			if flow == null:
				push_error("[FlowHandler] Flow konnte nicht instanziert werden!")
				continue

			# Ports ermitteln
			var src_ports: Array = src.get_output_ports()
			var dst_ports: Array = dst.get_input_ports()

			if src_ports.is_empty() or dst_ports.is_empty():
				push_warning("[FlowHandler] Port fehlt bei %s → %s" % [id, target_id])
				continue

			# ------------------------------------------------------
			# Gateway-Routing:
			# idx = 0 → rechter Ausgang → route_type = 0
			# idx = 1 → unterer Ausgang → route_type = 1
			# ------------------------------------------------------
			var src_port_index := 0
			if is_gateway:
				src_port_index = min(idx, src_ports.size() - 1)

			var src_port = src_ports[src_port_index]
			var dst_port = dst_ports[0]

			var route_type := 0       # default: horizontal
			if is_gateway:
				if src_port_index == 1:
					route_type = 2  # Port oben
				elif src_port_index == 2:
					route_type = 1  # Port unten

			# Flow einrichten
			if flow.has_method("setup"):
				flow.setup(src_port, dst_port, route_type)

			flow_instances.append(flow)

	return flow_instances
