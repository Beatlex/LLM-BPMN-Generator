extends Node2D 

## -------------------------------------------------------------
## ENUM – Internes Mapping der Typen
## -------------------------------------------------------------
enum EventType {
	GENERIC,
	INTERMEDIATE,
	TIMER,
	MESSAGE,
	ERROR,
	SIGNAL,
	LINK
}

## -------------------------------------------------------------
## EXPORTS
## -------------------------------------------------------------
@export var element_id: String = ""
@export var element_name: String = ""
@export var event_type: EventType = EventType.GENERIC:
	set = _set_event_type

@export var parent: String = ""
@export var children: Array[String] = []
@export var flows_to: Array[String] = []

## -------------------------------------------------------------
## INTERNAL REFERENCES
## -------------------------------------------------------------
@onready var sprite: Sprite2D = $EndEventLogo
@onready var label: Label = $Label

# EndEvent hat NUR EINEN Input-Port:
@onready var port_input: Area2D = $Input/InputPort/Area2D

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
		label.text = element_name

## -------------------------------------------------------------
## SETTER für Editor-Dropdown
## -------------------------------------------------------------
func _set_event_type(value):
	event_type = value
	_update_visuals()

## -------------------------------------------------------------
## UPDATE VISUALS
## -------------------------------------------------------------
func _update_visuals():
	if sprite:
		if tex.has(event_type):
			sprite.texture = tex[event_type]
		else:
			sprite.texture = tex[EventType.GENERIC]

## -------------------------------------------------------------
## JSON IMPORT
## -------------------------------------------------------------
func setup_from_element(element: Dictionary):

	element_id   = element.get("id", "")
	element_name = element.get("name", "")
	label.text   = element_name

	parent      = element.get("parent", "")
	children    = element.get("children", [])
	flows_to    = element.get("flows_to", [])

	# Typ mappen
	var t = element.get("type", "")
	match t:
		"end_event":
			event_type = EventType.GENERIC
		"end_error_event":
			event_type = EventType.ERROR
		_:
			event_type = EventType.GENERIC

	_update_visuals()

	# Position setzen
	if element.has("position"):
		var pos = element["position"]
		if pos.has("x") and pos.has("y"):
			global_position = Vector2(pos["x"], pos["y"])

## -------------------------------------------------------------
## PORT API
## -------------------------------------------------------------
func get_input_ports() -> Array:
	return [port_input]

func get_output_ports() -> Array:
	# EndEvent hat KEINEN output
	return []

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position
