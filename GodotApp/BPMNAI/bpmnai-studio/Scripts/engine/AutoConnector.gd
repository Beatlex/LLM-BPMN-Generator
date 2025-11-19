extends Node

# Muss per setget gesetzt werden oder in _ready() assigned werden.
var renderer_root: Node = null

var layout_engine: Node = null
var flow_scene: PackedScene = preload("res://Assets/bpmn/nodes/FlowLine2D.tscn")


func setup(root: Node, layout: Node):
	renderer_root = root
	layout_engine = layout


func auto_connect_to_end_event(all_nodes: Array):
	if renderer_root == null:
		push_error("AutoConnector: renderer_root ist null!")
		return

	# ---------------------------------------------------------
	# 1) Existierenden EndEvent suchen
	# ---------------------------------------------------------
	var end_event: Node = null
	for n in all_nodes:
		if "get_input_ports" in n and n.get_output_ports().size() == 0:
			end_event = n
			break

	# ---------------------------------------------------------
	# 2) Falls kein EndEvent existiert: neuen erzeugen
	# ---------------------------------------------------------
	if end_event == null:
		print("AutoConnector: Erzeuge automatisches EndEvent")

		var end_scene: PackedScene = preload("res://Assets/bpmn/events/EndEvent2D.tscn")
		end_event = end_scene.instantiate()

		end_event.global_position = Vector2(1500, 600)  # Standardplatz für erstes EndEvent

		renderer_root.add_child(end_event)
		all_nodes.append(end_event)

	# EndEvent hat EINEN Input-Port
	var end_port: Area2D = end_event.get_input_ports()[0]


	# ---------------------------------------------------------
	# 3) Für alle Nodes ohne flows_to → Flow erzeugen
	# ---------------------------------------------------------
	for n in all_nodes:
		if not ("flows_to" in n):
			continue
		if n.flows_to.size() > 0:
			continue

		var outs = n.get_output_ports()
		if outs.size() == 0:
			continue  # EndEvent

		var source_port: Area2D = outs[0]

		# -----------------------------------------------------
		# Routing via LayoutEngine
		# -----------------------------------------------------
		var pts = layout_engine.route_between_ports(source_port, end_port)

		# -----------------------------------------------------
		# Flow instanzieren
		# -----------------------------------------------------
		var flow = flow_scene.instantiate()
		renderer_root.add_child(flow)
		flow.setup(pts)
