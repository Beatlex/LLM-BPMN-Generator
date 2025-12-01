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



func _back_to_home() -> void:
	var home_scene: PackedScene = load("res://ui/home/Home.tscn")

	# 1) Prüfen ob die Szene korrekt geladen wurde
	if home_scene == null:
		push_error("[BPMN-Runner] FEHLER: Home.tscn nicht gefunden!")
		return

	# 2) Prüfen ob Home bereits existiert (Schutz vor Duplikaten)
	for child in get_tree().root.get_children():
		if child is Control and child.name == "Home":
			get_tree().root.remove_child(child)
			child.queue_free()

	# 3) Sauber neuen Home-Screen laden
	var home = home_scene.instantiate()
	get_tree().root.add_child(home)
	home.name = "Home" # wichtig, damit doppelte Instanzen verhindert werden

	# 4) Runner-Szene beenden
	queue_free()

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
