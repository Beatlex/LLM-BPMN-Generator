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

	line.points = _compute_path(start, end, route_type, dst_port)
	_update_arrow(line.points)


func _compute_path(
	start: Vector2,
	end: Vector2,
	route_type: int,
	dst_port: Node2D
) -> PackedVector2Array:

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
		return [start, Vector2(start.x, end.y), end]

	# 2 = Top-Branch (Split ↑ →)
	if route_type == 2:
		return [start, Vector2(start.x, end.y), end]

	# 3 = MERGE Top / Bottom → exakt horizontal auf Gateway-Kante
	if route_type == 3:
		var entry := _get_gateway_edge_entry(dst_port, start)
		return [
			start,
			Vector2(entry.x, start.y),
			entry
		]

	# 4 = MERGE Mitte → direkt
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

	# Pfeil exakt auf letzter Achse platzieren
	arrow.global_position = p2 - dir * ARROW_BACK_OFFSET

	# Rotation strikt achsenbasiert (keine Diagonalen!)
	if abs(dir.x) > abs(dir.y):
		arrow.rotation = 0.0 if dir.x > 0.0 else PI
	else:
		arrow.rotation = PI / 2 if dir.y > 0.0 else -PI / 2


func _get_port_center(port: Node2D) -> Vector2:
	if port is Area2D:
		for c in port.get_children():
			if c is CollisionShape2D and c.shape:
				return c.global_transform.origin
	return port.global_position


func _get_gateway_edge_entry(port: Node2D, from: Vector2) -> Vector2:
	# Gateway ist 45° gedreht, Ports liegen in den Ecken.
	# Ziel: Eintrittspunkt EXAKT auf der Gateway-KANTE

	var gateway := port.get_parent()
	var center: Vector2 = gateway.global_position

	var dx := from.x - center.x
	var dy := from.y - center.y

	# Horizontaler Eintritt (links/rechts)
	if abs(dx) > abs(dy):
		var sign_x := -1 if dx > 0.0 else 1
		return Vector2(
			center.x + sign_x * abs(port.global_position.x - center.x),
			center.y
		)

	# Vertikaler Eintritt (oben/unten)
	var sign_y := -1 if dy > 0.0 else 1
	return Vector2(
		center.x,
		center.y + sign_y * abs(port.global_position.y - center.y)
	)
