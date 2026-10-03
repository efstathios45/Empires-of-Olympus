extends SceneTree

func _init(): call_deferred("run")

func run():
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")


	var palm: = await _measure_palm()
	print("MEASURED palm_R=", palm.r, " palm_L_fore=", palm.l_fore, " strap=", palm.strap)

	var spear_candidates: Array = [
		{"tag": "s0", "pos": palm.r, "rot": Vector3(90, 0, 0)}, 
		{"tag": "s1", "pos": palm.r + Vector3(0, 0.02, 0.04), "rot": Vector3(90, 0, 0)}, 
		{"tag": "s2", "pos": palm.r + Vector3(-0.03, 0.0, 0.06), "rot": Vector3(90, 0, 0)}, 
		{"tag": "s3", "pos": Vector3(-0.08, -0.02, 0.32), "rot": Vector3(90, 0, 0)}, 
		{"tag": "s4", "pos": Vector3(-0.06, 0.0, 0.3), "rot": Vector3(90, 0, 0)}, 
		{"tag": "s5", "pos": Vector3(-0.1, -0.04, 0.34), "rot": Vector3(90, 15, 0)}, 
	]
	var shield_candidates: Array = [
		{"tag": "h0", "bone": "LowerArm.L", "pos": palm.strap, "rot": Vector3(0, 0, 0)}, 
		{"tag": "h1", "bone": "LowerArm.L", "pos": palm.l_fore, "rot": Vector3(0, 0, 0)}, 
		{"tag": "h2", "bone": "Wrist.L", "pos": palm.l_wrist, "rot": Vector3(0, 0, 0)}, 
		{"tag": "h3", "bone": "LowerArm.L", "pos": palm.strap + Vector3(0, 0, 0.04), "rot": Vector3(0, -90, 0)}, 
		{"tag": "h4", "bone": "LowerArm.L", "pos": palm.strap, "rot": Vector3(90, 0, 0)}, 
		{"tag": "h5", "bone": "LowerArm.L", "pos": Vector3(0.04, 0.12, 0.18), "rot": Vector3(0, 0, 0)}, 
	]

	for c in spear_candidates:
		await _cap("spear", c, WeaponGrip, GearPaint)
	for c in shield_candidates:
		await _cap("shield", c, WeaponGrip, GearPaint)


	await _cap_combo(Vector3(-0.08, -0.02, 0.32), Vector3(90, 0, 0), 
		"LowerArm.L", Vector3(0.04, 0.12, 0.18), Vector3(0, 0, 0), WeaponGrip, GearPaint)
	await _cap_combo(Vector3(-0.08, -0.02, 0.32), Vector3(90, 0, 0), 
		"Wrist.L", palm.l_wrist, Vector3(0, 0, 0), WeaponGrip, GearPaint)

	print("TUNE_OK")
	quit()


