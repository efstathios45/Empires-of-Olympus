extends SceneTree

# Smoke: enemies face the player with their head/snout, not their butt.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	for id in ["wolf_enemy", "boar_enemy", "satyr_enemy", "harpy_enemy", "gorgon_enemy", "minotaur_boss"]:
		ok = await _check(id) and ok
	ok = await _check_npc_greek() and ok
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
	e.set_process(false)
	await process_frame
	await process_frame
	var mesh: Node3D = e.get_node("MeshRoot") as Node3D
	var model: Node3D = mesh.get_child(0) as Node3D
	var anim: AnimationPlayer = e.get("anim") as AnimationPlayer
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
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
	# Aim chase at +Z player
	mesh.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, 1))
	await process_frame
	skel.force_update_all_bone_transforms()
	var hips_i: int = _find(skel, ["Hips", "hips", "Body", "Root"])
	var head_i: int = _find(skel, ["Head", "head", "Nose", "nose", "Neck3", "Neck"])
	if hips_i < 0 or head_i < 0:
		print("FAIL ", id, " missing hips/head")
		e.queue_free()
		return false
	var hips: Vector3 = skel.to_global(skel.get_bone_global_pose(hips_i).origin)
	var head: Vector3 = skel.to_global(skel.get_bone_global_pose(head_i).origin)
	var ahead: float = head.z - hips.z
	print("  model.y=", snappedf(model.rotation.y, 0.01), " head_ahead=", snappedf(ahead, 0.001),
		" facing_plus_z=", e.cfg.get("facing_plus_z", null))
	# Harpy head barely ahead; require weaker threshold. Others need a clear snout.
	var need: float = 0.03 if id == "harpy_enemy" else 0.05
	if ahead < need:
		print("FAIL ", id, " still faces away from chase target (head_ahead=", ahead, ")")
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
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D if model else null
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


func _find(skel: Skeleton3D, names: Array) -> int:
	for n in names:
		var i: int = skel.find_bone(String(n))
		if i >= 0:
			return i
	return -1
