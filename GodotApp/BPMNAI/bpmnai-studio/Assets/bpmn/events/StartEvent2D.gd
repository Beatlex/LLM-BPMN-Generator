extends Node2D

@export var element_id := ""
@export var element_name := ""
@export var lane_id: String = ""
@export var pool_id: String = ""
@export var element_type: String = "start_event"
@export var flows_to: Array[String] = []


@onready var sprite: Sprite2D = $StartLogo
@onready var label: Label   = $Label
@onready var port_output: Area2D = $Output/OutputPort

var tex_start = preload("res://Assets/bpmn/events/Start_event.png")


func _ready():
	sprite.texture = tex_start
	if element_name != "":
		label.text = element_name


# ------------------------------------------
# JSON import
# ------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	element_id   = element.get("element_id", "")
	element_name = element.get("element_name", "")

	# Label existiert erst nach _ready():
	call_deferred("_apply_label", element_name)

	flows_to = []
	for f in element.get("flows_to", []):
		flows_to.append(String(f))

	lane_id = element.get("lane_id", "")
	pool_id = element.get("pool_id", "")

	# optional position
	if element.has("position"):
		global_position = Vector2(
			element["position"].get("x", 0),
			element["position"].get("y", 0)
		)


func _apply_label(name: String) -> void:
	if label:
		label.text = name


# ------------------------------------------
# Port API
# ------------------------------------------
func get_input_ports() -> Array:
	return []


func get_output_ports() -> Array:
	return [port_output]


func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position
