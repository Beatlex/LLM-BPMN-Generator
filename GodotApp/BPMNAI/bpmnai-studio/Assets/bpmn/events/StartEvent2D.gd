extends Node2D

@export var element_id := ""
@export var element_name := ""
@export var flows_to: Array[String] = []
@export var children: Array[String] = []

@onready var sprite: Sprite2D = $StartLogo
@onready var label: Label = $Label
@onready var port_output: Area2D = $Output/OutputPort   # << KORREKT

var tex_start = preload("res://Assets/bpmn/events/Start_event.png")

func _ready():
	sprite.texture = tex_start
	if element_name != "":
		label.text = element_name

# JSON
func setup_from_element(element: Dictionary) -> void:
	element_id   = element.get("id", "")
	element_name = element.get("name", "")
	label.text   = element_name

	flows_to = element.get("flows_to", [])
	children = element.get("children", [])

	if element.has("position"):
		global_position = Vector2(element["position"]["x"], element["position"]["y"])

# -------- Port API --------

func get_input_ports() -> Array:
	return []

func get_output_ports() -> Array:
	return [port_output]

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position

func get_output_port_position(idx := 0) -> Vector2:
	return get_port_global_position(get_output_ports()[idx])
