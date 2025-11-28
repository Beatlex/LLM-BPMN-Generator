extends Node2D

@onready var line: Line2D = $Line2D
@onready var arrow: Sprite2D = $ArrowHead

const ARROW_BACK_OFFSET := 12


func _ready():
	z_index = -10
	line.z_index = -10       # immer hinter Tasks
	arrow.z_index = 10       # Pfeil über Linie


func setup(src_port: Node2D, dst_port: Node2D, route_type := 0) -> void:
	if line == null: await ready
	if line == null:
		push_error("[FlowLine2D] ⚠ Fehlende Line2D!!")
		return

	var start := src_port.global_position
	var end   := dst_port.global_position

	line.points = _compute_path(start, end, route_type)
	_update_arrow(line.points)


func _compute_path(start: Vector2, end: Vector2, route_type: int) -> PackedVector2Array:
	var pts: PackedVector2Array = []

	# 1 = Bottom-Branch (Split ↓ →)
	if route_type == 1:
		var p := Vector2(start.x, end.y)
		return [start, p, end]

	# 2 = Top-Branch (Split ↑ →)
	if route_type == 2:
		var p := Vector2(start.x, end.y)
		return [start, p, end]

	# 3 = MERGE Top/Bottom:
	#     erst auf X des Gateways, dann vertikal rein
	if route_type == 3:
		var p := Vector2(end.x, start.y)
		return [start, p, end]

	# 4 = MERGE Mitte:
	#     direkt horizontal rein
	if route_type == 4:
		return [start, end]

	# 0 / Default: Standard-Dogleg (z. B. Task → Task)
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

	var p1: Vector2 = pts[pts.size()-2]
	var p2: Vector2 = pts[pts.size()-1]
	var dir: Vector2 = (p2 - p1).normalized()

	# Pfeil leicht zurück ziehen
	arrow.global_position = p2 - dir * ARROW_BACK_OFFSET

	# ----------------------------------------------
	# ⭐ MERGE-Gateway Fix — Output MUSS nach rechts!
	# ----------------------------------------------
	# Fall: Letzter Flow-Pfad verläuft überwiegend vertikal → korrigieren auf →
	if abs(dir.x) < abs(dir.y) and p2.x > p1.x:
		arrow.rotation = deg_to_rad(0)      # →
		return

	# Falls er theoretisch nach links zeigen würde
	if abs(dir.x) < abs(dir.y) and p2.x < p1.x:
		arrow.rotation = deg_to_rad(180)    # ← (selten, aber safe)
		return


	if abs(dir.x) > abs(dir.y):
		# Horizontal dominiert
		if dir.x > 0:
			arrow.rotation = deg_to_rad(0)    # →
		else:
			arrow.rotation = deg_to_rad(180)  # ←
	else:
		# Vertikal dominiert
		if dir.y > 0:
			arrow.rotation = deg_to_rad(90)   # ↓
		else:
			arrow.rotation = deg_to_rad(-90)  # ↑
