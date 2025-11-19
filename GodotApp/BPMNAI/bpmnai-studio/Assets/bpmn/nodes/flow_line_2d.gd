# res://Assets/bpmn/nodes/flow_line_2d.gd (oder wo du sie hast)
extends Node2D

@onready var line: Line2D   = $Line2D
@onready var arrow: Sprite2D = $ArrowHead

func _ready():
	arrow.z_index = 10

# NEU: bekommt nur noch Punkte
func setup(points: PackedVector2Array) -> void:
	line.points = points
	_update_arrow()


func _update_arrow():
	var pts := line.points
	if pts.size() < 2:
		return

	var p1 := pts[pts.size() - 2]
	var p2 := pts[pts.size() - 1]

	var dir := (p2 - p1).normalized()

	# Halbe Länge des Pfeils in Richtung der Linie
	var half_len := arrow.texture.get_width() * arrow.scale.x * 0.5

	# Pfeil auf Linie platzieren und um halbe Länge zurückversetzen
	arrow.position = p2 - dir * half_len
	arrow.rotation = dir.angle()
