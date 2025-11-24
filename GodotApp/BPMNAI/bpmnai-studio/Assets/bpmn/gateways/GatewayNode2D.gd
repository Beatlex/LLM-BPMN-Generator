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

	# Output labels (optional)
	var outs = element.get("output_labels", [])
	if outs.size() > 0:
		element_output1 = outs[0]
		call_deferred("_apply_output_label_x", outs[0])
	if outs.size() > 1:
		element_output2 = outs[1]
		call_deferred("_apply_output_label_y", outs[1])

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


## -------------------------------------------------------------
## INTERNAL — Update visuals based on type
## -------------------------------------------------------------
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


## -------------------------------------------------------------
## PORT API
## -------------------------------------------------------------
func get_input_ports() -> Array:
	return [port_input]

func get_output_ports() -> Array:
	return [port_output_x, port_output_y]

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position

func get_output_port_position(idx := 0) -> Vector2:
	return get_port_global_position(get_output_ports()[idx])
