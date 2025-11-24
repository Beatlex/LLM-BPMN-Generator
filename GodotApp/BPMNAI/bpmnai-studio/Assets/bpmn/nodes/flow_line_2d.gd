extends Node2D

@onready var line: Line2D = $Line2D
@onready var arrow: Sprite2D = $ArrowHead

# small padding so arrowhead doesn't overlap port
const ARROW_BACK_OFFSET := 12


func _ready():
	print("[FlowLine2D] SELF = ", self.name)
	print("[FlowLine2D] CHILDREN = ", get_children())
	arrow.z_index = 10


# -------------------------------------------------------
# Setup mit Ports + lane_index (Beta)
# -------------------------------------------------------
func setup(src_port: Node2D, dst_port: Node2D, route_type := 0) -> void:

	if line == null:
		# Sicherstellen, dass die Subnodes verfügbar sind
		await ready

	if line == null:
		push_error("[FlowLine2D] FEHLER: line == null (Scene falsch aufgebaut?)")
		return

	var start := src_port.global_position
	var end := dst_port.global_position

	var pts := _compute_path(start, end, route_type)
	line.points = pts
	_update_arrow(pts)



# -------------------------------------------------------
# Beta-Routing
# -------------------------------------------------------
func _compute_path(start: Vector2, end: Vector2, route_type: int) -> PackedVector2Array:
	var pts: PackedVector2Array = []

	# route_type:
	# 0 = normaler rechter Ausgang (→)
	# 1 = unterer Ausgang (↓ →)

	if route_type == 1:
		# DOWN-Pfad → Nur 1 Knick
		# 1) runter auf Höhe des Childs
		var p_down := Vector2(start.x, end.y)
		pts.append(start)
		pts.append(p_down)
		pts.append(end)
		return pts

	# DEFAULT: alter 2-Knick horizontaler Pfad
	var mid_x := (start.x + end.x) * 0.5

	pts.append(start)
	pts.append(Vector2(mid_x, start.y))
	pts.append(Vector2(mid_x, end.y))
	pts.append(end)
	return pts


# -------------------------------------------------------
# Pfeil-Ausrichtung
# -------------------------------------------------------
func _update_arrow(pts: PackedVector2Array) -> void:
	if pts.size() < 2:
		return

	var p1 := pts[pts.size() - 2]
	var p2 := pts[pts.size() - 1]

	var dir := (p2 - p1).normalized()

	arrow.global_position = p2 - dir * ARROW_BACK_OFFSET
	arrow.rotation = dir.angle()
