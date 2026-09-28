class_name ModelUtils

## Baked into exports so we can verify the PCK actually contains this revision.
const BUILD_FIX_TOKEN := "EOO_FIX_WARRIOR_STAND_V7"

## Tripo mesh id shared by spartan_hoplite + city_guard — UAL melts this bind.
const _BROKEN_UAL_MESH := "95ce6ed4"

## Ground a model so its mesh bottom sits at y_offset above its parent origin.
##
## Uses world-space mesh bounds, then moves via global_position.y so nested
## uniform scales (Gobkit Maya ×100 meshes, scale_to_height) cannot bury or
## float the mesh. `y_offset` is metres above the parent Node3D origin — for
## characters parented under a MeshRoot at terrain height pass 0; for props
## parented under the world root pass the terrain height (same as global Y).
static func ground_model(node: Node3D, y_offset: float = 0.0) -> void:
	if not node.is_inside_tree():
		return
	node.force_update_transform()
	var min_y := INF
	for child in node.find_children("*", "MeshInstance3D"):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if mi.is_inside_tree():
			mi.force_update_transform()
		var aabb: AABB = mi.get_aabb()
		for corner_idx in 8:
			var world_y: float = mi.to_global(aabb.get_endpoint(corner_idx)).y
			if world_y < min_y:
				min_y = world_y
	if min_y == INF:
		return
	var parent_y := 0.0
	var parent := node.get_parent()
	if parent is Node3D:
		parent_y = (parent as Node3D).global_position.y
	var target_y: float = parent_y + y_offset
	node.global_position.y += target_y - min_y

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


## Copy keys from `src` that fall in [start_s, end_s) into a new Animation,
## shifted so the slice starts at t=0. Used to carve Gobkit master timelines
## into idle / attack / dead / walk clips.
static func subclip_animation(src: Animation, start_s: float, end_s: float, loop: bool = false) -> Animation:
	var out := Animation.new()
	var length: float = maxf(0.05, end_s - start_s)
	out.length = length
	out.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if src == null:
		return out
	for ti in src.get_track_count():
		var path := src.track_get_path(ti)
		var type := src.track_get_type(ti)
		var new_ti := out.add_track(type)
		out.track_set_path(new_ti, path)
		out.track_set_interpolation_type(new_ti, src.track_get_interpolation_type(ti))
		out.track_set_enabled(new_ti, src.track_is_enabled(ti))
		var kc: int = src.track_get_key_count(ti)
		for ki in kc:
			var t: float = src.track_get_key_time(ti, ki)
			if t < start_s - 0.0001 or t > end_s + 0.0001:
				continue
			var local_t: float = clampf(t - start_s, 0.0, length)
			var trans: float = src.track_get_key_transition(ti, ki)
			match type:
				Animation.TYPE_VALUE, Animation.TYPE_BLEND_SHAPE:
					out.track_insert_key(new_ti, local_t, src.track_get_key_value(ti, ki), trans)
				Animation.TYPE_POSITION_3D:
					out.position_track_insert_key(new_ti, local_t, src.position_track_interpolate(ti, t))
				Animation.TYPE_ROTATION_3D:
					out.rotation_track_insert_key(new_ti, local_t, src.rotation_track_interpolate(ti, t))
				Animation.TYPE_SCALE_3D:
					out.scale_track_insert_key(new_ti, local_t, src.scale_track_interpolate(ti, t))
				_:
					# Best-effort for other track types.
					out.track_insert_key(new_ti, local_t, src.track_get_key_value(ti, ki), trans)
		# Guarantee a key at the slice start/end so the pose doesn't pop.
		if out.track_get_key_count(new_ti) == 0:
			match type:
				Animation.TYPE_POSITION_3D:
					out.position_track_insert_key(new_ti, 0.0, src.position_track_interpolate(ti, start_s))
				Animation.TYPE_ROTATION_3D:
					out.rotation_track_insert_key(new_ti, 0.0, src.rotation_track_interpolate(ti, start_s))
				Animation.TYPE_SCALE_3D:
					out.scale_track_insert_key(new_ti, 0.0, src.scale_track_interpolate(ti, start_s))
				Animation.TYPE_VALUE, Animation.TYPE_BLEND_SHAPE:
					out.track_insert_key(new_ti, 0.0, src.value_track_interpolate(ti, start_s))
	return out

