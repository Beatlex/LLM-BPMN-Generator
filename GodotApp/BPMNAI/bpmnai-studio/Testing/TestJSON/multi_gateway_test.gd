extends Node2D

@onready var factory = NodeFactory.new()
@onready var layout = preload("res://Scripts/engine/layout/LayoutEngine.gd").new()
@onready var flow_handler = preload("res://Scripts/engine/flow/FlowConnectionHandler.gd").new()
@onready var flow_scene = preload("res://Assets/bpmn/nodes/FlowLine2D.tscn")

func _ready():
	# JSON laden
	var file = FileAccess.open("res://Testing/TestJSON/MultiGateway.json", FileAccess.READ)
	var json_text = file.get_as_text()
	var data = JSON.parse_string(json_text)

	if typeof(data) != TYPE_ARRAY:
		push_error("JSON root must be array!")
		return

	# Nodes erzeugen
	var nodes = factory.build_all(data)

	# Layout anwenden (KORREKT)
	layout.apply_layout(nodes)

	# Nodes der Szene hinzufügen
	for id in nodes.keys():
		add_child(nodes[id])

	# 4) Flows erzeugen
	var flows = flow_handler.connect_flows(nodes)
	for f in flows:
		add_child(f)
		
	# ----------------------------------------------------
	# ⚡ Debug: Node-Positionen in sauberer Tabelle ausgeben
	# ----------------------------------------------------
	print("\n================ NODE POSITION DEBUG ================")
	var sorted_ids = nodes.keys()
	sorted_ids.sort()   # Optional: alphabetische Ausgabe

	for id in sorted_ids:
		var n: Node2D = nodes[id]
		print("ID:", id, "  TYPE:", n.element_type, 
			  " → X:", round(n.global_position.x), 
			  " | Y:", round(n.global_position.y))

	print("=====================================================\n")