func _measure_palm() -> Dictionary:
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	root.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.strip_arm_animation_tracks(anim)
	anim.play("Idle_Neutral")
	for i in 14:
		await process_frame
	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var mi: MeshInstance3D = null
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		mi = n as MeshInstance3D
		if mi and mi.mesh and mi.skin:
			break
	var skin: Skin = mi.skin
	var skel_node: = mi.get_node(mi.skeleton) as Skeleton3D
	var bone_xfs: Array[Transform3D] = []
	bone_xfs.resize(skin.get_bind_count())
	var bind_names: PackedStringArray = PackedStringArray()
	bind_names.resize(skin.get_bind_count())
	for bi in skin.get_bind_count():
		var bone_name: = skin.get_bind_name(bi)
		bind_names[bi] = bone_name
		var bone_idx: = skel_node.find_bone(bone_name)
		if bone_idx < 0:
			bone_idx = skin.get_bind_bone(bi)
		bone_xfs[bi] = skel_node.global_transform * skel_node.get_bone_global_pose(bone_idx) * skin.get_bind_pose(bi)

	var wr_i: = -1
	var wl_i: = -1
	for bi in bind_names.size():
		if bind_names[bi] == "Wrist.R":
			wr_i = bi
		if bind_names[bi] == "Wrist.L":
			wl_i = bi

	var r_acc: = Vector3.ZERO
	var r_n: = 0
	var l_acc: = Vector3.ZERO
	var l_n: = 0
	var mesh: = mi.mesh
	for si in mesh.get_surface_count():
		var arr: = mesh.surface_get_arrays(si)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones_a: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights_a: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		for vi in vs.size():
			var w_r: = 0.0
			var w_l: = 0.0
			var p: = Vector3.ZERO
			var wsum: = 0.0
			for k in 4:
				var w: = weights_a[vi * 4 + k]
				var b: = bones_a[vi * 4 + k]
				if w <= 0.0 or b < 0 or b >= bone_xfs.size():
					continue
				p += bone_xfs[b] * vs[vi] * w
				wsum += w
				if b == wr_i:
					w_r += w
				if b == wl_i:
					w_l += w
			if wsum <= 0.0:
				continue
			p /= wsum

			if w_r >= 0.35 and p.x > 0.4:
				r_acc += p
				r_n += 1
			if w_l >= 0.35 and p.x < -0.4:
				l_acc += p
				l_n += 1

	var wr_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
	var wl_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.L"))
	var lal_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LowerArm.L"))
	var r_palm: = r_acc / float(maxi(1, r_n))
	var l_palm: = l_acc / float(maxi(1, l_n))
	print("wrist_weighted R n=", r_n, " ", r_palm, " L n=", l_n, " ", l_palm)
	var out: = {
		"r": wr_g.affine_inverse() * r_palm, 
		"l_wrist": wl_g.affine_inverse() * l_palm, 
		"l_fore": lal_g.affine_inverse() * l_palm, 
		"strap": lal_g.affine_inverse() * lal_g.origin.lerp(l_palm, 0.55), 
	}
	hero.queue_free()
	await process_frame
	return out


func _cap(kind: String, c: Dictionary, WeaponGrip, GearPaint) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(720, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	_lit(stage)
	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.strip_arm_animation_tracks(anim)
	if kind == "spear":
		var wp = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
			"bone": "Wrist.R", "position": c.pos, "rotation_deg": c.rot, "scale": 1.05, 
		})
		if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")

		var sh = WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
			"bone": "LowerArm.L", "position": Vector3(0.04, 0.12, 0.18), "rotation_deg": Vector3.ZERO, "scale": 1.0, 
		})
		if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	else:
		var sh2 = WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
			"bone": c.bone, "position": c.pos, "rotation_deg": c.rot, "scale": 1.0, 
		})
		if sh2: GearPaint.paint_attached(sh2, "res://assets/props/gear/aspis_shield.glb")
		var wp2 = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
			"bone": "Wrist.R", "position": Vector3(-0.08, -0.02, 0.32), "rotation_deg": Vector3(90, 0, 0), "scale": 1.05, 
		})
		if wp2: GearPaint.paint_attached(wp2, "res://assets/props/weapons/dory_spear.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Idle_Neutral")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.0, 1.35, -2.9)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 22:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/TUNE_%s_%s.png" % [kind, c.tag])

	cam.position = Vector3(2.8, 1.2, 0.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/TUNE_%s_%s_side.png" % [kind, c.tag])
	print("saved ", kind, " ", c.tag, " pos=", c.pos)
	vp.queue_free()
	await process_frame


func _cap_combo(sp: Vector3, sr: Vector3, sbone: String, shpos: Vector3, shrot: Vector3, WeaponGrip, GearPaint) -> void :
	var tag: = "combo_%s" % sbone.replace(".", "")
	var vp: = SubViewport.new()
	vp.size = Vector2i(900, 1100)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	_lit(stage)
	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.strip_arm_animation_tracks(anim)
	var wp = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R", "position": sp, "rotation_deg": sr, "scale": 1.05, 
	})
	var sh = WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
		"bone": sbone, "position": shpos, "rotation_deg": shrot, "scale": 1.0, 
	})
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Idle_Neutral")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.05, 1.4, -3.1)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 26:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/TUNE_%s_face.png" % tag)
	cam.position = Vector3(3.0, 1.25, -0.15)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/TUNE_%s_side.png" % tag)
	print("saved ", tag)
	vp.queue_free()
	await process_frame


func _lit(stage: Node3D) -> void :
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.48, 0.56, 0.64)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, 28, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)
