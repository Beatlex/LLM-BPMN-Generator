extends Node2D 

## -------------------------------------------------------------
## ENUM – EndEvent Typen
## -------------------------------------------------------------
enum EventType {
	GENERIC,
	ERROR
}

## -------------------------------------------------------------
## EXPORTS
## -------------------------------------------------------------
@export var element_id: String = ""
@export var element_name: String = ""
@export var event_type: EventType = EventType.GENERIC:
	set = _set_event_type

@export var lane_id: String = ""
@export var pool_id: String = ""
@export var element_type: String = "end_event"

# EndEvents haben nur EINEN Eingang
@export var flows_to: Array[String] = []

## -------------------------------------------------------------
## INTERNAL REFERENCES
## -------------------------------------------------------------
@onready var sprite: Sprite2D = $EndEventLogo
@onready var label: Label = $Label
@onready var port_input: Area2D = $Input/InputPort

## -------------------------------------------------------------
## TEXTURES
## -------------------------------------------------------------
var tex = {
	EventType.GENERIC: preload("res://Assets/bpmn/events/End_Event.png"),
	EventType.ERROR:   preload("res://Assets/bpmn/events/End_Exception_Event.png")
}

## -------------------------------------------------------------
## READY
## -------------------------------------------------------------
func _ready():
	_update_visuals()

	if element_name != "":
		# Label existiert erst NACH Ready
		call_deferred("_apply_label", element_name)

## -------------------------------------------------------------
## SETTER
## -------------------------------------------------------------
func _set_event_type(value):
	event_type = value
	_update_visuals()

## -------------------------------------------------------------
## UPDATE VISUALS
## -------------------------------------------------------------
func _update_visuals():
	if sprite and tex.has(event_type):
		sprite.texture = tex[event_type]

## -------------------------------------------------------------
## JSON IMPORT
## -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	element_id   = element.get("element_id", "")
	element_name = element.get("element_name", "")
	element_type = element.get("element_type", "end_event")
	lane_id      = element.get("lane_id", "")
	pool_id      = element.get("pool_id", "")

	# Label deferred setzen
	call_deferred("_apply_label", element_name)

	# Typ mappen
	var t = element.get("element_type", "")
	match t:
		"end_event":
			event_type = EventType.GENERIC
		"end_error_event":
			event_type = EventType.ERROR
		_:
			event_type = EventType.GENERIC

	_update_visuals()

	# Position optional
	if element.has("position"):
		var pos = element["position"]
		global_position = Vector2(
			pos.get("x", 0),
			pos.get("y", 0)
		)

## -------------------------------------------------------------
## Deferred Label Setter
## -------------------------------------------------------------
func _apply_label(text_value: String) -> void:
	if label:
		label.text = text_value

## -------------------------------------------------------------
## PORT API
## -------------------------------------------------------------
func get_input_ports() -> Array:
	return [port_input]

func get_output_ports() -> Array:
	return []  # EndEvents haben keine Outputs

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position
