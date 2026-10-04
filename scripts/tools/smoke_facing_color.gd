extends SceneTree

# Smoke: chase facing (not sideways) + plaza NPCs painted (not white).

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	ok = await _check_enemy("wolf_enemy", true) and ok
	ok = await _check_enemy("boar_enemy", true) and ok
	ok = await _check_enemy("satyr_enemy", false) and ok
	ok = await _check_enemy("harpy_enemy", false) and ok
	ok = await _check_enemy("gorgon_enemy", false) and ok
	ok = await _check_enemy("minotaur_boss", false) and ok
	ok = await _check_npc_color() and ok
	if ok:
		print("SMOKE_FACING_COLOR_OK")
		quit(0)
	else:
		print("SMOKE_FACING_COLOR_FAIL")
		quit(1)


func _check_enemy(id: String, use_head: bool) -> bool:
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
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if anim:
		for c in ["Idle", "ual1_Idle", "Walk", "ual1_Walk"]:
			if anim.has_animation(c):
				anim.play(c)
				anim.seek(0.2, true)
				break
	mesh.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, 1))
	await process_frame
	skel.force_update_all_bone_transforms()
	var face: float = _face_dot(skel)
	var head: float = _head_ahead(skel)
	var yaw_cfg = e.cfg.get("facing_yaw_deg", null)
	print("  yaw_cfg=", yaw_cfg, " model.y=", snappedf(model.rotation.y, 0.01),
		" face_dot=", snappedf(face, 0.01), " head_ahead=", snappedf(head, 0.01))
	var good: bool = head > 0.05 if use_head else face > 0.55
	if not good:
		print("FAIL ", id, " still sideways/backwards")
		e.queue_free()
		return false
	print("  ", id, " OK")
	e.queue_free()
	await process_frame
	return true


func _check_npc_color() -> bool:
	print("-- npc color")
	var n: StaticBody3D = load("res://scripts/npc.gd").create(
		"priestess", "Priestess Melite",
		"res://assets/characters/greek_oracle/greek_oracle.glb", "",
		Vector3.ZERO, 1.72, 0.0)
	get_root().add_child(n)
	await process_frame
	await process_frame
	var model: Node3D = n.get("_model") as Node3D
	if model == null:
		print("FAIL no model")
		return false
	var painted := 0
	var whiteish := 0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var mat: Material = mi.get_active_material(0)
		if mat == null and mi.get_surface_override_material_count() > 0:
			mat = mi.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			var c: Color = (mat as StandardMaterial3D).albedo_color
			var sat: float = maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			print("  mesh=", mi.name, " albedo=", c, " sat=", snappedf(sat, 0.01))
			if sat < 0.05 and c.r > 0.75:
				whiteish += 1
			else:
				painted += 1
	print("  painted=", painted, " whiteish=", whiteish)
	if painted < 1 or whiteish > painted:
		print("FAIL NPC still mostly white/unpainted")
		n.queue_free()
		return false
	# Guard should get bronze armor palette
	var g: StaticBody3D = load("res://scripts/npc.gd").create_flavour(
		"citizen_g", "Guard", "res://assets/characters/greek_guard/greek_guard.glb", "",
		Vector3.ZERO, 1.84, 0.0, "Idle_Sword", "hi")
	g.greek_role = "guard"
	get_root().add_child(g)
	await process_frame
	await process_frame
	var gm: Node3D = g.get("_model") as Node3D
	var armor_ok := false
	for node in gm.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var mat: Material = mi.get_surface_override_material(0)
		if mat == null:
			mat = mi.get_active_material(0)
		if mat is StandardMaterial3D:
			var c: Color = (mat as StandardMaterial3D).albedo_color
			print("  guard albedo=", c)
			# Bronze-ish armor from GreekLook guard palette
			if c.r > 0.4 and c.g > 0.25 and c.b < 0.45 and c.r > c.b:
				armor_ok = true
	if not armor_ok:
		print("FAIL guard not bronze-painted")
		n.queue_free(); g.queue_free()
		return false
	print("  npc color OK")
	n.queue_free()
	g.queue_free()
	return true


func _face_dot(skel: Skeleton3D) -> float:
	var toward := Vector3(0, 0, 1)
	for bn in ["UpperChest", "Chest", "Hips", "Head"]:
		var bi := skel.find_bone(bn)
		if bi < 0:
			continue
		var xf := skel.global_transform * skel.get_bone_global_pose(bi)
		var f: Vector3 = -xf.basis.z
		f.y = 0.0
		if f.length_squared() > 1e-6:
			return f.normalized().dot(toward)
	return 0.0


func _head_ahead(skel: Skeleton3D) -> float:
	var hips_i := -1
	var head_i := -1
	for n in ["Hips", "hips", "Body"]:
		hips_i = skel.find_bone(n)
		if hips_i >= 0: break
	for n in ["Head", "head", "Nose", "nose", "Neck"]:
		head_i = skel.find_bone(n)
		if head_i >= 0: break
	if hips_i < 0 or head_i < 0:
		return 0.0
	return skel.to_global(skel.get_bone_global_pose(head_i).origin).z - skel.to_global(skel.get_bone_global_pose(hips_i).origin).z
