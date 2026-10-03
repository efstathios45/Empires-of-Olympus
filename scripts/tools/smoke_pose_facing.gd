extends SceneTree

# Smoke: wolf chase facing, humanoid enemy anim bind, plaza NPC idle pose.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	ok = await _check_wolf() and ok
	ok = await _check_boar() and ok
	ok = await _check_satyr() and ok
	ok = await _check_npc_greek() and ok
	ok = await _check_npc_old_guard_retarget() and ok
	if ok:
		print("SMOKE_POSE_FACING_OK")
	else:
		print("SMOKE_POSE_FACING_FAIL")
		quit(1)
		return
	quit(0)


func _check_wolf() -> bool:
	print("-- wolf facing")
	var e: CharacterBody3D = load("res://scripts/enemy.gd").create("wolf_enemy", Vector3.ZERO)
	get_root().add_child(e)
	e.set_physics_process(false)
	e.set_process(false)
	await process_frame
	await process_frame
	var mesh: Node3D = e.get_node("MeshRoot") as Node3D
	var model: Node3D = mesh.get_child(0) as Node3D
	var arm: Node3D = model.find_child("AnimalArmature", true, false) as Node3D
	if arm == null:
		print("FAIL wolf missing AnimalArmature")
		return false
	mesh.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, 1))
	await process_frame
	var fwd := _forward(arm)
	var head_fwd := _head_forward(model)
	var toward := Vector3(0, 0, 1)
	var align := fwd.dot(toward)
	var head_align := head_fwd.dot(toward)
	print("  mesh_yaw=", mesh.rotation.y, " model_yaw=", model.rotation.y,
		" arm_yaw=", arm.rotation.y, " fwd=", fwd, " align=", align,
		" head_fwd=", head_fwd, " head_align=", head_align)
	# Prefer head/nose if available; else armature −Z.
	var use_align := head_align if head_fwd.length_squared() > 0.01 else align
	if use_align < 0.5:
		print("FAIL wolf walks/looks backward while chasing +Z (align=", use_align, ")")
		return false
	if model.has_meta("eoo_quat_facing"):
		print("FAIL wolf should not get CharacterArmature facing meta")
		return false
	print("  wolf OK")
	e.queue_free()
	return true


func _check_boar() -> bool:
	print("-- boar facing")
	var e: CharacterBody3D = load("res://scripts/enemy.gd").create("boar_enemy", Vector3.ZERO)
	get_root().add_child(e)
	e.set_physics_process(false)
	e.set_process(false)
	await process_frame
	await process_frame
	var mesh: Node3D = e.get_node("MeshRoot") as Node3D
	var model: Node3D = mesh.get_child(0) as Node3D
	var arm: Node3D = model.find_child("boar_armature", true, false) as Node3D
	var n: Node3D = arm if arm else model
	mesh.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, 1))
	await process_frame
	var align := _forward(n).dot(Vector3(0, 0, 1))
	print("  fwd=", _forward(n), " align=", align, " mesh_yaw=", mesh.rotation.y)
	if align < 0.5:
		print("FAIL boar backward (align=", align, ")")
		return false
	print("  boar OK")
	e.queue_free()
	return true


func _check_satyr() -> bool:
	print("-- satyr anim bind")
	var e: CharacterBody3D = load("res://scripts/enemy.gd").create("satyr_enemy", Vector3.ZERO)
	get_root().add_child(e)
	await process_frame
	await process_frame
	await process_frame
	var anim: AnimationPlayer = e.get("anim")
	var mesh: Node3D = e.get_node("MeshRoot") as Node3D
	var model: Node3D = mesh.get_child(0) as Node3D
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if anim == null or skel == null:
		print("FAIL satyr missing anim/skel")
		return false
	var clip := "ual1_Idle"
	if not anim.has_animation(clip):
		print("FAIL satyr missing ", clip, " list=", anim.get_animation_list())
		return false
	# Confirm tracks were retargeted off %GeneralSkeleton
	var a := anim.get_animation(clip)
	var still_unique := false
	for ti in a.get_track_count():
		if String(a.track_get_path(ti)).begins_with("%GeneralSkeleton"):
			still_unique = true
			break
	if still_unique:
		print("FAIL satyr tracks still use %GeneralSkeleton")
		return false
	anim.play(clip)
	anim.seek(0.15, true)
	await process_frame
	await process_frame
	var moved := _pose_moved(skel)
	print("  current=", anim.current_animation, " moved=", moved,
		" sample_track=", a.track_get_path(2) if a.get_track_count() > 2 else "")
	if not moved:
		print("FAIL satyr T-pose (idle did not move bones)")
		return false
	print("  satyr OK")
	e.queue_free()
	return true


