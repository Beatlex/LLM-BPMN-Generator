extends Node2D

# -------------------------------------------------------------
# EXPORTS
# -------------------------------------------------------------
@export var element_id: String = ""
@export var element_name: String = ""
@export var flows_to: Array[String] = []
@export var children: Array[String] = []

# -------------------------------------------------------------
# INTERNAL NODE REFERENCES
# -------------------------------------------------------------
@onready var sprite: Sprite2D = $StartLogo
@onready var label: Label = $Label
@onready var port_output: Area2D = $Output/OutputPort

# -------------------------------------------------------------
# TEXTURE
# -------------------------------------------------------------
var tex_start = preload("res://Assets/bpmn/events/Start_event.png")

# -------------------------------------------------------------
# READY
# -------------------------------------------------------------
func _ready():
	sprite.texture = tex_start
	if element_name != "":
		label.text = element_name

# -------------------------------------------------------------
# PUBLIC API – Setup from JSON element
# -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	# Basic properties
	element_id   = element.get("id", "")
	element_name = element.get("name", "")
	label.text   = element_name

	# Flow + children
	flows_to = element.get("flows_to", [])
	children = element.get("children", [])

	# Position (optional but good)
	if element.has("position"):
		var pos = element["position"]
		if pos.has("x") and pos.has("y"):
			global_position = Vector2(pos["x"], pos["y"])

# -------------------------------------------------------------
# PORT API
# -------------------------------------------------------------
func get_input_ports() -> Array:
	return []      # Start event has NO input

func get_output_ports() -> Array:
	return [port_output]

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position
