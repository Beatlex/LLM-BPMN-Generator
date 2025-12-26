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

	var end_scene: PackedScene = preload("res://Assets/bpmn/events/EndEvent2D.tscn")

	for n in all_nodes:
		if not ("flows_to" in n):
			continue

		# Node hat bereits ein Ziel → OK
		if n.flows_to.size() > 0:
			continue

		var outs = n.get_output_ports()
		if outs.is_empty():
			continue

		# 🔹 Für DIESEN Pfad ein eigenes EndEvent
		var end_event = end_scene.instantiate()

		# einfache relative Positionierung (minimal invasiv)
		end_event.global_position = n.global_position + Vector2(400, 0)

		renderer_root.add_child(end_event)
		all_nodes.append(end_event)

		var source_port: Area2D = outs[0]
		var end_port: Area2D = end_event.get_input_ports()[0]

		var flow = flow_scene.instantiate()
		renderer_root.add_child(flow)
		flow.setup(source_port, end_port, 0)
