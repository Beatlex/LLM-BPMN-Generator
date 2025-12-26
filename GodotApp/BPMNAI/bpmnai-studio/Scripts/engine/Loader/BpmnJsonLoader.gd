extends Node2D

@onready var factory      = NodeFactory.new()
@onready var layout       = preload("res://Scripts/engine/layout/LayoutEngine.gd").new()
@onready var flow_handler = preload("res://Scripts/engine/flow/FlowConnectionHandler.gd").new()
@onready var flow_scene   = preload("res://Assets/bpmn/nodes/FlowLine2D.tscn")

@onready var btn_back: Button = $UI/btnBack
@onready var btn_screenshot: Button = $UI/btnScreenshot
@onready var cam: Camera2D = $Camera2D

@onready var diagram_root: Node2D = self

var current_data: Array = []


func load_json_data(data: Array) -> void:
	current_data = data
	_render_bpmn()


func _ready() -> void:
	if btn_back:
		btn_back.pressed.connect(_back_to_home)

	if btn_screenshot:
		btn_screenshot.pressed.connect(_take_screenshot)

	if cam:
		cam.make_current()

	if not BPMNData.pending_bpmn.is_empty():
		current_data = BPMNData.pending_bpmn
		BPMNData.pending_bpmn = []
		_render_bpmn()

func _back_to_home() -> void:
	match BPMNData.origin:
		BPMNData.Origin.CHAT:
			get_tree().change_scene_to_file(
				"res://ui/chat/LlmChatWindow.tscn"
			)
		BPMNData.Origin.HOME:
			get_tree().change_scene_to_file(
				"res://ui/home/Home.tscn"
			)
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

func _take_screenshot() -> void:
	await get_tree().process_frame

	var viewport := get_viewport().get_camera_2d().get_viewport()
	var image: Image = viewport.get_texture().get_image()

	if image == null:
		push_error("[Screenshot] Konnte Viewport nicht erfassen")
		return

	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "res://Logs/BPMNPngs/bpmn_screenshot_%s.png" % timestamp

	var err := image.save_png(path)
	if err != OK:
		push_error("[Screenshot] Fehler beim Speichern")
	else:
		print("[Screenshot] Gespeichert:", path)