## World-space visual height. Prefer skeleton bone extents when the bind-pose
## mesh AABB is tiny (common with Maya-cm packs like Gobkit whose authored
## MeshInstance scale of 100 is dropped on import — mesh ~5cm, bones ~3m).
static func measure_height(node: Node3D) -> float:
	_restore_maya_cm_mesh_scales(node)
	if node.is_inside_tree():
		node.force_update_transform()
	var mesh_h := _measure_mesh_height(node)
	var bone_h := _measure_skeleton_height(node)
	if bone_h > 0.4:
		# Skeleton is the ground truth for skinned Maya-cm packs.
		if mesh_h < 0.05 or absf(mesh_h - bone_h) / bone_h > 0.45:
			return bone_h
	if bone_h > 0.05 and mesh_h < 0.05:
		return bone_h
	return mesh_h if mesh_h >= 0.001 else bone_h


## Gobkit / Maya cm packs: do NOT set MeshInstance.scale=100 when the Skin
## bind poses already encode that scale (common after glTF import). Doing both
## doubles the deform and flings giant meshes into the sky while the body
## hitbox stays on the ground.
static func _restore_maya_cm_mesh_scales(node: Node3D) -> void:
	for child in node.find_children("*", "MeshInstance3D"):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local_h: float = mi.get_aabb().size.y
		if local_h <= 0.0 or local_h >= 0.15:
			continue
		if mi.scale.y >= 50.0:
			continue
		# Skin bind pose already carries ~×100 → leave MI scale at 1.
		if mi.skin != null and mi.skin.get_bind_count() > 0:
			var bind_s: Vector3 = mi.skin.get_bind_pose(0).basis.get_scale()
			if bind_s.length() > 50.0:
				continue
		mi.scale = Vector3(100.0, 100.0, 100.0)


static func _measure_mesh_height(node: Node3D) -> float:
	var min_y := INF
	var max_y := -INF
	for child in node.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi and mi.mesh:
			if mi.is_inside_tree():
				mi.force_update_transform()
			for corner_idx in 8:
				var corner = mi.get_aabb().get_endpoint(corner_idx)
				var world_y = mi.to_global(corner).y
				min_y = min(min_y, world_y)
				max_y = max(max_y, world_y)
	return max_y - min_y if min_y != INF else 0.0


static func _measure_skeleton_height(node: Node3D) -> float:
	var min_y := INF
	var max_y := -INF
	for child in node.find_children("*", "Skeleton3D"):
		var skel := child as Skeleton3D
		if skel == null:
			continue
		if skel.is_inside_tree():
			skel.force_update_transform()
		for bi in skel.get_bone_count():
			var gt := skel.global_transform * skel.get_bone_global_pose(bi)
			var y: float = gt.origin.y
			min_y = min(min_y, y)
			max_y = max(max_y, y)
	return max_y - min_y if min_y != INF else 0.0


## Longest side of the combined mesh AABB in the node's local space (metres).
## Used by ground loot to pocket-size gear GLBs without stretching by height alone.
static func measure_max_extent(node: Node3D) -> float:
	if node == null:
		return 0.0
	if node.is_inside_tree():
		node.force_update_transform()
	var aabb := _get_combined_aabb(node)
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest >= 0.001:
		return longest
	# Fallback when meshes aren't ready / AABB empty — height is still useful.
	return measure_height(node)


## Uniformly scale so the longest mesh side matches target_meters.
static func scale_to_max_extent(node: Node3D, target_meters: float) -> void:
	if node == null or target_meters <= 0.0:
		return
	if node.is_inside_tree():
		node.force_update_transform()
	var current := measure_max_extent(node)
	if current < 0.001:
		return
	var factor := target_meters / current
	# Props can be tiny authored units or oversized Tripo meshes — keep sane.
	factor = clampf(factor, 0.01, 80.0)
	node.scale *= factor
	if node.is_inside_tree():
		node.force_update_transform()
		var final_e := measure_max_extent(node)
		if final_e > target_meters * 1.25 and final_e > 0.01:
			node.scale *= target_meters / final_e


