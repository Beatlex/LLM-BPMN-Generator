extends Node2D

## -------------------------------------------------------------
## ENUM & EXPORTS
## -------------------------------------------------------------
enum GatewayType { XOR, AND, OR, EMPTY }

@export var element_id: String = ""
@export var element_name: String = ""

@export var gateway_type: GatewayType = GatewayType.XOR:
	set = _set_gateway_type

## -------------------------------------------------------------
## INTERNAL NODE REFERENCES
## -------------------------------------------------------------
@onready var sprite: Sprite2D = $GatewayLogo
@onready var label: Label   = $Label
# Ports
@onready var port_input: Area2D            = $Input/InputPort/Area2D
@onready var port_output_x: Area2D         = $OutputX/OutputPort/Area2D
@onready var port_output_y: Area2D         = $OutputY/OutputPort/Area2D
# Output label nodes
@onready var output_label_x: Label = $OutputX/Output1
@onready var output_label_y: Label = $OutputY/Output2
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
	if element_name != "":
		label.text = element_name

## -------------------------------------------------------------
## SETTER (Fix für Editor Dropdown!)
## -------------------------------------------------------------
func _set_gateway_type(value):
	gateway_type = value
	_update_visuals()

## -------------------------------------------------------------
## PUBLIC API – called by BPMNRenderer
## -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	element_id   = element.get("id", "")
	element_name = element.get("name", "")
	label.text   = element_name

	var t = element.get("type", "")

	match t:
		"exclusive_gateway":
			gateway_type = GatewayType.XOR
		"parallel_gateway":
			gateway_type = GatewayType.AND
		"inclusive_gateway":
			gateway_type = GatewayType.OR
		_:
			gateway_type = GatewayType.EMPTY

	_update_visuals()

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
