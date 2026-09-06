class_name ModelUtils

## Ground a model so its mesh bottom sits at the given y_offset in world space.
static func ground_model(node: Node3D, y_offset: float = 0.0) -> void:
	var min_y := INF
	for child in node.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi and mi.mesh:
			var aabb = mi.get_aabb()
			for corner_idx in 8:
				var corner = aabb.get_endpoint(corner_idx)
				var world_y = mi.to_global(corner).y
				if world_y < min_y:
					min_y = world_y
	if min_y != INF and abs(min_y) > 0.001:
		node.position.y -= min_y - y_offset

## Tier 1: single AABB box collision for a model (static only).
static func add_collision(node: Node3D, collision_layer: int = 1) -> void:
	var aabb = _get_combined_aabb(node)
	if aabb.size.length() == 0:
		return
	var static_body = StaticBody3D.new()
	static_body.collision_layer = collision_layer
	static_body.collision_mask = 0
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = aabb.size
	col_shape.shape = box
	# _get_combined_aabb already returns the box in the node's LOCAL space, and
	# the shape is parented under the node — so the local centre is the offset.
	# (Subtracting global_position here shifted colliders far off the model and
	# produced invisible walls around every placed building.)
	col_shape.position = aabb.get_center()
	static_body.add_child(col_shape)
	node.add_child(static_body)

## Tier 2: per-part convex hull collision for irregular SOLID props.
const MAX_HULLS := 25
static func add_per_part_convex_collision(node: Node3D, collision_layer: int = 1) -> void:
	var meshes = node.find_children("*", "MeshInstance3D")
	var parts: Array[Dictionary] = []
	for child in meshes:
		var mi = child as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var aabb = mi.get_aabb()
		var vol = aabb.size.x * aabb.size.y * aabb.size.z
		parts.append({"mesh": mi, "volume": vol})
	parts.sort_custom(func(a, b): return a["volume"] > b["volume"])
	var filtered: Array[MeshInstance3D] = []
	for i in min(parts.size(), MAX_HULLS):
		filtered.append(parts[i]["mesh"])
	for mi in filtered:
		mi.create_convex_collision(true, true)
		for i in range(mi.get_child_count() - 1, -1, -1):
			if mi.get_child(i) is StaticBody3D:
				var sb = mi.get_child(i) as StaticBody3D
				sb.collision_layer = collision_layer
				sb.collision_mask = 0
				break

## Set animation loop modes: locomotion loops, attacks/hits/deaths are one-shot.
static func set_animation_loops(anim_player: AnimationPlayer) -> void:
	var oneshot_anims = ["jump", "attack", "slash", "shoot", "hurt", "die", "death",
		"fall", "climb", "dive", "hit", "cast", "throw", "reload", "pick_up", "roll", "dodge"]
	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)
		if not anim:
			continue
		var lower_name = anim_name.to_lower()
		var is_oneshot = false
		for keyword in oneshot_anims:
			if keyword in lower_name:
				is_oneshot = true
				break
		if is_oneshot:
			anim.loop_mode = Animation.LOOP_NONE
		else:
			anim.loop_mode = Animation.LOOP_LINEAR

## World-space height of a node's combined mesh AABB.
static func measure_height(node: Node3D) -> float:
	var min_y := INF
	var max_y := -INF
	for child in node.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi and mi.mesh:
			for corner_idx in 8:
				var corner = mi.get_aabb().get_endpoint(corner_idx)
				var world_y = mi.to_global(corner).y
				min_y = min(min_y, world_y)
				max_y = max(max_y, world_y)
	return max_y - min_y if min_y != INF else 0.0

## Scale a node so its world-space height matches target_meters.
static func scale_to_height(node: Node3D, target_meters: float) -> void:
	var current = measure_height(node)
	if current < 0.001:
		return
	var factor = target_meters / current
	node.scale *= factor


## Longest mesh-axis extent of a node's meshes (metres), honouring nested scales.
## Works even when the node is not yet inside the SceneTree (no global xforms).
static func measure_max_extent(node: Node3D) -> float:
	var max_e := 0.0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var scale_acc: Vector3 = mi.scale
		var p: Node = mi.get_parent()
		while p != null:
			if p is Node3D:
				scale_acc *= (p as Node3D).scale
			if p == node:
				break
			p = p.get_parent()
		var sz: Vector3 = mi.mesh.get_aabb().size
		sz = Vector3(absf(sz.x * scale_acc.x), absf(sz.y * scale_acc.y), absf(sz.z * scale_acc.z))
		max_e = maxf(max_e, maxf(sz.x, maxf(sz.y, sz.z)))
	return max_e


## Uniformly scale so the longest mesh axis equals target_meters.
## Use for world loot: Tripo/Kenney GLBs arrive at wildly different units and a
## fixed `scale = 0.55` still leaves giant blocks covering the camera.
static func scale_to_max_extent(node: Node3D, target_meters: float) -> void:
	var current := measure_max_extent(node)
	if current < 0.001:
		return
	node.scale *= target_meters / current

## One-call setup for movement-driven characters.
static func setup_character_for_movement(node: Node3D, target_height: float = 1.8) -> void:
	scale_to_height(node, target_height)
	ground_model(node)

## Return the Godot yaw that aims canonical MODEL_FRONT (-Z) along direction.
static func yaw_from_direction(direction: Vector3) -> float:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.000001:
		return 0.0
	flat = flat.normalized()
	return atan2(-flat.x, -flat.z)

## Aim a certified prop/environment instance along a world-space direction.
static func face_direction(node: Node3D, direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length_squared() < 0.000001:
		return
	node.rotation.y = yaw_from_direction(direction)

## Aim a certified prop/environment instance at a world-space target.
static func face_toward(node: Node3D, target: Vector3) -> void:
	face_direction(node, target - node.global_position)

static func _get_combined_aabb(node: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D"):
		var mesh_instance = child as MeshInstance3D
		if mesh_instance and mesh_instance.mesh:
			var child_aabb = mesh_instance.mesh.get_aabb()
			var child_transform = node.global_transform.inverse() * mesh_instance.global_transform
			var transformed_aabb = child_transform * child_aabb
			if first:
				combined = transformed_aabb
				first = false
			else:
				combined = combined.merge(transformed_aabb)
	return combined
