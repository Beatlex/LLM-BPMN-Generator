extends Node2D

## -------------------------------------------------------------
## ENUM – Task-Art
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
## EXPORTS – Daten aus JSON
## -------------------------------------------------------------
@export var element_id: String = ""
@export var element_name: String = ""
@export var lane_id: String = ""
@export var pool_id: String = ""
@export var element_type: String = "task"

# Muss zwingend Array[String] sein → typ-sicher!
@export var flows_to: Array[String] = []

# Die Eltern-ID (falls notwendig)
@export var element_parent_id: String = ""

# Auto-Assign: TaskType
@export var task_type: TaskType = TaskType.EMPTY:
	set = _set_task_type


## -------------------------------------------------------------
## INTERNAL REFERENCES
## -------------------------------------------------------------
@onready var sprite: Sprite2D = $TaskLogo
@onready var label: Label     = $Label

# Ports
@onready var port_input: Area2D  = $Input/InputPort
@onready var port_output: Area2D = $Output/OutputPort


## -------------------------------------------------------------
## TEXTURES
## -------------------------------------------------------------
var tex_empty                = preload("res://Assets/bpmn/tasks/Task_EmptyTemplate.png")
var tex_manual               = preload("res://Assets/bpmn/tasks/Task_Manual.png")
var tex_receive              = preload("res://Assets/bpmn/tasks/Task_Receive.png")
var tex_receive_instantiated = preload("res://Assets/bpmn/tasks/Task_Receive_instantiated.png")
var tex_script               = preload("res://Assets/bpmn/tasks/Task_Script.png")
var tex_service              = preload("res://Assets/bpmn/tasks/Task_Service.png")


## -------------------------------------------------------------
## READY
## -------------------------------------------------------------
func _ready():
	_update_visuals()

	# Falls der Name bereits gesetzt wurde
	if element_name != "":
		call_deferred("_apply_label", element_name)


## -------------------------------------------------------------
## Internal setter
## -------------------------------------------------------------
func _set_task_type(value):
	task_type = value
	_update_visuals()


## -------------------------------------------------------------
## PUBLIC API – JSON Import
## -------------------------------------------------------------
func setup_from_element(element: Dictionary) -> void:

	# Basic fields
	element_id   = element.get("element_id", "")
	element_name = element.get("element_name", "")
	lane_id      = element.get("lane_id", "")
	pool_id      = element.get("pool_id", "")
	element_type = element.get("element_type", "task")
	element_parent_id = element.get("parent", "")

	# Label erst NACH onready existierend → deferred setzen
	call_deferred("_apply_label", element_name)

	# Typ-sichere flows_to Verarbeitung
	flows_to.clear()
	for target in element.get("flows_to", []):
		flows_to.append(str(target))

	# TaskType Auto-Erkennung
	var t: String = element.get("element_type", "")
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
## Apply label (nach ready)
## -------------------------------------------------------------
func _apply_label(text_value: String) -> void:
	if label:
		label.text = text_value


## -------------------------------------------------------------
## Update visuals
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
## PORT API – Konsistent
## -------------------------------------------------------------
func get_input_ports() -> Array:
	return [port_input]

func get_output_ports() -> Array:
	return [port_output]

func get_port_global_position(port: Area2D) -> Vector2:
	return port.global_position

func get_input_port_position(idx := 0) -> Vector2:
	return get_port_global_position(get_input_ports()[idx])

func get_output_port_position(idx := 0) -> Vector2:
	return get_port_global_position(get_output_ports()[idx])
