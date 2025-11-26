extends Node2D

@onready var line: Line2D = $Line2D
@onready var arrow: Sprite2D = $ArrowHead

const ARROW_BACK_OFFSET := 12


func _ready():
	z_index = -10
	line.z_index = -10       # immer hinter Tasks
	arrow.z_index = 10       # Pfeil über Linie


# ============================================================
#  Setup vom Flow → Routing wird aus route_type abgeleitet
# ============================================================
func setup(src_port: Node2D, dst_port: Node2D, route_type := 0) -> void:
	if line == null: await ready
	if line == null:
		push_error("[FlowLine2D] ⚠ Fehlende Line2D!!")
		return

	var start := src_port.global_position
	var end   := dst_port.global_position

	line.points = _compute_path(start, end, route_type)
	_update_arrow(line.points)



# ============================================================
#   Routing-Varianten
#
# 0 → Standard Horizontal
# 1 → Bottom-Branch (↓ →)
# 2 → Top-Branch    (↑ →)
# 3 → Merge-Gateway (→ x-Achse ↘ oder ↗)
#
# ============================================================
func _compute_path(start: Vector2, end: Vector2, route_type:int) -> PackedVector2Array:
	var pts: PackedVector2Array = []

	# ========================================================
	# 1) Bottom Branch  (Split → Child unten)
	# ========================================================
	if route_type == 1:
		var p := Vector2(start.x, end.y)       # runter bis Y Zielnode → direkt rein
		return [start, p, end]


	# ========================================================
	# 2) Top Branch  (Split → Child oben)
	# ========================================================
	if route_type == 2:
		var p := Vector2(start.x, end.y)       # hoch auf Y Node → dann rein
		return [start, p, end]


	# ========================================================
	# 3) MERGE: sauberes Einsammeln (rot/blau korrekt!)
	#
	#    🔥 Verhalten:
	#    - erst zu Gateway-X verschwenken
	#    - dann auf Y des Gateways einsammeln
	#    - schöner gleichlanger Knick → kein Mix-Mess
	# ========================================================
	if route_type == 3:
		var x_merge := end.x - 80               # kleiner Soft-Offset → kein hartes Kreuz
		var y_merge := end.y

		return [
			start,
			Vector2(x_merge, start.y),          # 1. Knick: horizontale Annäherung
			Vector2(x_merge, y_merge),          # 2. Knick: vertikal einsteuern
			end
		]


	# ========================================================
	# 0) DEFAULT — Normal Horizontal Routing
	# ========================================================
	var mid_x := (start.x + end.x) * 0.5
	return [
		start,
		Vector2(mid_x, start.y),
		Vector2(mid_x, end.y),
		end
	]


# ============================================================
# Pfeil-Orientierung
# ============================================================
func _update_arrow(pts:PackedVector2Array):
	if pts.size() < 2: return
	var p1 = pts[pts.size()-2]
	var p2 = pts[pts.size()-1]
	var dir = (p2-p1).normalized()
	arrow.global_position = p2 - dir * ARROW_BACK_OFFSET
	arrow.rotation = dir.angle()
