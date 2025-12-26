extends Node2D

@onready var line: Line2D = $Line2D
@onready var arrow: Sprite2D = $ArrowHead

const ARROW_BACK_OFFSET := 12
const BACKFLOW_OFFSET_Y := 140
const BACKFLOW_OFFSET_X := 80


func _ready():
	z_index = -10
	line.z_index = -10 
	arrow.z_index = 10


func setup(src_port: Node2D, dst_port: Node2D, route_type := 0) -> void:
	if line == null:
		await ready
	if line == null:
		push_error("[FlowLine2D] ⚠ Fehlende Line2D!!")
		return

	var start := _get_port_center(src_port)
	var end   := _get_port_center(dst_port)


	line.points = _compute_path(start, end, route_type)
	_update_arrow(line.points)


func _compute_path(start: Vector2, end: Vector2, route_type: int) -> PackedVector2Array:

	# 99 = BACKFLOW (Rücksprung)
	if route_type == 99:
		var down_y = max(start.y, end.y) + BACKFLOW_OFFSET_Y
		var left_x := end.x - BACKFLOW_OFFSET_X

		return [
			start,
			Vector2(start.x, down_y),
			Vector2(left_x, down_y),
			Vector2(left_x, end.y),
			end
		]

	# 1 = Bottom-Branch (Split ↓ →)
	if route_type == 1:
		var p := Vector2(start.x, end.y)
		return [start, p, end]

	# 2 = Top-Branch (Split ↑ →)
	if route_type == 2:
		var p := Vector2(start.x, end.y)
		return [start, p, end]

	# 3 = MERGE Top/Bottom (immer seitlich ins Gateway)
	if route_type == 3:
		var mid_x := end.x - 40  # kleiner Abstand vor dem Gateway
		return [
			start,
			Vector2(mid_x, start.y),
			Vector2(mid_x, end.y),
			end
		]


	# 4 = MERGE Mitte
	if route_type == 4:
		return [start, end]

	# 0 = Default (Dogleg)
	var mid_x := (start.x + end.x) * 0.5
	return [
		start,
		Vector2(mid_x, start.y),
		Vector2(mid_x, end.y),
		end
	]


func _update_arrow(pts: PackedVector2Array):
	if pts.size() < 2:
		return

	var p1: Vector2 = pts[pts.size() - 2]
	var p2: Vector2 = pts[pts.size() - 1]
	var dir: Vector2 = (p2 - p1).normalized()

	var arrow_offset := ARROW_BACK_OFFSET
	arrow.global_position = p2 - dir * arrow_offset


	# Pfeilrichtung bestimmen
	if abs(dir.x) > abs(dir.y):
		# Horizontal dominiert
		if dir.x > 0:
			arrow.rotation = deg_to_rad(0)     # →
		else:
			arrow.rotation = deg_to_rad(180)   # ←
	else:
		# Vertikal dominiert
		if dir.y > 0:
			arrow.rotation = deg_to_rad(90)    # ↓
		else:
			arrow.rotation = deg_to_rad(-90)   # ↑

func _get_port_center(port: Node2D) -> Vector2:
	# Exakte visuelle Mitte des Ports treffen
	if port is Area2D:
		for c in port.get_children():
			if c is CollisionShape2D and c.shape:
				var shape = c.shape
				if shape is RectangleShape2D:
					return port.global_position + c.position
	return port.global_position
