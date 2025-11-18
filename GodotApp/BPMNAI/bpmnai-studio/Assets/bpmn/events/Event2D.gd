extends Node2D

# -------------------------------------------------------------
# EXPORTS
# -------------------------------------------------------------
@export var element_id: String = ""
@export var element_name: String = ""
@export var flows_from: Array[String] = []
@export var parent: String = ""
@export var children: Array[String] = []

# -------------------------------------------------------------
# INTERNAL NODE REFERENCES
# -------------------------------------------------------------
@onready var sprite: Sprite2D = $EndEventLogo
@onready var label: Label = $Label
@onready var port_input: Area2D = $TaskInput/Area2D

# -------------------------------------------------------------
# TEXTURE
# -------------------------------------------------------------
var tex_end = preload("res://Assets/bpmn/events/End_Event.png")

# -------------------------------------------------------------
# READY
# -------------------------------------------------------------
func _ready():
	sprite.texture = tex_end
	if element_name != "":
		label.text = element_name

# -------------------------------------------------------------
# PUBLIC API – Setup from JSON element
# -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	element_id   = element.get("id", "")
	element_name = element.get("name", "")
	label.text   = element_name

	parent      = element.get("parent", null)
	children    = element.get("children", [])
	flows_from  = element.get("flows_from", [])

	# Position
	if element.has("position"):
		var pos = element["position"]
		if pos.has("x") and pos.has("y"):
			global_position = Vector2(pos["x"], pos["y"])

# -------------------------------------------------------------
# PORT API
# -------------------------------------------------------------
func get_input_ports() -> Array:
	return [port_input]

func get_output_ports() -> Array:
	return []   # EndEvent hat K E I N E Outputs

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position
