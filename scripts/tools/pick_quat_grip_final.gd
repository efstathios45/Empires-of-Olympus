extends SceneTree
## Single-attach finalists for Quaternius spear + aspis.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var vp := _stage(700, 900)
	var stage: Node3D = vp.get_child(0)
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var GearPaint = load("res://scripts/utils/gear_paint.gd") if ResourceLoader.exists("res://scripts/utils/gear_paint.gd") else null

	var shield_g := {
		"bone": "Wrist.L",
		"position": Vector3(0.0, 0.04, 0.08),
		"rotation_deg": Vector3(-90.0, 0.0, 90.0),
		"scale": 1.0,
	}
	## Spear: tip-up / forward candidates after normalize (aim +Z).
	var spear_rots := [
		Vector3(0, 0, 90),
		Vector3(0, 0, -90),
		Vector3(90, 0, 90),
		Vector3(-90, 0, 90),
		Vector3(0, 90, 90),
		Vector3(0, -90, 90),
		Vector3(90, 90, 0),
		Vector3(-90, -90, 0),
		Vector3(180, 0, 90),
		Vector3(0, 180, 90),
	]
	var idx := 0
	for rot in spear_rots:
		## Fresh character each trial — avoids mount leaks.
		for c in stage.get_children():
			if c is Node3D and String(c.name) == "hero":
				c.free()
		await process_frame
		var m: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
		m.name = "hero"
		stage.add_child(m)
		ModelUtils.setup_character_for_movement(m, 1.85)
		var anim := m.find_child("AnimationPlayer", true) as AnimationPlayer
		ModelUtils.set_animation_loops(anim)
		anim.play("Idle_Sword")
		var sh = WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", shield_g)
		var wp = WeaponGrip.attach(m, "res://assets/props/weapons/dory_spear.glb", "melee", {
			"bone": "Wrist.R",
			"position": Vector3(0.0, 0.05, 0.0),
			"rotation_deg": rot,
			"scale": 1.05,
		})
		if GearPaint != null:
			if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
			if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
		for i in 8:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_final_%02d.png" % idx)
		print("final_", idx, " spear_rot=", rot, " sh=", sh != null, " wp=", wp != null)
		idx += 1

	## Also Idle_Neutral with best guess rot (0,0,-90) and front+side cameras
	for c in stage.get_children():
		if c is Node3D and String(c.name) == "hero":
			c.free()
	await process_frame
	var m2: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	m2.name = "hero"
	stage.add_child(m2)
	ModelUtils.setup_character_for_movement(m2, 1.85)
	var anim2 := m2.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim2)
	anim2.play("Idle_Neutral")
	var sh2 = WeaponGrip.attach(m2, "res://assets/props/gear/aspis_shield.glb", "shield", shield_g)
	var wp2 = WeaponGrip.attach(m2, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R",
		"position": Vector3(0.0, 0.05, 0.0),
		"rotation_deg": Vector3(0, 0, -90),
		"scale": 1.05,
	})
	if GearPaint != null:
		if sh2: GearPaint.paint_attached(sh2, "res://assets/props/gear/aspis_shield.glb")
		if wp2: GearPaint.paint_attached(wp2, "res://assets/props/weapons/dory_spear.glb")
	var cam := stage.get_node("Cam") as Camera3D
	cam.position = Vector3(2.2, 1.35, 3.0)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_final_idleN_front.png")
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	cam.position = Vector3(3.5, 1.1, 0.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_final_idleN_side.png")
	print("PICK_DONE")
	quit()


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
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 35, 0)
	light.light_energy = 1.25
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.38, 0.33)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.current = true
	cam.fov = 34
	cam.position = Vector3(2.2, 1.4, 3.0)
	cam.look_at(Vector3(0, 1.15, 0), Vector3.UP)
	stage.add_child(cam)
	return vp
