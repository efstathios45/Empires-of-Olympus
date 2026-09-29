class_name ModelUtils


const BUILD_FIX_TOKEN: = "EOO_FIX_HELLENIC_NPC_POSE_V1"


const _BROKEN_UAL_MESH: = "95ce6ed4"








static func ground_model(node: Node3D, y_offset: float = 0.0) -> void :
	if not node.is_inside_tree():
		return
	node.force_update_transform()
	var min_y: = INF
	for child in node.find_children("*", "MeshInstance3D"):
		var mi: = child as MeshInstance3D
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
	var parent_y: = 0.0
	var parent: = node.get_parent()
	if parent is Node3D:
		parent_y = (parent as Node3D).global_position.y
	var target_y: float = parent_y + y_offset
	node.global_position.y += target_y - min_y


static func add_collision(node: Node3D, collision_layer: int = 1) -> void :
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




	col_shape.position = aabb.get_center()
	static_body.add_child(col_shape)
	node.add_child(static_body)


const MAX_HULLS: = 25
static func add_per_part_convex_collision(node: Node3D, collision_layer: int = 1) -> void :
	var meshes = node.find_children("*", "MeshInstance3D")
	var parts: Array[Dictionary] = []
	for child in meshes:
		var mi = child as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var aabb = mi.get_aabb()
		var vol = aabb.size.x * aabb.size.y * aabb.size.z
		parts.append({"mesh": mi, "volume": vol})
	parts.sort_custom( func(a, b): return a["volume"] > b["volume"])
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


static func set_animation_loops(anim_player: AnimationPlayer) -> void :
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





const _ARM_TRACK_KEYS: = [
	"Shoulder", "UpperArm", "LowerArm", "Wrist", 
	"Thumb", "Index", "Middle", "Ring", "Pinky", 
]

static func _bone_name_is_arm(bone_name: String) -> bool:
	for key in _ARM_TRACK_KEYS:
		if key in bone_name:
			return true
	return false



# Disabled: the greek_hoplite clips animate the arms correctly on their own
# (verified: every arm bone has motion tracks). The old "hang arms" hack sampled
# a pose before the skeleton had applied the animation, captured the T-pose rest,
# then stripped the good arm tracks and pinned that T-pose — which is exactly why
# the hero (and anything routed through here) looked T-posed. Letting the source
# animation drive the arms restores natural idle/walk/attack and weapon holding.
static func _setup_achilles_hang_arms(_model: Node3D) -> void :
	return


static func strip_arm_animation_tracks(anim_player: AnimationPlayer) -> void :
	if anim_player == null:
		return

	for lib_name in anim_player.get_animation_library_list():
		var lib: AnimationLibrary = anim_player.get_animation_library(lib_name)
		if lib == null:
			continue
		for anim_name in lib.get_animation_list():
			var src: = lib.get_animation(anim_name)
			if src == null:
				continue
			var anim: Animation = src.duplicate(true)
			for ti in range(anim.get_track_count() - 1, -1, -1):
				var path: = String(anim.track_get_path(ti))
				var hit: = false
				for key in _ARM_TRACK_KEYS:
					if key in path:
						hit = true
						break
				if hit:
					anim.remove_track(ti)
			lib.add_animation(anim_name, anim)





static func subclip_animation(src: Animation, start_s: float, end_s: float, loop: bool = false) -> Animation:
	var out: = Animation.new()
	var length: float = maxf(0.05, end_s - start_s)
	out.length = length
	out.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if src == null:
		return out
	for ti in src.get_track_count():
		var path: = src.track_get_path(ti)
		var type: = src.track_get_type(ti)
		var new_ti: = out.add_track(type)
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

					out.track_insert_key(new_ti, local_t, src.track_get_key_value(ti, ki), trans)

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




static func measure_height(node: Node3D) -> float:
	_restore_maya_cm_mesh_scales(node)
	if node.is_inside_tree():
		node.force_update_transform()
	var mesh_h: = _measure_mesh_height(node)
	var bone_h: = _measure_skeleton_height(node)
	if bone_h > 0.4:

		if mesh_h < 0.05 or absf(mesh_h - bone_h) / bone_h > 0.45:
			return bone_h
	if bone_h > 0.05 and mesh_h < 0.05:
		return bone_h
	return mesh_h if mesh_h >= 0.001 else bone_h






