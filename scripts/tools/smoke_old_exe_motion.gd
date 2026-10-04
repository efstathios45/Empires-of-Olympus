extends SceneTree
# Verify NPC/mob motion matches pre-chat exe (m84Azz3v): GeneralSkeleton bind,
# no retarget/posture dampen, facing_plus_z animals, UAL plaza cast, clips play.

func _init() -> void:
	await process_frame
	var ok := true
	ok = (await _check_enemy("wolf_enemy", 180.0, "Idle", "Walk", "Attack")) and ok
	# OGA boar snout is authored −Z (chase-forward); yaw 0 keeps charge face-on.
	ok = (await _check_enemy("boar_enemy", 0.0, "Idle", "Walk", "Attack")) and ok
	# Tripo UAL face is +Z → facing_yaw 180 so chase shows their face.
	ok = (await _check_enemy("satyr_enemy", 180.0, "ual1_Idle", "ual1_Walk", "ual1_Sword_Attack")) and ok
	ok = (await _check_enemy("harpy_enemy", 180.0, "ual1_Idle", "ual1_Walk", "ual1_Sword_Attack")) and ok
	ok = (await _check_enemy("minotaur_boss", 180.0, "ual1_Idle", "ual1_Walk", "ual1_Sword_Attack")) and ok
	ok = (await _check_enemy("gorgon_enemy", 180.0, "ual1_Idle", "ual1_Walk", "ual1_Sword_Attack")) and ok
	ok = (await _check_npc(
		"res://assets/characters/city_guard/city_guard.glb",
		"res://assets/characters/city_guard/city_guard_animations.tres",
		"ual1_Idle", 1.84)) and ok
	ok = (await _check_npc(
		"res://assets/characters/citizen_merchant/citizen_merchant.glb",
		"res://assets/characters/citizen_merchant/citizen_merchant_animations.tres",
		"ual2_Idle_FoldArms", 1.78)) and ok
	ok = _check_plaza_paths() and ok
	if ok:
		print("OK old_exe_motion")
		quit(0)
	else:
		print("FAIL old_exe_motion")
		quit(1)


func _check_plaza_paths() -> bool:
	var src := FileAccess.get_file_as_string("res://scripts/world/city_plaza.gd")
	for needle in [
		"city_guard/city_guard.glb",
		"citizen_merchant/citizen_merchant.glb",
		"oracle_priestess/oracle_priestess.glb",
		"blacksmith_npc/blacksmith_npc.glb",
		"ual1_Idle",
	]:
		if needle not in src:
			print("FAIL plaza missing ", needle)
			return false
	if "quaternius_guard_adventurer" in src or "quaternius_oracle_witch" in src:
		print("FAIL plaza still on Quaternius cast")
		return false
	print("OK plaza cast")
	return true


func _hips_moved(skel: Skeleton3D, anim: AnimationPlayer, clip: String) -> bool:
	if skel == null or anim == null or not anim.has_animation(clip):
		return false
	var hips := skel.find_bone("Hips")
	if hips < 0:
		hips = 0
	anim.play(clip)
	anim.seek(0.05, true)
	skel.force_update_all_bone_transforms()
	var a := skel.get_bone_pose_rotation(hips)
	anim.seek(0.35, true)
	skel.force_update_all_bone_transforms()
	var b := skel.get_bone_pose_rotation(hips)
	# Idle can be near-static; also accept any bone differing from rest.
	if not a.is_equal_approx(b):
		return true
	var rest := skel.get_bone_rest(hips).basis.get_rotation_quaternion()
	return not b.is_equal_approx(rest)


func _look_y(skel: Skeleton3D) -> float:
	var hi := skel.find_bone("Head")
	if hi < 0:
		return 0.0
	skel.force_update_all_bone_transforms()
	var xf := skel.global_transform * skel.get_bone_global_pose(hi)
	return (-xf.basis.z).y


func _hands_dist(skel: Skeleton3D) -> float:
	var l := skel.find_bone("LeftHand")
	var r := skel.find_bone("RightHand")
	if l < 0 or r < 0:
		l = skel.find_bone("LeftForeArm")
		r = skel.find_bone("RightForeArm")
	if l < 0 or r < 0:
		return 1.0
	skel.force_update_all_bone_transforms()
	var a := skel.to_global(skel.get_bone_global_pose(l).origin)
	var b := skel.to_global(skel.get_bone_global_pose(r).origin)
	return a.distance_to(b)


