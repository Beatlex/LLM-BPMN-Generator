extends Node
class_name LayoutEngine

const Y_TOLERANCE := 2.0
const BRANCH_OFFSET_Y := 400.0


# -------------------------------------------------------------------
# 1) Allgemeines Routing für „normale“ Flows (Task → Task, Start → Task)
# -------------------------------------------------------------------
func route_between_ports(a, b, c=null, d=null, opts := {}):
	# Backward compatibility:
	# Old signature: route_between_ports(source_port, target_port, flow_line)
	if c is Node2D and d == null:
		var source_port = a
		var target_port = b
		var flow_line   = c

		var start_world = source_port.global_position
		var end_world   = target_port.global_position

		var world_pts = _compute_manhattan_path(start_world, end_world)

		var local_pts := PackedVector2Array()
		for p in world_pts:
			local_pts.append(flow_line.to_local(p))

		flow_line.setup(local_pts)
		return local_pts

	# New signature:
	# route_between_ports(source_node, source_port, target_node, target_port)
	var source_node = a
	var source_port = b
	var target_node = c
	var target_port = d

	var start = source_node.get_port_global_position(source_port)
	var end   = target_node.get_port_global_position(target_port)

	return _compute_manhattan_path(start, end)



# -------------------------------------------------------------------
# 2) Gateway-Branch (Option A – funktioniert perfekt!)
# -------------------------------------------------------------------
func route_gateway_branch(
		source_node,
		source_port: Area2D,
		target_node,
		target_port: Area2D,
		branch_index: int
	) -> PackedVector2Array:

	var start = source_node.get_port_global_position(source_port)
	var end   = target_node.get_port_global_position(target_port)

	# Geradeaus (YES)
	if branch_index == 0:
		return PackedVector2Array([start, end])

	# Abzweigung (NO) – 1 Knick-Regel
	var mid1 := Vector2(start.x, start.y + BRANCH_OFFSET_Y * branch_index)
	var mid2 := Vector2(end.x,   start.y + BRANCH_OFFSET_Y * branch_index)

	return PackedVector2Array([start, mid1, mid2, end])


# -------------------------------------------------------------------
# 3) EndEvent-Sammel-Route (Option C – deine Vorgabe)
# -------------------------------------------------------------------
func route_collect_to_end(
		source_node,
		source_port: Area2D,
		end_node,
		end_input_port: Area2D
	) -> PackedVector2Array:

	var start = source_node.get_port_global_position(source_port)
	var end   = end_node.get_port_global_position(end_input_port)

	# Sammeln auf Y-Achse des EndEvents
	var mid := Vector2(start.x, end.y)

	return PackedVector2Array([start, mid, end])


# -------------------------------------------------------------------
# 4) Einfaches Manhattan-Routing (max. 1 Knick)
# -------------------------------------------------------------------
func _compute_manhattan_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(start)

	if abs(start.y - end.y) <= Y_TOLERANCE:
		# gleiche Höhe → direkt
		pts.append(end)
	else:
		# ein Knick
		var corner := Vector2(start.x, end.y)
		pts.append(corner)
		pts.append(end)

	return pts
	
	# -------------------------------------------------------------------
# 5) Merge-Routing für Ziele mit mehreren eingehenden Flows
# -------------------------------------------------------------------
func route_merge_to_target(
		source_nodes: Array,
		source_ports: Array,
		target_node,
		target_port: Area2D
	) -> Dictionary:

	var result := {}

	# 1) Alle Startpositionen sammeln
	var starts: Array = []
	for i in range(source_nodes.size()):
		starts.append(source_nodes[i].get_port_global_position(source_ports[i]))

	# 2) Zielposition
	var end_pos: Vector2 = target_node.get_port_global_position(target_port)

	# 3) Halbpunkt der horizontalen Strecke
	#    -> Stränge laufen bis zur Hälfte parallel
	var max_start_x := -999999.0
	for s in starts:
		if s.x > max_start_x:
			max_start_x = s.x

	var half_x = lerp(max_start_x, end_pos.x, 0.5)

	# 4) Merge-Y = Mittelwert aller Starts
	var sum_y := 0.0
	for s in starts:
		sum_y += s.y
	var merge_y := sum_y / starts.size()

	# 5) Für jeden Startpfad erzeugen
	for i in range(starts.size()):
		var s: Vector2 = starts[i]
		var pts := PackedVector2Array()

		# 1. Startpunkt
		pts.append(s)

		# 2. Erst bis zur halben Strecke (parallel!)
		var half_point := Vector2(half_x, s.y)
		pts.append(half_point)

		# 3. Von halber Strecke auf Merge-Y
		var merge_point := Vector2(half_x, merge_y)
		pts.append(merge_point)

		# 4. Von dort direkt in den EndEvent-Port
		pts.append(end_pos)

		result[source_nodes[i]] = pts

	return result
