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
	_update_arrow(line.points, dst_port)

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

	# 3 = MERGE Top / Bottom exakt auf Port-X sammeln, dann vertikal
	if route_type == 3:
		var port_pos := end 

		return [
			start,
			Vector2(port_pos.x, start.y), # horizontal bis exakt Port-X
			port_pos                        # vertikal in den Port
	]
	
	# 4 = MERGE Mitte 
	if route_type == 4:
		var epsilon := 1.0  # minimaler horizontaler Versatz
		return [
			start,
			Vector2(end.x + epsilon, end.y)
		]


	# 0 = Default (Dogleg)
	var mid_x := (start.x + end.x) * 0.5
	return [
		start,
		Vector2(mid_x, start.y),
		Vector2(mid_x, end.y),
		end
	]


func _update_arrow(pts: PackedVector2Array, dst_port: Node2D):
	if pts.size() < 2 or dst_port == null:
		return

	var end := pts[pts.size() - 1]
	var arrow_pos := end

	# ---- MERGE-GATEWAY-LOGIK ----
	var gateway := dst_port.get_parent()
	if gateway:
		var center = gateway.global_position
		var port_pos := dst_port.global_position

		var dx = port_pos.x - center.x
		var dy = port_pos.y - center.y

		# ---- MID (links → ins Gateway) ----
		if abs(dx) > abs(dy):
			arrow.rotation = 0.0               # →
			arrow.global_position = Vector2(
				port_pos.x - ARROW_BACK_OFFSET,
				port_pos.y
			)
			return

		# ---- TOP (oben → nach unten) ----
		if dy < 0.0:
			arrow.rotation = PI / 2            # ↓
			arrow.global_position = Vector2(
				port_pos.x,
				port_pos.y - ARROW_BACK_OFFSET
			)
			return

		# ---- BOTTOM (unten → nach oben) ----
		if dy > 0.0:
			arrow.rotation = -PI / 2           # ↑
			arrow.global_position = Vector2(
				port_pos.x,
				port_pos.y + ARROW_BACK_OFFSET
			)
			return

	# ---- FALLBACK (Tasks / Events) ----
	var p1 := pts[pts.size() - 2]
	var dir := (end - p1).normalized()
	arrow.global_position = end - dir * ARROW_BACK_OFFSET

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
