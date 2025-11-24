extends Camera2D

@export var target_root_path: NodePath
@export var margin := 200.0      # Extra Rand um das Diagramm herum
@export var smooth := true
@export var smooth_speed := 6.0


func _process(delta):
	if not target_root_path:
		return

	var root = get_node(target_root_path)
	if root == null:
		return

	var bounds = _compute_aabb(root)
	if bounds.size == Vector2.ZERO:
		return

	# Kamera-Zentrum setzen
	var target_pos = bounds.position + bounds.size * 0.5

	if smooth:
		global_position = global_position.lerp(target_pos, delta * smooth_speed)
	else:
		global_position = target_pos

	# Kamera-Zoom bestimmen
	var viewport_size = get_viewport_rect().size

	var zoom_x = (bounds.size.x + margin) / viewport_size.x
	var zoom_y = (bounds.size.y + margin) / viewport_size.y

	var target_zoom = max(zoom_x, zoom_y)

	if smooth:
		zoom = zoom.lerp(Vector2(target_zoom, target_zoom), delta * smooth_speed)
	else:
		zoom = Vector2(target_zoom, target_zoom)


func _compute_aabb(root: Node) -> Rect2:
	var first := true
	var aabb := Rect2()

	for c in root.get_children():
		if not (c is Node2D):
			continue

		var pos = c.global_position

		if first:
			aabb.position = pos
			aabb.size = Vector2.ZERO
			first = false
		else:
			aabb = aabb.expand(pos)

	return aabb
