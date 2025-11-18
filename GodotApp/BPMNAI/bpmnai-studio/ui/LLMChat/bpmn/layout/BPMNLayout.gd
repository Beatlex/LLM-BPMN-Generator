extends Node2D

enum EventType { START, END, INTERMEDIATE }

@export var element_id: String = ""
@export var element_name: String = ""
@export var event_type: EventType = EventType.START

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var tex_start      = preload("res://Assets/bpmn/events/Start_event.png")
var tex_end        = preload("res://Assets/bpmn/events/End_Event.png")
var tex_intermediate = preload("res://Assets/bpmn/events/Intermediate_event.png")
# TODO: weitere Eventtypen mappen 

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
		"start_event":
			event_type = EventType.START
		"end_event":
			event_type = EventType.END
		"intermediate_event":
			event_type = EventType.INTERMEDIATE
		_:
			# TODO: weitere Eventtypen abbilden (Timer, Message, etc.)
			event_type = EventType.START

	_update_visuals()

func _update_visuals() -> void:
	match event_type:
		EventType.START:
			sprite.texture = tex_start
		EventType.END:
			sprite.texture = tex_end
		EventType.INTERMEDIATE:
			sprite.texture = tex_intermediate
