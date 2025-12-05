extends Camera2D

@export var zoom_speed := 0.1
@export var zoom_min := 0.3
@export var zoom_max := 3.0

var dragging := false
var drag_start := Vector2()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				dragging = true
				drag_start = event.position
			else:
				dragging = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom.x - zoom_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom.x + zoom_speed)

	if event is InputEventMouseMotion and dragging:
		position -= event.relative    # Szene verschieben

func _set_zoom(value: float):
	var z = clamp(value, zoom_min, zoom_max)
	zoom = Vector2(z, z)
