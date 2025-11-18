extends Node2D

@onready var cam: Camera2D = $Camera2D
@onready var diagram_root: Node2D = $DiagramRoot

var pan_active := false
var last_mouse_pos := Vector2.ZERO

const ZOOM_IN_FACTOR := 0.9
const ZOOM_OUT_FACTOR := 1.1
const ZOOM_MIN := 0.4
const ZOOM_MAX := 3.0


func _ready():
	cam.make_current()
	print("MainScene ready. BPMN Renderer initialized.")


func _input(event):
	# --- Zoom In ---
	if event.is_action_pressed("zoom_in"):
		_apply_zoom(ZOOM_IN_FACTOR)

	# --- Zoom Out ---
	if event.is_action_pressed("zoom_out"):
		_apply_zoom(ZOOM_OUT_FACTOR)

	# --- Pan Start ---
	if event.is_action_pressed("pan"):
		pan_active = true
		last_mouse_pos = event.position

	# --- Pan End ---
	if event.is_action_released("pan"):
		pan_active = false

	# --- While Panning (Mouse Motion) ---
	if event is InputEventMouseMotion and pan_active:
		var delta = event.relative
		cam.position -= delta
		

func _apply_zoom(factor):
	var new_zoom = cam.zoom * factor

	new_zoom.x = clamp(new_zoom.x, ZOOM_MIN, ZOOM_MAX)
	new_zoom.y = clamp(new_zoom.y, ZOOM_MIN, ZOOM_MAX)

	cam.zoom = new_zoom
