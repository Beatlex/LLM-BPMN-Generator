extends Node2D

## -------------------------------------------------------------
## ENUM & EXPORTS
## -------------------------------------------------------------
enum GatewayType { XOR, AND, OR, EMPTY }

@export var element_id: String = ""
@export var element_name: String = ""

# Neue Parameter (nicht invasiv)
@export var element_output1: String = "Yes"
@export var element_output2: String = "No"

@export var element_parent_id: String = ""
@export var element_children_ids: Array[String] = []

@export var gateway_type: GatewayType = GatewayType.XOR:
	set = _set_gateway_type

@export var lane_id: String = ""
@export var pool_id: String = "" 

@export var element_type: String = "gateway"
@export var outputs: Dictionary = {}
@export var flows_to: Array[String] = []


## -------------------------------------------------------------
## INTERNAL NODE REFERENCES
## -------------------------------------------------------------
@onready var sprite: Sprite2D = $GatewayLogo
@onready var label: Label     = $Label
# Output label nodes
@onready var output_label_x: Label = $Output1
@onready var output_label_y: Label = $Output2
# Ports
@onready var port_input: Area2D      = $Input/InputPort
@onready var port_output_x: Area2D   = $OutputX/OutputPort
@onready var port_output_y: Area2D   = $OutputY/OutputPort
@onready var port_output_y_top: Area2D = $OutputYTop/OutputPort


## -------------------------------------------------------------
## TEXTURES
## -------------------------------------------------------------
var tex_xor   = preload("res://Assets/bpmn/gateways/XOR_Gateway.png")
var tex_and   = preload("res://Assets/bpmn/gateways/AND_Gateway.png")
var tex_or    = preload("res://Assets/bpmn/gateways/OR_Gateway.png")
var tex_empty = preload("res://Assets/bpmn/gateways/Gateway_Empty.png")


## -------------------------------------------------------------
## READY
## -------------------------------------------------------------
func _ready():
	_update_visuals()

	# Haupttitel
	if element_name != "":
		label.text = element_name

	# Output-Labels (mit Default)
	output_label_x.text = element_output1 if element_output1 != "" else "Ja"
	output_label_y.text = element_output2 if element_output2 != "" else "Nein"


## -------------------------------------------------------------
## SETTER (Fix für Editor Dropdown!)
## -------------------------------------------------------------
func _set_gateway_type(value):
	gateway_type = value
	_update_visuals()


## -------------------------------------------------------------
## PUBLIC API – setup from JSON
## -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:
	element_id   = element.get("element_id", "")
	element_type = element.get("element_type", "gateway")
	element_name = element.get("element_name", "")

	call_deferred("_apply_label", element_name)
	_apply_labels_from_outputs()

	# 1) Gateway-Type bevorzugt aus JSON lesen
	var gt = element.get("gateway_type", "")

	if gt == "":
		# 2) AUTOMATISCHE Erkennung aus element_type
		match element_type:
			"exclusive_gateway":
				gateway_type = GatewayType.XOR
			"inclusive_gateway":
				gateway_type = GatewayType.OR
			"parallel_gateway":
				gateway_type = GatewayType.AND
			_:
				gateway_type = GatewayType.EMPTY
	else:
		# 3) Der JSON "gateway_type" Key überschreibt
		match gt.to_lower():
			"xor":
				gateway_type = GatewayType.XOR
			"and":
				gateway_type = GatewayType.AND
			"or":
				gateway_type = GatewayType.OR
			_:
				gateway_type = GatewayType.EMPTY	
	# flows_to
	flows_to = []
	for f in element.get("flows_to", []):
		flows_to.append(String(f))

	# outputs (Dictionary)
	outputs = element.get("outputs", {})

