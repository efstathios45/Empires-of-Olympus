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
	var oneshot_anims = ["jump", "attack", "atack", "slash", "shoot", "firing", "hurt", "die", "death",
		"fall", "climb", "dive", "hit", "cast", "throw", "reload", "pick_up", "roll", "dodge", "unsheath", "strike"]
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

## Put a posed skeleton's body over the parent origin and its feet on y=0.
## Skinned-mesh AABBs stay on the bind pose, so bone positions are the guide.
static func align_skeleton_to_ground(node: Node3D) -> void:
	var skel := node.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null:
		center_model_xz(node)
		ground_model(node)
		return
	skel.force_update_all_bone_transforms()
	var min_y := INF
	var anchor := Vector3.ZERO
	var have_anchor := false
	for i in skel.get_bone_count():
		var bone_name := str(skel.get_bone_name(i))
		var world: Vector3 = skel.to_global(skel.get_bone_global_pose(i).origin)
		if (bone_name.begins_with("RootBone") or bone_name.begins_with("ROOT BODY")) and not have_anchor:
			anchor = world
			have_anchor = true
		var lower := bone_name.to_lower()
		var is_end := "end" in lower
		if not is_end and ("hoof" in lower or lower.begins_with("foot") or ".foot" in lower or lower.begins_with("ik foot")):
			min_y = minf(min_y, world.y)
	var parent := node.get_parent() as Node3D
	var parent_basis := Basis.IDENTITY
	var target := Vector3.ZERO
	if parent:
		parent_basis = parent.global_transform.basis
		target = parent.global_position
	if have_anchor:
		var delta := Vector3(anchor.x - target.x, 0.0, anchor.z - target.z)
		var local_delta := parent_basis.inverse() * delta
		node.position.x -= local_delta.x
		node.position.z -= local_delta.z
	else:
		center_model_xz(node)
	if min_y < INF and min_y > -1000.0:
		node.position.y -= min_y

## Shift a model so its mesh AABB sits on the node's XZ origin.
## Some Sketchfab rigs are authored several metres away from the scene root.
static func center_model_xz(node: Node3D) -> void:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for child in node.find_children("*", "MeshInstance3D"):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var aabb := mi.get_aabb()
		for corner_idx in 8:
			var world: Vector3 = mi.to_global(aabb.get_endpoint(corner_idx))
			min_x = minf(min_x, world.x)
			max_x = maxf(max_x, world.x)
			min_z = minf(min_z, world.z)
			max_z = maxf(max_z, world.z)
	if min_x == INF:
		return
	var delta := Vector3((min_x + max_x) * 0.5, 0.0, (min_z + max_z) * 0.5) - node.global_position
	delta.y = 0.0
	# position is in the parent frame. The node's own scale must not be inverted.
	var parent_basis := Basis.IDENTITY
	if node.get_parent() is Node3D:
		parent_basis = (node.get_parent() as Node3D).global_transform.basis
	var local_delta := parent_basis.inverse() * delta
	node.position.x -= local_delta.x
	node.position.z -= local_delta.z

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
