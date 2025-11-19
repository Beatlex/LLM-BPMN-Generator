extends Node2D

@onready var start_event = $StartEvent2D
@onready var task_node = $TaskNode2D
@onready var flow = $FlowLine2D        # WICHTIG: kein var in _ready!

func _ready():
	print("Scene loaded, searching ports…")

	var start_port = start_event.get_output_ports()[0]
	var task_port = task_node.get_input_ports()[0]

	print("Ports found:", start_port, task_port)

	# Flow einrichten
	flow.setup(start_port, task_port, 0)

	print("TestFlowScene: Flow setup fertig!")
