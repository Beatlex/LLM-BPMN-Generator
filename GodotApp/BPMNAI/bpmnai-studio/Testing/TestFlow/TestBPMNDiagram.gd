extends Node2D

@onready var layout       : LayoutEngine = $LayoutEngine
@onready var start_event                = $StartEvent
@onready var task_a                     = $TaskA
@onready var gateway                    = $Gateway
@onready var task_yes                   = $TaskYes
@onready var task_no                    = $TaskNo
@onready var end_event                  = $EndEvent

@onready var flow_start_task  = $Flow_Start_Task
@onready var flow_task_gw     = $Flow_Task_Gateway
@onready var flow_gw_yes      = $Flow_GW_Yes
@onready var flow_gw_no       = $Flow_GW_No
@onready var flow_yes_end     = $Flow_Yes_End
@onready var flow_no_end      = $Flow_No_End


func _ready():
	_set_positions()

	# 1) Start → TaskA
	_connect_flow(flow_start_task, start_event, 0, task_a, 0)

	# 2) TaskA → Gateway
	_connect_flow(flow_task_gw, task_a, 0, gateway, 0)

	# 3) Gateway → TaskYes (X-Output)
	_connect_flow(flow_gw_yes, gateway, 0, task_yes, 0)

	# 4) Gateway → TaskNo (Y-Output)
	_connect_flow(flow_gw_no, gateway, 1, task_no, 0)

	# 5) TaskYes → EndEvent  (wird gleich überschrieben)
	_connect_flow(flow_yes_end, task_yes, 0, end_event, 0)

	# 6) TaskNo → EndEvent   (wird gleich überschrieben)
	_connect_flow(flow_no_end, task_no, 0, end_event, 0)

	# 7) Nun den Merge anwenden → überschreibt die Endlinien
	_connect_end_merges()

func _set_positions():

	# BPMN-friendly margins
	var H_SPACING := 400     # horizontal spacing between elements
	var V_SPACING := 400     # vertical spacing for branches

	# Start lane (Y = 200)
	var Y_MAIN := 200

	# Branch lane (No = below)
	var Y_BRANCH := Y_MAIN + V_SPACING   # → 600

	# 1) Start Event
	start_event.position = Vector2(100, Y_MAIN)

	# 2) Task A
	task_a.position = start_event.position + Vector2(H_SPACING, 0)

	# 3) Gateway
	gateway.position = task_a.position + Vector2(H_SPACING, 0)

	# 4) YES Task (Gerade Linie)
	task_yes.position = gateway.position + Vector2(H_SPACING + 200, 0)

	# 5) NO Task (ein Strang tiefer)
	task_no.position = gateway.position + Vector2(H_SPACING + 200, V_SPACING)

	# 6) End Event mittig zwischen yes/no
	var end_x = task_yes.position.x + H_SPACING
	var end_y = (task_yes.position.y + task_no.position.y) / 2.0  # Durchschnitt

	end_event.position = Vector2(end_x, end_y)



func _connect_flow(flow: Node2D, from_node, from_out_idx: int, to_node, to_in_idx: int):
	var out_port: Area2D = from_node.get_output_ports()[from_out_idx]
	var in_port : Area2D = to_node.get_input_ports()[to_in_idx]

	# nutzt die rückwärtskompatible Variante:
	# route_between_ports(source_port, target_port, flow_line)
	layout.route_between_ports(out_port, in_port, flow)
	
func _connect_end_merges():
	var sources = [task_yes, task_no]
	var ports   = [
		task_yes.get_output_ports()[0],
		task_no.get_output_ports()[0]
	]

	var end_port = end_event.get_input_ports()[0]

	var merged := layout.route_merge_to_target(
		sources,
		ports,
		end_event,
		end_port
	)

	# jetzt setzen wir die Flow-Linien
	flow_yes_end.setup( merged[task_yes] )
	flow_no_end.setup( merged[task_no] )
