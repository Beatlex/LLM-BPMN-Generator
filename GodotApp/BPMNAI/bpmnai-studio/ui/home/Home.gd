extends Node2D

enum GatewayType { XOR, AND, OR, EMPTY }

@export var element_id: String = ""
@export var element_name: String = ""
@export var gateway_type: GatewayType = GatewayType.XOR

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var tex_xor   = preload("res://Assets/bpmn/gateways/XOR_Gateway.png")
var tex_and   = preload("res://Assets/bpmn/gateways/AND_Gateway.png")
var tex_or    = preload("res://Assets/bpmn/gateways/OR_Gateway.png")
var tex_empty = preload("res://Assets/bpmn/gateways/Gateway_Empty.png")

func _ready():
	_update_visuals()
	if element_name != "":
		label.text = element_name

func setup_from_element(element: Dictionary) -> void:
	element_id = element.get("id", "")
	element_name = element.get("name", "")
	label.text = element_name

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

func _update_visuals():
	match gateway_type:
		GatewayType.XOR:
			sprite.texture = tex_xor
		GatewayType.AND:
			sprite.texture = tex_and
		GatewayType.OR:
			sprite.texture = tex_or
		GatewayType.EMPTY:
			sprite.texture = tex_empty
