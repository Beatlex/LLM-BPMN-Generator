extends Node2D

## -------------------------------------------------------------
## ENUM – Welche Task-Art soll das Icon bestimmen?
## -------------------------------------------------------------
enum TaskType {
	EMPTY,
	MANUAL,
	RECEIVE,
	RECEIVE_INSTANTIATED,
	SCRIPT,
	SERVICE
}

## -------------------------------------------------------------
## EXPORTS
## -------------------------------------------------------------
@export var element_id: String = ""
@export var element_name: String = ""

@export var task_type: TaskType = TaskType.EMPTY:
	set = _set_task_type

## -------------------------------------------------------------
## INTERNAL NODE REFERENCES
## -------------------------------------------------------------
@onready var sprite: Sprite2D = $TaskLogo
@onready var label: Label   = $Label

# Ports
@onready var port_input: Area2D = $Input/InputPort
@onready var port_output: Area2D = $Output/OutputPort


## -------------------------------------------------------------
## TEXTURES
## -------------------------------------------------------------
var tex_empty               = preload("res://Assets/bpmn/tasks/Task_EmptyTemplate.png")
var tex_manual              = preload("res://Assets/bpmn/tasks/Task_Manual.png")
var tex_receive             = preload("res://Assets/bpmn/tasks/Task_Receive.png")
var tex_receive_instantiated = preload("res://Assets/bpmn/tasks/Task_Receive_instantiated.png")
var tex_script              = preload("res://Assets/bpmn/tasks/Task_Script.png")
var tex_service             = preload("res://Assets/bpmn/tasks/Task_Service.png")

## -------------------------------------------------------------
## READY
## -------------------------------------------------------------
func _ready():
	_update_visuals()
	if element_name != "":
		label.text = element_name


## -------------------------------------------------------------
## SETTER – Für Editor Dropdown
## -------------------------------------------------------------
func _set_task_type(value):
	task_type = value
	_update_visuals()

## -------------------------------------------------------------
## PUBLIC API – Für den Renderer
## -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	element_id   = element.get("id", "")
	element_name = element.get("name", "")
	label.text   = element_name

	var t = element.get("type", "")

	match t:
		"task_manual":
			task_type = TaskType.MANUAL
		"task_receive":
			task_type = TaskType.RECEIVE
		"task_receive_instantiated":
			task_type = TaskType.RECEIVE_INSTANTIATED
		"task_script":
			task_type = TaskType.SCRIPT
		"task_service":
			task_type = TaskType.SERVICE
		_:
			task_type = TaskType.EMPTY

	_update_visuals()

## -------------------------------------------------------------
## INTERNAL – Updated the proper icon
## -------------------------------------------------------------
func _update_visuals() -> void:
	if not sprite:
		return

	match task_type:
		TaskType.EMPTY:
			sprite.texture = tex_empty
		TaskType.MANUAL:
			sprite.texture = tex_manual
		TaskType.RECEIVE:
			sprite.texture = tex_receive
		TaskType.RECEIVE_INSTANTIATED:
			sprite.texture = tex_receive_instantiated
		TaskType.SCRIPT:
			sprite.texture = tex_script
		TaskType.SERVICE:
			sprite.texture = tex_service

## -------------------------------------------------------------
## PORT API – Konsistent zum Gateway!
## -------------------------------------------------------------
func get_input_ports() -> Array:
	return [port_input]

func get_output_ports() -> Array:
	return [port_output]

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position
