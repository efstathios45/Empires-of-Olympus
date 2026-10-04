extends SceneTree

# Smoke: enemies face the player (Tripo face = bone +Z; animals = snout ahead).

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	for id in ["wolf_enemy", "boar_enemy", "satyr_enemy", "harpy_enemy", "gorgon_enemy", "minotaur_boss"]:
		ok = await _check(id) and ok
	ok = await _check_npc_greek() and ok
	ok = await _check_npc_ual_guard() and ok
	if ok:
		print("SMOKE_POSE_FACING_OK")
		quit(0)
	else:
		print("SMOKE_POSE_FACING_FAIL")
		quit(1)


func _check(id: String) -> bool:
	print("-- ", id)
	var Enemy: GDScript = load("res://scripts/enemy.gd") as GDScript
	var e: CharacterBody3D = Enemy.call("create", id, Vector3.ZERO) as CharacterBody3D
	get_root().add_child(e)
	e.set_physics_process(false)
	await process_frame
	await process_frame
	var mesh: Node3D = e.get_node("MeshRoot") as Node3D
	var model: Node3D = mesh.get_child(0) as Node3D
	var anim: AnimationPlayer = e.get("anim") as AnimationPlayer
	var skel: Skeleton3D = null
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	if skel == null:
		print("FAIL ", id, " no skeleton")
		e.queue_free()
		return false
	if anim != null:
		for c in ["Walk", "ual1_Walk", "Gallop", "Idle", "ual1_Idle"]:
			if anim.has_animation(c):
				anim.play(c)
				anim.seek(0.25, true)
				break
	mesh.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, 1))
	for i in 6:
		await process_frame
	skel.force_update_all_bone_transforms()
	var chase := Vector3(0, 0, 1)
	var is_ual := skel.find_bone("UpperChest") >= 0 or skel.find_bone("Chest") >= 0
	print("  model.y=", snappedf(model.rotation.y, 0.01),
		" facing_plus_z=", e.cfg.get("facing_plus_z", null),
		" facing_yaw=", e.cfg.get("facing_yaw_deg", null),
		" posture=", skel.has_node("NpcPostureFix"))
	if not is_ual:
		var hips_i := _find(skel, ["Hips", "hips", "Body", "Root"])
		var snout_i := _find(skel, ["nose", "Nose", "head", "Head", "Neck3", "Neck"])
		if hips_i < 0 or snout_i < 0:
			print("FAIL ", id, " no front axis")
			e.queue_free()
			return false
		var hips: Vector3 = skel.to_global(skel.get_bone_global_pose(hips_i).origin)
		var snout: Vector3 = skel.to_global(skel.get_bone_global_pose(snout_i).origin)
		var ahead: float = snout.z - hips.z
		print("  animal snout_ahead=", snappedf(ahead, 0.001))
		if ahead < 0.05:
			print("FAIL ", id, " still faces away (snout_ahead=", ahead, ")")
			e.queue_free()
			return false
	else:
		var hi := skel.find_bone("Head")
		if hi < 0:
			hi = skel.find_bone("UpperChest")
		var xf := skel.global_transform * skel.get_bone_global_pose(hi)
		# Tripo face = +Z. Use full 3D look (Y-flatten flips sky-gaze remnants).
		var look: Vector3 = xf.basis.z
		var dot := look.normalized().dot(chase)
		print("  head+Z·chase=", snappedf(dot, 0.001), " look_y=", snappedf(look.y, 0.001))
		if dot < 0.55:
			print("FAIL ", id, " face aims away from chase (dot=", dot, ")")
			e.queue_free()
			return false
	print("  ", id, " OK")
	e.queue_free()
	await process_frame
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
	var model: Node3D = n.get("_model") as Node3D
	var anim: AnimationPlayer = n.get("_anim") as AnimationPlayer
	var skel: Skeleton3D = null
	if model:
		for node in model.find_children("*", "Skeleton3D", true, false):
			skel = node as Skeleton3D
			break
	if model == null or anim == null or skel == null:
		print("FAIL greek npc missing nodes")
		return false
	await process_frame
	var moved := false
	for i in skel.get_bone_count():
		if not skel.get_bone_rest(i).is_equal_approx(skel.get_bone_pose(i)):
			moved = true
			break
	print("  clip=", anim.current_animation, " moved=", moved)
	if not moved:
		print("FAIL greek npc idle not posing")
		return false
	print("  greek npc OK")
	n.queue_free()
	return true


func _check_npc_ual_guard() -> bool:
	print("-- UAL city_guard NPC bind")
	var n: StaticBody3D = load("res://scripts/npc.gd").create_flavour(
		"guard_test", "Guard Lysandros",
		"res://assets/characters/city_guard/city_guard.glb",
		"res://assets/characters/city_guard/city_guard_animations.tres",
		Vector3(0, 0, 5), 1.84, 0.0, "ual1_Idle", "test")
	get_root().add_child(n)
	await process_frame
	await process_frame
	var model: Node3D = n.get("_model") as Node3D
	var anim: AnimationPlayer = n.get("_anim") as AnimationPlayer
	var skel: Skeleton3D = null
	if model:
		for node in model.find_children("*", "Skeleton3D", true, false):
			skel = node as Skeleton3D
			break
	if model == null or anim == null or skel == null:
		print("FAIL ual guard missing nodes")
		return false
	var resolved = anim.get_node_or_null(anim.root_node)
	var gs = resolved.get_node_or_null("%GeneralSkeleton") if resolved else null
	print("  skel_name=", skel.name, " unique=", skel.unique_name_in_owner,
		" resolve_%GS=", gs != null, " clip=", anim.current_animation)
	if gs == null:
		print("FAIL ual guard %GeneralSkeleton unresolved")
		n.queue_free()
		return false
	anim.play("ual1_Idle")
	anim.seek(0.3, true)
	for i in 3:
		await process_frame
	var moved := false
	for i in skel.get_bone_count():
		if not skel.get_bone_rest(i).is_equal_approx(skel.get_bone_pose(i)):
			moved = true
			break
	print("  posed=", moved, " posture=", skel.has_node("NpcPostureFix"))
	if not moved:
		print("FAIL ual guard idle not posing")
		n.queue_free()
		return false
	print("  ual guard OK")
	n.queue_free()
	return true


func _find(skel: Skeleton3D, names: Array) -> int:
	for n in names:
		var i: int = skel.find_bone(String(n))
		if i >= 0:
			return i
	return -1
