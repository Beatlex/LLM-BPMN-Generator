extends Node2D

@export var source_port: Area2D
@export var target_port: Area2D

@onready var line: Line2D = $Line2D
@onready var arrow: Sprite2D = $ArrowHead

func _ready():
	arrow.z_index = 10

func setup(source: Area2D, target: Area2D, lane_index := 0):
	source_port = source
	target_port = target

	# Convert global → local space of this FlowLine2D node
	var start_local = to_local(source_port.global_position)
	var end_local   = to_local(target_port.global_position)

	line.points = [start_local, end_local]

	_update_arrow()


func _update_arrow():
	var pts := line.points
	if pts.size() < 2:
		return

	var p1 := pts[pts.size() - 2]
	var p2 := pts[pts.size() - 1]

	# Richtung der Linie
	var dir := (p2 - p1).normalized()

	# Halbe Breite des Pfeils in Richtung berechnen
	var half_len := arrow.texture.get_width() * arrow.scale.x * 0.3

	# Pfeil auf Endpunkt setzen, dann zurückversetzen
	arrow.position = p2 - dir * half_len

	# Rotation exakt in Richtung der Linie
	arrow.rotation = dir.angle()