static func _restore_maya_cm_mesh_scales(node: Node3D) -> void :
	for child in node.find_children("*", "MeshInstance3D"):
		var mi: = child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local_h: float = mi.get_aabb().size.y
		if local_h <= 0.0 or local_h >= 0.15:
			continue
		if mi.scale.y >= 50.0:
			continue

		if mi.skin != null and mi.skin.get_bind_count() > 0:
			var bind_s: Vector3 = mi.skin.get_bind_pose(0).basis.get_scale()
			if bind_s.length() > 50.0:
				continue
		mi.scale = Vector3(100.0, 100.0, 100.0)


static func _measure_mesh_height(node: Node3D) -> float:
	var min_y: = INF
	var max_y: = - INF
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
	var min_y: = INF
	var max_y: = - INF
	for child in node.find_children("*", "Skeleton3D"):
		var skel: = child as Skeleton3D
		if skel == null:
			continue
		if skel.is_inside_tree():
			skel.force_update_transform()
		for bi in skel.get_bone_count():
			var gt: = skel.global_transform * skel.get_bone_global_pose(bi)
			var y: float = gt.origin.y
			min_y = min(min_y, y)
			max_y = max(max_y, y)
	return max_y - min_y if min_y != INF else 0.0




static func measure_max_extent(node: Node3D) -> float:
	if node == null:
		return 0.0
	if node.is_inside_tree():
		node.force_update_transform()
	var aabb: = _get_combined_aabb(node)
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest >= 0.001:
		return longest

	return measure_height(node)



static func scale_to_max_extent(node: Node3D, target_meters: float) -> void :
	if node == null or target_meters <= 0.0:
		return
	if node.is_inside_tree():
		node.force_update_transform()
	var current: = measure_max_extent(node)
	if current < 0.001:
		return
	var factor: = target_meters / current

	factor = clampf(factor, 0.01, 80.0)
	node.scale *= factor
	if node.is_inside_tree():
		node.force_update_transform()
		var final_e: = measure_max_extent(node)
		if final_e > target_meters * 1.25 and final_e > 0.01:
			node.scale *= target_meters / final_e



static func scale_to_height(node: Node3D, target_meters: float) -> void :
	_restore_maya_cm_mesh_scales(node)
	if node.is_inside_tree():
		node.force_update_transform()

	var bone_h: = _measure_skeleton_height(node)
	var mesh_h: = _measure_mesh_height(node)
	var current: float = mesh_h
	if bone_h > 0.4:
		current = bone_h
	elif mesh_h >= 0.001:
		current = mesh_h
	if current < 0.001:
		return
	var factor: = target_meters / current

	if factor > 4.0 or factor < 0.05:
		push_warning("ModelUtils.scale_to_height: clamping factor %.3f (h=%.3f → %.3f) on %s" % [factor, current, target_meters, node.name])
		factor = clampf(factor, 0.05, 4.0)
	node.scale *= factor

	if node.is_inside_tree():
		node.force_update_transform()
		var final_h: = _measure_mesh_height(node)
		if final_h > target_meters * 1.35 and final_h > 0.01:
			node.scale *= target_meters / final_h




static func clamp_world_height(node: Node3D, max_height: float, target_height: float = -1.0) -> void :
	if not node.is_inside_tree():
		return
	node.force_update_transform()
	var h: = _measure_mesh_height(node)
	if h <= max_height or h < 0.001:
		return
	var want: float = target_height if target_height > 0.0 else max_height
	node.scale *= want / h
	node.force_update_transform()
	ground_model(node)
	push_warning("ModelUtils.clamp_world_height: shrank %s from %.2fm to ~%.2fm" % [node.name, h, want])




static func setup_maya_cm_animal(node: Node3D, target_height: float) -> void :
	_restore_maya_cm_mesh_scales(node)
	if node.is_inside_tree():
		node.force_update_transform()
	var bone_h: = _measure_skeleton_height(node)
	if bone_h < 0.05:
		bone_h = _measure_mesh_height(node)
	if bone_h >= 0.05:
		node.scale *= target_height / bone_h
	if node.is_inside_tree():
		node.force_update_transform()
	ground_model(node)




