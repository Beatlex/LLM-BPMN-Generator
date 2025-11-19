extends Node2D

@onready var gateway: Node2D      = $GatewayNode2d
@onready var task_yes: Node2D     = $TaskNode2DJa
@onready var task_no: Node2D      = $TaskNode2DNein

@onready var flow_yes: Node2D     = $FlowLine2DJa
@onready var flow_no: Node2D      = $FlowLine2DNein

@onready var layout: LayoutEngine = $LayoutEngine


func _ready():
	# Gateway-Ports holen
	var gw_outputs: Array = gateway.get_output_ports()
	var gw_out_yes: Area2D = gw_outputs[0]   # rechts
	var gw_out_no:  Area2D = gw_outputs[1]   # unten

	# Task-Input-Ports holen
	var yes_input: Area2D = task_yes.get_input_ports()[0]
	var no_input:  Area2D = task_no.get_input_ports()[0]

	# Routen:
	layout.route_between_ports(gw_out_yes, yes_input, flow_yes)
	layout.route_between_ports(gw_out_no,  no_input,  flow_no)

	print("TestFlowGateway: Routing fertig.")