func _check_npc_greek() -> bool:
	print("-- greek plaza NPC")
	var n: StaticBody3D = load("res://scripts/npc.gd").create_flavour(
		"citizen_test", "Guard Test",
		"res://assets/characters/greek_guard/greek_guard.glb", "",
		Vector3.ZERO, 1.84, 0.0, "Idle_Sword", "test")
	get_root().add_child(n)
	await process_frame
	await process_frame
	var model: Node3D = n.get("_model")
	var anim: AnimationPlayer = n.get("_anim")
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D if model else null
	if model == null or anim == null or skel == null:
		print("FAIL greek npc missing nodes")
		return false
	if skel.has_node("NpcPostureFix"):
		print("FAIL greek npc should not install UAL posture fix")
		return false
	await process_frame
	var moved := _pose_moved(skel)
	print("  clip=", anim.current_animation, " moved=", moved, " quat=", ModelUtils._is_quaternius_model(model))
	if not moved:
		print("FAIL greek npc idle not posing")
		return false
	print("  greek npc OK")
	n.queue_free()
	return true


func _check_npc_old_guard_retarget() -> bool:
	# Retarget path still works if a leftover UAL citizen pack is spawned.
	print("-- UAL city_guard retarget")
	var path := "res://assets/characters/city_guard/city_guard.glb"
	var libp := "res://assets/characters/city_guard/city_guard_animations.tres"
	if not ResourceLoader.exists(path) or not ResourceLoader.exists(libp):
		print("  skip (assets missing)")
		return true
	var n: StaticBody3D = load("res://scripts/npc.gd").create_flavour(
		"old_guard", "Old Guard", path, libp, Vector3.ZERO, 1.84, 0.0, "ual1_Idle", "hi")
	get_root().add_child(n)
	await process_frame
	await process_frame
	await process_frame
	var model: Node3D = n.get("_model")
	var anim: AnimationPlayer = n.get("_anim")
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D if model else null
	if anim == null or skel == null:
		print("FAIL old guard nodes")
		return false
	var moved := _pose_moved(skel)
	print("  clip=", anim.current_animation, " moved=", moved)
	if not moved:
		print("FAIL old UAL guard still T-pose after retarget")
		return false
	print("  old guard retarget OK")
	n.queue_free()
	return true


func _forward(n: Node3D) -> Vector3:
	var f := -n.global_transform.basis.z
	f.y = 0.0
	if f.length_squared() < 1e-8:
		return Vector3.ZERO
	return f.normalized()


func _head_forward(model: Node3D) -> Vector3:
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null:
		return Vector3.ZERO
	var bi := skel.find_bone("Head")
	if bi < 0:
		bi = skel.find_bone("head")
	if bi < 0:
		return Vector3.ZERO
	skel.force_update_all_bone_transforms()
	var xf := skel.global_transform * skel.get_bone_global_pose(bi)
	# Quaternius animals often aim the head bone's −Z or −Y; prefer −Z then −Y.
	for axis in [-xf.basis.z, -xf.basis.y, xf.basis.z]:
		var f: Vector3 = axis
		f.y = 0.0
		if f.length_squared() > 0.05:
			return f.normalized()
	return Vector3.ZERO


func _pose_moved(skel: Skeleton3D) -> bool:
	if skel == null:
		return false
	for i in skel.get_bone_count():
		if not skel.get_bone_rest(i).is_equal_approx(skel.get_bone_pose(i)):
			return true
	return false
