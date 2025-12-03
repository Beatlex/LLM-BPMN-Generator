extends Node2D

@onready var factory      = NodeFactory.new()
@onready var layout       = preload("res://Scripts/engine/layout/LayoutEngine.gd").new()
@onready var flow_handler = preload("res://Scripts/engine/flow/FlowConnectionHandler.gd").new()
@onready var flow_scene   = preload("res://Assets/bpmn/nodes/FlowLine2D.tscn")

# Wichtig: Script hängt auf Node2D → Button ist ein Geschwister unter ../UI
@onready var btn_back: Button = $UI/btnBackHome
@onready var cam: Camera2D = $Camera2D
# Diagramm-Root: einfach dieser Node2D selbst
@onready var diagram_root: Node2D = self

var current_data: Array = []


### -------------------------------------------
### Wird vom Home-Menü aufgerufen
### -------------------------------------------
func load_json_data(data: Array) -> void:
	current_data = data
	_render_bpmn()


func _ready() -> void:
	# Button nur verbinden, wenn er wirklich gefunden wurde
	if btn_back:
		btn_back.pressed.connect(_back_to_home)
	else:
		push_error("[BpmnJsonLoader] btnBackHome nicht gefunden! Pfad prüfen.")

	if cam:
		cam.make_current()
	else:
		push_error("[Runner] Keine Camera2D gefunden!")

	# === Daten aus dem globalen Container holen (Home-Pfad) ===
	if not BPMNData.pending_bpmn.is_empty():
		current_data = BPMNData.pending_bpmn
		BPMNData.pending_bpmn = []  # leeren, damit kein alter Müll bleibt
		_render_bpmn()
	# Falls du den Loader auch anders verwendest (z.B. direkt mit load_json_data),
	# dann einfach nichts machen, current_data wird dann von außen gesetzt.

func _back_to_home() -> void:
	get_tree().change_scene_to_file("res://ui/home/Home.tscn")

### -------------------------------------------
### ⚡ Generiert & zeichnet das BPMN Diagramm
### -------------------------------------------
func _render_bpmn() -> void:
	if typeof(current_data) != TYPE_ARRAY or current_data.is_empty():
		push_error("[Runner] JSON muss ARRAY sein!")
		return

	# Nodes erzeugen
	var nodes = factory.build_all(current_data)

	# Layout berechnen
	layout.apply_layout(nodes)

	# BPMN-Objekte ins Diagramm hängen
	for id in nodes.keys():
		diagram_root.add_child(nodes[id])

	# Flows erzeugen
	var flows = flow_handler.connect_flows(nodes)
	for f in flows:
		diagram_root.add_child(f)

	# Debug
	print("\n========== BPMN Rendered ==========")
	for id in nodes.keys():
		var n: Node2D = nodes[id]
		print("Node:", id, " → ", n.element_type, " Pos:", n.global_position)
	print("===================================\n")