# Output labels aus "outputs" Dictionary übernehmen
	if element.has("outputs"):
		var outs_dict = element["outputs"]

	# RIGHT → output_label_x
		if outs_dict.has("right"):
			element_output1 = outs_dict["right"]
			call_deferred("_apply_output_label_x", element_output1)

		# DOWN → output_label_y
		if outs_dict.has("down"):
			element_output2 = outs_dict["down"]
			call_deferred("_apply_output_label_y", element_output2)


	# Parent/Children
	element_parent_id = element.get("parent", "")

	lane_id = element.get("lane_id", "")
	pool_id = element.get("pool_id", "")

	_update_visuals()


# SAFETY HELPERS (NEU)
func _apply_label(t: String) -> void:
	if label:
		label.text = t

func _apply_output_label_x(t: String) -> void:
	if output_label_x:
		output_label_x.text = t

func _apply_output_label_y(t: String) -> void:
	if output_label_y:
		output_label_y.text = t


# INTERNAL — Update visuals based on type
func _update_visuals():
	if not sprite:
		return

	match gateway_type:
		GatewayType.XOR:
			sprite.texture = tex_xor
		GatewayType.AND:
			sprite.texture = tex_and
		GatewayType.OR:
			sprite.texture = tex_or
		GatewayType.EMPTY:
			sprite.texture = tex_empty


func get_input_ports() -> Array:
	return [port_input]
	
func get_output_ports() -> Array:
	var ports := []

	var t = str(element_type)

	# PARALLEL (AND)
	if t == "parallel_gateway":
		if port_output_y_top: ports.append(port_output_y_top)
		if port_output_x: ports.append(port_output_x)
		if port_output_y: ports.append(port_output_y)
		return ports

	# XOR / OR
	if t == "exclusive_gateway" or t == "inclusive_gateway":
		# 1 → Mitte
		# 2 → Mitte + Unten
		# 3 → Oben + Mitte + Unten
		if flows_to.size() == 1:
			if port_output_x: ports.append(port_output_x)
		elif flows_to.size() == 2:
			if port_output_x: ports.append(port_output_x)
			if port_output_y: ports.append(port_output_y)
		else:
			if port_output_y_top: ports.append(port_output_y_top)
			if port_output_x: ports.append(port_output_x)
			if port_output_y: ports.append(port_output_y)
		return ports

	# Fallback
	if port_output_x: ports.append(port_output_x)
	if port_output_y: ports.append(port_output_y)
	return ports


func get_output_ports_sorted() -> Array:
	var ports = [
		{"node": port_output_y_top, "y": port_output_y_top.global_position.y},
		{"node": port_output_x,     "y": port_output_x.global_position.y},
		{"node": port_output_y,     "y": port_output_y.global_position.y}
	]

	ports = ports.filter(func(p): return p["node"] != null)
	ports.sort_custom(func(a,b): return a["y"] < b["y"])

	var sorted:= []
	for p in ports:
		sorted.append(p["node"])
	return sorted


func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position

func get_output_port_position(idx := 0) -> Vector2:
	return get_port_global_position(get_output_ports()[idx])

func _apply_labels_from_outputs():
	if outputs.size() > 2:
		# Zu viele Outputs → keine Labels anzeigen
		if output_label_x: output_label_x.visible = false
		if output_label_y: output_label_y.visible = false
		return

	# Normalfall: 1–2 Ausgänge → Label anwenden
	if outputs.has("right"):
		output_label_x.visible = true
		output_label_x.text = outputs["right"]

	if outputs.has("down"):
		output_label_y.visible = true
		output_label_y.text = outputs["down"]

func apply_gateway_label_logic(is_split: bool, is_merge: bool) -> void:
	# Wenn es ein Split ODER Merge ist → keine Labels!
	if is_split or is_merge:
		if output_label_x: output_label_x.visible = false
		if output_label_y: output_label_y.visible = false

func get_merge_ports() -> Array:
	var arr: Array = []

	# [0] = Top-Input  (oben)
	if port_output_y_top:
		arr.append(port_output_y_top)

	# [1] = Mid-Input  (links)
	if port_input:
		arr.append(port_input)

	# [2] = Bottom-Input (unten)
	if port_output_y:
		arr.append(port_output_y)

	return arr
