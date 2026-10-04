extends SceneTree

# Smoke: chase facing (visual front toward chase) + textured plaza NPCs.

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
	ok = await _check_enemy("centaur_enemy", true) and ok
	ok = await _check_npc_textured() and ok
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
		for c in ["Idle", "ual1_Idle", "Walk", "ual1_Walk", "Armature|Walking", "Armature|RestPose"]:
			if anim.has_animation(c):
				anim.play(c)
				anim.seek(0.2, true)
				break
	# MeshRoot aims chase +Z (same as runtime yaw_from_direction).
	mesh.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, 1))
	await process_frame
	skel.force_update_all_bone_transforms()
	var face: float = _visual_face_dot(skel) # UAL +Z / Godot chase
	var head: float = _head_ahead(skel)
	var yaw_cfg = e.cfg.get("facing_yaw_deg", null)
	print("  yaw_cfg=", yaw_cfg, " model.y=", snappedf(model.rotation.y, 0.01),
		" face_dot=", snappedf(face, 0.01), " head_ahead=", snappedf(head, 0.01))
	var good: bool
	if use_head:
		good = head > 0.05
	else:
		# Humanoids: visual front (chest +Z) must aim at chase.
		good = face > 0.55
	if not good:
		print("FAIL ", id, " still sideways/backwards")
		e.queue_free()
		return false
	print("  ", id, " OK")
	e.queue_free()
	await process_frame
	return true


func _check_npc_textured() -> bool:
	print("-- npc textured cast")
	var n: StaticBody3D = load("res://scripts/npc.gd").create(
		"priestess", "Priestess Melite",
		"res://assets/characters/oracle_priestess/oracle_priestess.glb",
		"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres",
		Vector3.ZERO, 1.72, 0.0)
	get_root().add_child(n)
	await process_frame
	await process_frame
	var model: Node3D = n.get("_model") as Node3D
	if model == null:
		print("FAIL no model")
		return false
	var textured := 0
	var flat_paint := 0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var mat: Material = mi.get_active_material(0)
		if mat == null and mi.get_surface_override_material_count() > 0:
			mat = mi.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			if sm.albedo_texture != null:
				textured += 1
				print("  mesh=", mi.name, " TEXTURED")
			else:
				var c: Color = sm.albedo_color
				var sat: float = maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
				print("  mesh=", mi.name, " albedo=", c, " sat=", snappedf(sat, 0.01))
				# GreekLook bronze/cloth overrides look like flat paint
				if sat > 0.08:
					flat_paint += 1
	print("  textured=", textured, " flat_paint=", flat_paint)
	if textured < 1:
		print("FAIL NPC has no albedo textures")
		n.queue_free()
		return false
	if flat_paint > textured:
		print("FAIL NPC still GreekLook-painted over textures")
		n.queue_free()
		return false
	# Guard textured too
	var g: StaticBody3D = load("res://scripts/npc.gd").create_flavour(
		"citizen_g", "Guard", "res://assets/characters/city_guard/city_guard.glb",
		"res://assets/characters/city_guard/city_guard_animations.tres",
		Vector3.ZERO, 1.84, 0.0, "Idle_Sword", "hi")
	get_root().add_child(g)
	await process_frame
	await process_frame
	var gm: Node3D = g.get("_model") as Node3D
	var gtex := 0
	for node in gm.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var mat: Material = mi.get_active_material(0)
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
			gtex += 1
	print("  guard textured_meshes=", gtex)
	if gtex < 1:
		print("FAIL guard not textured")
		n.queue_free(); g.queue_free()
		return false
	print("  npc textured OK")
	n.queue_free()
	g.queue_free()
	return true


func _visual_face_dot(skel: Skeleton3D) -> float:
	# UAL/Mixamo visual front is chest +Z. Chase probe aims MeshRoot at +Z.
	var toward := Vector3(0, 0, 1)
	for bn in ["UpperChest", "Chest", "Hips", "Head", "Torso_04"]:
		var bi := skel.find_bone(bn)
		if bi < 0:
			continue
		var xf := skel.global_transform * skel.get_bone_global_pose(bi)
		var f: Vector3 = xf.basis.z
		f.y = 0.0
		if f.length_squared() > 1e-6:
			return f.normalized().dot(toward)
	return 0.0


func _head_ahead(skel: Skeleton3D) -> float:
	var hips_i := -1
	var head_i := -1
	for n in ["Hips", "hips", "Body", "RootBone_01", "Torso_04"]:
		hips_i = skel.find_bone(n)
		if hips_i >= 0: break
	for n in ["Head", "head", "Nose", "nose", "Neck", "Head_06"]:
		head_i = skel.find_bone(n)
		if head_i >= 0: break
	if hips_i < 0 or head_i < 0:
		return 0.0
	return skel.to_global(skel.get_bone_global_pose(head_i).origin).z - skel.to_global(skel.get_bone_global_pose(hips_i).origin).z