## Scale a node so its world-space height matches target_meters.
static func scale_to_height(node: Node3D, target_meters: float) -> void:
	_restore_maya_cm_mesh_scales(node)
	if node.is_inside_tree():
		node.force_update_transform()
	# Prefer skeleton for Maya-cm skinned packs — mesh AABB alone over-scales.
	var bone_h := _measure_skeleton_height(node)
	var mesh_h := _measure_mesh_height(node)
	var current: float = mesh_h
	if bone_h > 0.4:
		current = bone_h
	elif mesh_h >= 0.001:
		current = mesh_h
	if current < 0.001:
		return
	var factor := target_meters / current
	# Hard clamp: never amplify more than 4× (prevents giant skinned animals).
	if factor > 4.0 or factor < 0.05:
		push_warning("ModelUtils.scale_to_height: clamping factor %.3f (h=%.3f → %.3f) on %s" % [factor, current, target_meters, node.name])
		factor = clampf(factor, 0.05, 4.0)
	node.scale *= factor
	# Final safety: if the skinned mesh is still oversized, shrink to target.
	if node.is_inside_tree():
		node.force_update_transform()
		var final_h := _measure_mesh_height(node)
		if final_h > target_meters * 1.35 and final_h > 0.01:
			node.scale *= target_meters / final_h


## If the skinned mesh is still absurdly tall after setup, force it down.
## Catches Maya-cm / import failures that leave giants floating above the body.
static func clamp_world_height(node: Node3D, max_height: float, target_height: float = -1.0) -> void:
	if not node.is_inside_tree():
		return
	node.force_update_transform()
	var h := _measure_mesh_height(node)
	if h <= max_height or h < 0.001:
		return
	var want: float = target_height if target_height > 0.0 else max_height
	node.scale *= want / h
	node.force_update_transform()
	ground_model(node)
	push_warning("ModelUtils.clamp_world_height: shrank %s from %.2fm to ~%.2fm" % [node.name, h, want])


## Setup for Maya-cm animals (Gobkit): scale by skeleton only.
## Skin bind poses already include the authored ×100 — never set MI.scale=100.
static func setup_maya_cm_animal(node: Node3D, target_height: float) -> void:
	_restore_maya_cm_mesh_scales(node)  # no-op when binds already encode ×100
	if node.is_inside_tree():
		node.force_update_transform()
	var bone_h := _measure_skeleton_height(node)
	if bone_h < 0.05:
		bone_h = _measure_mesh_height(node)
	if bone_h >= 0.05:
		node.scale *= target_height / bone_h
	if node.is_inside_tree():
		node.force_update_transform()
	ground_model(node)

## One-call setup for movement-driven characters.
static func setup_character_for_movement(node: Node3D, target_height: float = 1.8) -> void:
	# Keep BUILD_FIX_TOKEN live in exported bytecode (unused consts are stripped).
	if node == null and BUILD_FIX_TOKEN.is_empty():
		return
	scale_to_height(node, target_height)
	if node.is_inside_tree():
		node.force_update_transform()
	ground_model(node)
	## Tripo+UAL melts legs into a Z-shape. Plant legs to rest after every pose.
	install_leg_plant_fix(node)


## Legacy no-op — hip/chest pitch hacks made heroes look less human.
static func correct_sky_gaze(_skel: Skeleton3D, _strength: float = 1.0) -> void:
	return


## Soften positive local-X pitch (unused; kept for older tool scripts).
static func _dampen_local_pitch(skel: Skeleton3D, bone_name: String, strength: float) -> void:
	var bone_i := skel.find_bone(bone_name)
	if bone_i < 0:
		return
	var e: Vector3 = skel.get_bone_pose_rotation(bone_i).get_euler()
	if e.x <= 0.01:
		return
	e.x = lerpf(e.x, 0.0, clampf(strength, 0.0, 1.0))
	skel.set_bone_pose_rotation(bone_i, Quaternion.from_euler(e))


## Legacy alias.
static func install_sky_gaze_fix(model: Node3D) -> void:
	install_leg_plant_fix(model)


## Plant torso+legs to rest after AnimationPlayer (broken Tripo warrior only).
static func install_leg_plant_fix(model: Node3D) -> void:
	if model == null:
		return
	if not _mesh_needs_ual_plant(model):
		return
	var skel: Skeleton3D = null
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	if skel == null:
		return
	if skel.has_node("LegPlantFix"):
		return
	var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null:
		anim.process_priority = -100
	var fix := Node.new()
	fix.name = "LegPlantFix"
	fix.set_script(load("res://scripts/utils/leg_plant_fix.gd"))
	fix.process_priority = 1000
	skel.add_child(fix)


static func _mesh_needs_ual_plant(model: Node3D) -> bool:
	var nlow := String(model.name).to_lower()
	if "spartan" in nlow or "hoplite" in nlow or "city_guard" in nlow or "guard" in nlow:
		return true
	for n in model.find_children("*", "MeshInstance3D", true, false):
		if _BROKEN_UAL_MESH in String(n.name):
			return true
	return false

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