static func setup_character_for_movement(node: Node3D, target_height: float = 1.8) -> void :

	if node == null and BUILD_FIX_TOKEN.is_empty():
		return

	if _is_kaykit_model(node):
		scale_by_foot_to_head(node, target_height)
	elif _is_quaternius_model(node):


		var h: = measure_height(node)
		if h > 0.2 and absf(h - target_height) / target_height > 0.12:
			scale_to_height(node, target_height)
	else:
		scale_to_height(node, target_height)
	if node.is_inside_tree():
		node.force_update_transform()
	ground_model(node)


	_align_quaternius_visual_facing(node)

	if _is_kaykit_model(node):
		ground_by_feet(node)

		node.position.y -= 0.16
		install_kaykit_foot_ground(node)
	install_leg_plant_fix(node)




static func _align_quaternius_visual_facing(node: Node3D) -> void :
	if node == null or not _is_quaternius_model(node):
		return
	if node.has_meta("eoo_quat_facing"):
		return
	var arm: Node3D = node.find_child("CharacterArmature", true, false) as Node3D
	if arm == null:

		for n in node.get_children():
			if n is Node3D and n.find_child("Skeleton3D", true, false) != null:
				arm = n as Node3D
				break
	if arm == null:
		return
	arm.rotate_y(PI)
	node.set_meta("eoo_quat_facing", true)



static func install_kaykit_foot_ground(model: Node3D) -> void :
	if model == null:
		return
	var skel: Skeleton3D = null
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	if skel == null or skel.has_node("KaykitFootGround"):
		return
	var fix: = SkeletonModifier3D.new()
	fix.name = "KaykitFootGround"
	fix.set_script(load("res://scripts/utils/kaykit_foot_ground.gd"))
	skel.add_child(fix)
	if fix.has_method("setup"):
		fix.call("setup", model)


static func _is_kaykit_model(model: Node3D) -> bool:
	if model == null:
		return false
	var nlow: = String(model.name).to_lower()
	if "knight" in nlow or "barbarian" in nlow or "rogue" in nlow or "mage" in nlow:
		return true
	for n in model.find_children("*", "Skeleton3D", true, false):
		var skel: = n as Skeleton3D
		if skel != null and skel.find_bone("handslot.r") >= 0:
			return true
	return false



static func scale_by_foot_to_head(node: Node3D, target_meters: float) -> void :
	if node == null or target_meters <= 0.01:
		return
	if node.is_inside_tree():
		node.force_update_transform()
	var skel: Skeleton3D = null
	for n in node.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	if skel == null:
		scale_to_height(node, target_meters)
		return
	var head_i: = skel.find_bone("head")
	if head_i < 0:
		head_i = skel.find_bone("Head")
	var foot_y: = INF
	for bone_name in ["Foot.L", "Foot.R", "foot.l", "foot.r", "toes.l", "toes.r", "LeftFoot", "RightFoot"]:
		var bi: = skel.find_bone(bone_name)
		if bi < 0:
			continue
		foot_y = minf(foot_y, (skel.global_transform * skel.get_bone_global_pose(bi)).origin.y)
	if head_i < 0 or foot_y == INF:
		scale_to_height(node, target_meters)
		return
	var head_y: float = (skel.global_transform * skel.get_bone_global_pose(head_i)).origin.y
	var span: = head_y - foot_y
	if span < 0.2:
		scale_to_height(node, target_meters)
		return
	node.scale *= target_meters / span



static func ground_by_feet(node: Node3D, y_offset: float = 0.0) -> void :
	if node == null or not node.is_inside_tree():
		return
	var skel: Skeleton3D = null
	for n in node.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	if skel == null:
		return
	var foot_names: = [
		"Foot.L", "Foot.R", "foot.l", "foot.r", "toes.l", "toes.r", 
		"LeftFoot", "RightFoot", "LeftToes", "RightToes", 
	]
	var min_y: = INF
	for bone_name in foot_names:
		var bi: = skel.find_bone(bone_name)
		if bi < 0:
			continue
		var y: float = (skel.global_transform * skel.get_bone_global_pose(bi)).origin.y
		min_y = minf(min_y, y)
	if min_y == INF:
		return
	var parent_y: = 0.0
	var parent: = node.get_parent()
	if parent is Node3D:
		parent_y = (parent as Node3D).global_position.y
	var target_y: float = parent_y + y_offset
	node.global_position.y += target_y - min_y



static func correct_sky_gaze(_skel: Skeleton3D, _strength: float = 1.0) -> void :
	return