func _check_enemy(id: String, expect_yaw_deg: float, idle: String, walk: String, attack: String) -> bool:
	var Enemy = load("res://scripts/enemy.gd")
	var e = Enemy.create(id, Vector3.ZERO)
	get_root().add_child(e)
	await process_frame
	await process_frame
	var yaw_deg := float(e.cfg.get("facing_yaw_deg", -1.0))
	if absf(yaw_deg - expect_yaw_deg) > 0.5:
		print("FAIL ", id, " facing_yaw_deg want ", expect_yaw_deg, " got ", yaw_deg)
		e.queue_free()
		return false
	var model: Node3D = e.mesh_root.get_child(0) if e.mesh_root.get_child_count() > 0 else null
	if model == null:
		print("FAIL ", id, " no model")
		e.queue_free()
		return false
	var skel: Skeleton3D = null
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	if skel != null and skel.has_node("LegPlantFix"):
		print("FAIL ", id, " has LegPlantFix")
		e.queue_free()
		return false
	if skel != null and skel.has_node("UalPostureFix"):
		print("FAIL ", id, " has UalPostureFix (old-exe path must not posture-correct)")
		e.queue_free()
		return false
	var anim: AnimationPlayer = e.anim
	if anim == null:
		print("FAIL ", id, " no anim")
		e.queue_free()
		return false
	for clip in [idle, walk, attack]:
		if not anim.has_animation(clip):
			print("FAIL ", id, " missing clip ", clip)
			e.queue_free()
			return false
	# Humanoids: clips must move skeleton (not T-pose)
	if skel != null and skel.find_bone("Hips") >= 0 and skel.find_bone("LeftUpperArm") >= 0:
		if skel.name != "GeneralSkeleton" or not skel.unique_name_in_owner:
			print("FAIL ", id, " GeneralSkeleton bind missing name=", skel.name, " uniq=", skel.unique_name_in_owner)
			e.queue_free()
			return false
		if not _hips_moved(skel, anim, idle):
			print("FAIL ", id, " idle did not move hips (T-pose?)")
			e.queue_free()
			return false
		anim.play(idle)
		anim.seek(0.3, true)
		skel.force_update_all_bone_transforms()
		var ly := _look_y(skel)
		# Old-exe path has no UalPostureFix; mild upward look on some Tripo heads is expected.
		if ly > 0.45:
			print("FAIL ", id, " sky-gaze look_y=", ly)
			e.queue_free()
			return false
		var hd := _hands_dist(skel)
		if hd < 0.12:
			print("FAIL ", id, " hands glued/entangled dist=", hd)
			e.queue_free()
			return false
	# Animals: facing PI when plus_z
	# Visual front must aim with MeshRoot −Z after chase yaw toward −Z.
	e.mesh_root.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	if anim.has_animation(walk):
		anim.play(walk)
		anim.seek(0.2, true)
	if skel:
		skel.force_update_all_bone_transforms()
		var front := Vector3.ZERO
		for bn in ["UpperChest", "Chest", "Hips", "Head"]:
			var bi := skel.find_bone(bn)
			if bi < 0:
				continue
			var xf := skel.global_transform * skel.get_bone_global_pose(bi)
			front = xf.basis.z
			front.y = 0.0
			if front.length_squared() > 1e-6:
				front = front.normalized()
				break
		if front.length_squared() > 1e-6:
			# Tripo UAL + animals-with-plus_z: chest +Z aims chase dir.
			var chase := Vector3(0, 0, -1)
			var dot_plus := front.dot(chase)
			if id == "boar_enemy":
				# Boar snout is −Z; accept either axis alignment.
				if maxf(dot_plus, (-front).dot(chase)) < 0.45:
					print("FAIL ", id, " not facing chase plus=", dot_plus)
					e.queue_free()
					return false
			elif dot_plus < 0.45:
				print("FAIL ", id, " not facing chase plus=", dot_plus)
				e.queue_free()
				return false
	print("OK enemy ", id)
	e.queue_free()
	return true


func _check_npc(glb: String, lib: String, idle: String, height: float) -> bool:
	var Npc = load("res://scripts/npc.gd")
	var n = Npc.create("test", "Test", glb, lib, Vector3(0, 0, 5), height, 0.0)
	n.idle_clip = idle
	get_root().add_child(n)
	await process_frame
	await process_frame
	var skel: Skeleton3D = null
	for node in n.find_children("*", "Skeleton3D", true, false):
		skel = node as Skeleton3D
		break
	var anim: AnimationPlayer = null
	for node in n.find_children("*", "AnimationPlayer", true, false):
		anim = node as AnimationPlayer
		break
	if skel == null or anim == null:
		print("FAIL npc missing skel/anim ", glb, " skel=", skel, " anim=", anim)
		n.queue_free()
		return false
	if skel.has_node("LegPlantFix"):
		print("FAIL npc has LegPlantFix ", glb)
		n.queue_free()
		return false
	if skel.has_node("UalPostureFix"):
		print("FAIL npc has UalPostureFix ", glb)
		n.queue_free()
		return false
	if skel.name != "GeneralSkeleton" or not skel.unique_name_in_owner:
		print("FAIL npc GeneralSkeleton bind ", skel.name, " ", skel.unique_name_in_owner)
		n.queue_free()
		return false
	if not anim.has_animation(idle):
		print("FAIL npc missing idle ", idle)
		n.queue_free()
		return false
	if not _hips_moved(skel, anim, idle):
		print("FAIL npc T-pose on ", idle)
		n.queue_free()
		return false
	anim.play(idle)
	anim.seek(0.3, true)
	# Let pitch-only posture corrector run after the seek.
	await process_frame
	await process_frame
	var ly := _look_y(skel)
	if ly > 0.45:
		print("FAIL npc sky-gaze look_y=", ly, " ", glb)
		n.queue_free()
		return false
	var hd := _hands_dist(skel)
	# Folded-arms / crossed-arm idles keep hands near the chest by design.
	var idle_l := idle.to_lower()
	if hd < 0.12 and "fold" not in idle_l and "cross" not in idle_l:
		print("FAIL npc entangled hands=", hd, " ", glb)
		n.queue_free()
		return false
	print("OK npc ", glb.get_file())
	n.queue_free()
	return true
