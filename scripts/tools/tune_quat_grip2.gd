extends SceneTree
## Finer shield + spear grip sweep on Wrist.L / Wrist.R for Quaternius.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var vp := _stage(640, 800)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim := m.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	anim.play("Idle_Sword")
	var skel: Skeleton3D = null
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 34
	cam.position = Vector3(2.4, 1.4, 3.0)
	cam.look_at(Vector3(0.05, 1.15, 0.1), Vector3.UP)

	var WeaponGrip = load("res://scripts/weapon_grip.gd")

	## Shield candidates on Wrist.L
	var shield_trials := [
		{"bone": "Wrist.L", "position": Vector3(0.02, 0.03, 0.06), "rotation_deg": Vector3(0, 90, 0), "scale": 1.0},
		{"bone": "Wrist.L", "position": Vector3(0.02, 0.03, 0.06), "rotation_deg": Vector3(90, 0, 0), "scale": 1.0},
		{"bone": "Wrist.L", "position": Vector3(0.02, 0.03, 0.06), "rotation_deg": Vector3(0, 0, 90), "scale": 1.0},
		{"bone": "Wrist.L", "position": Vector3(0.0, 0.04, 0.08), "rotation_deg": Vector3(-90, 0, 90), "scale": 1.0},
		{"bone": "Wrist.L", "position": Vector3(0.0, 0.04, 0.08), "rotation_deg": Vector3(0, 90, 90), "scale": 1.0},
		{"bone": "Wrist.L", "position": Vector3(0.04, 0.0, 0.05), "rotation_deg": Vector3(90, 90, 0), "scale": 1.0},
		{"bone": "Wrist.L", "position": Vector3(0.0, 0.02, 0.1), "rotation_deg": Vector3(180, 90, 0), "scale": 1.0},
		{"bone": "LowerArm.L", "position": Vector3(0.0, 0.18, 0.06), "rotation_deg": Vector3(-90, 0, 90), "scale": 1.0},
		{"bone": "LowerArm.L", "position": Vector3(0.0, 0.18, 0.06), "rotation_deg": Vector3(0, 90, 0), "scale": 1.0},
		{"bone": "LowerArm.L", "position": Vector3(0.0, 0.2, 0.08), "rotation_deg": Vector3(90, 0, 90), "scale": 1.05},
		## skip_normalize — keep authored aspis orientation
		{"bone": "Wrist.L", "position": Vector3(0.0, 0.05, 0.08), "rotation_deg": Vector3(0, 90, 0), "scale": 0.55, "skip_normalize": true},
		{"bone": "Wrist.L", "position": Vector3(0.0, 0.05, 0.08), "rotation_deg": Vector3(90, 0, 90), "scale": 0.55, "skip_normalize": true},
		{"bone": "Wrist.L", "position": Vector3(0.05, 0.0, 0.05), "rotation_deg": Vector3(0, 0, 0), "scale": 0.55, "skip_normalize": true},
		{"bone": "LowerArm.L", "position": Vector3(0.0, 0.15, 0.1), "rotation_deg": Vector3(90, 90, 0), "scale": 0.55, "skip_normalize": true},
	]
	var idx := 0
	for g in shield_trials:
		_clear_mounts(skel)
		await process_frame
		WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", g)
		## Fixed spear candidate while tuning shield
		WeaponGrip.attach(m, "res://assets/props/weapons/dory_spear.glb", "melee", {
			"bone": "Wrist.R",
			"position": Vector3(0.0, 0.04, 0.0),
			"rotation_deg": Vector3(90, 0, 0),
			"scale": 1.0,
		})
		for i in 5:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_s_%02d.png" % idx)
		print("s_", idx, " ", g)
		idx += 1

	## Spear-only sweeps with best-looking shield later; capture spear variants
	_clear_mounts(skel)
	await process_frame
	## Use shield trial that looked ok — we'll pick after; for now Wrist.L Z-out
	WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", {
		"bone": "Wrist.L", "position": Vector3(0.0, 0.04, 0.08),
		"rotation_deg": Vector3(-90, 0, 90), "scale": 1.0,
	})
	var spear_trials := [
		Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(-90, 0, 0), Vector3(0, 90, 0),
		Vector3(0, 0, 90), Vector3(0, 0, -90), Vector3(90, 0, 90), Vector3(-90, 90, 0),
		Vector3(0, -90, 90), Vector3(180, 0, 0),
	]
	idx = 0
	for rot in spear_trials:
		## remove only weapon mounts named for melee — wipe all and reattach both
		_clear_mounts(skel)
		await process_frame
		WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", {
			"bone": "Wrist.L", "position": Vector3(0.0, 0.04, 0.08),
			"rotation_deg": Vector3(-90, 0, 90), "scale": 1.0,
		})
		WeaponGrip.attach(m, "res://assets/props/weapons/dory_spear.glb", "melee", {
			"bone": "Wrist.R",
			"position": Vector3(0.0, 0.04, 0.0),
			"rotation_deg": rot,
			"scale": 1.0,
		})
		for i in 5:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_w_%02d.png" % idx)
		print("w_", idx, " rot=", rot)
		idx += 1

	print("TUNE2_DONE")
	quit()


func _clear_mounts(skel: Skeleton3D) -> void:
	for child in skel.get_children():
		var nm := String(child.name)
		if nm.begins_with("WeaponMount") or nm.begins_with("Shield") or nm.begins_with("Grip"):
			child.free()


func _stage(w: int, h: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65, 0.66, 0.7)
	e.ambient_light_energy = 0.65
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 35, 0)
	light.light_energy = 1.2
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.38, 0.33)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