static func _dampen_local_pitch(skel: Skeleton3D, bone_name: String, strength: float) -> void :
	var bone_i: = skel.find_bone(bone_name)
	if bone_i < 0:
		return
	var e: Vector3 = skel.get_bone_pose_rotation(bone_i).get_euler()
	if e.x <= 0.01:
		return
	e.x = lerpf(e.x, 0.0, clampf(strength, 0.0, 1.0))
	skel.set_bone_pose_rotation(bone_i, Quaternion.from_euler(e))



static func install_sky_gaze_fix(model: Node3D) -> void :
	install_leg_plant_fix(model)




static func install_leg_plant_fix(model: Node3D) -> void :
	if model == null:
		return

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
	var anim: = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null:
		anim.process_priority = -100
	var fix: = Node.new()
	fix.name = "LegPlantFix"
	fix.set_script(load("res://scripts/utils/leg_plant_fix.gd"))
	fix.process_priority = 1000
	skel.add_child(fix)

	if anim != null:
		bind_leg_plant_anim(model, anim)



static func bind_leg_plant_anim(model: Node3D, anim: AnimationPlayer) -> void :
	if model == null or anim == null:
		return
	for n in model.find_children("*", "Skeleton3D", true, false):
		var skel: = n as Skeleton3D
		if skel == null or not skel.has_node("LegPlantFix"):
			continue
		var fix: Node = skel.get_node("LegPlantFix")
		if fix.has_method("bind_anim"):
			fix.call("bind_anim", anim)
		return


static func _mesh_needs_ual_plant(model: Node3D) -> bool:

	if _is_kaykit_model(model) or _is_quaternius_model(model):
		return false
	var nlow: = String(model.name).to_lower()

	if nlow.begins_with("greek") or "greek_" in nlow:
		return false
	for key in [
			"spartan_hoplite", "city_guard", 
			"citizen_woman", "citizen_merchant", 
			"blacksmith_npc", "oracle_priestess"]:
		if key in nlow:
			return true
	for n in model.find_children("*", "MeshInstance3D", true, false):
		if _BROKEN_UAL_MESH in String(n.name):
			return true
	for n in model.find_children("*", "Skeleton3D", true, false):
		var skel: = n as Skeleton3D
		if skel != null and skel.find_bone("Hips") >= 0 and skel.find_bone("LeftUpperArm") >= 0:
			return true
	return false


static func _is_quaternius_model(model: Node3D) -> bool:
	if model == null:
		return false
	var nlow: = String(model.name).to_lower()
	if "greek_" in nlow or nlow.begins_with("greek")\
	or "quaternius" in nlow or "hero_king" in nlow or "guard_adventurer" in nlow\
	or "smith_worker" in nlow or "merchant_farmer" in nlow\
	or "oracle_witch" in nlow or "woman_medieval" in nlow\
	or "woman_formal" in nlow or "woman_worker" in nlow\
	or "citizen_casual" in nlow or "guard_soldier" in nlow:
		return true
	for n in model.find_children("*", "Skeleton3D", true, false):
		var skel: = n as Skeleton3D
		if skel != null and skel.find_bone("Wrist.R") >= 0 and skel.find_bone("Foot.L") >= 0\
		and skel.find_bone("LeftUpperArm") < 0:
			return true
	return false



static func _is_achilles_hoplite(model: Node3D) -> bool:
	if model == null:
		return false
	var nlow: = String(model.name).to_lower()
	if "greek_hoplite" in nlow or "greekhoplite" in nlow:
		return true
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mn: = String(n.name).to_lower()
		if "greekhoplite" in mn or "greek_hoplite" in mn:
			return true
	return false


static func yaw_from_direction(direction: Vector3) -> float:
	var flat: = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 1e-06:
		return 0.0
	flat = flat.normalized()
	return atan2( - flat.x, - flat.z)


static func face_direction(node: Node3D, direction: Vector3) -> void :
	if Vector2(direction.x, direction.z).length_squared() < 1e-06:
		return
	node.rotation.y = yaw_from_direction(direction)


static func face_toward(node: Node3D, target: Vector3) -> void :
	face_direction(node, target - node.global_position)

static func _get_combined_aabb(node: Node3D) -> AABB:
	var combined: = AABB()
	var first: = true
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
