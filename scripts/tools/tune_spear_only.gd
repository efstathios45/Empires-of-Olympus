extends SceneTree
## Tune dory spear on Quaternius Wrist.R; keep proven shield grip.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var vp := _stage(640, 820)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim := m.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	var skel: Skeleton3D = null
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")

	var shield_g := {
		"bone": "Wrist.L",
		"position": Vector3(0.0, 0.04, 0.08),
		"rotation_deg": Vector3(-90.0, 0.0, 90.0),
		"scale": 1.0,
	}
	var sh = WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", shield_g)
	if sh and GearPaint:
		GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36
	cam.position = Vector3(2.3, 1.4, 3.1)
	cam.look_at(Vector3(0, 1.15, 0), Vector3.UP)

	var rots := [
		Vector3(0, 0, 0),
		Vector3(90, 0, 0),
		Vector3(-90, 0, 0),
		Vector3(0, 90, 0),
		Vector3(0, -90, 0),
		Vector3(0, 0, 90),
		Vector3(0, 0, -90),
		Vector3(90, 90, 0),
		Vector3(-90, 90, 0),
		Vector3(90, 0, 90),
		Vector3(-90, 0, -90),
		Vector3(0, 180, 0),
		Vector3(180, 0, 0),
		Vector3(0, 90, 90),
		Vector3(45, 0, -90),
		Vector3(-45, 0, -90),
	]
	var idx := 0
	for rot in rots:
		## Remove prior melee mount only
		for child in skel.get_children():
			if String(child.name) == "WeaponMount":
				## keep shield mount (first) — WeaponGrip names both WeaponMount
				pass
		## Delete all WeaponMount then re-add shield+spear
		var to_del: Array = []
		for child in skel.get_children():
			if String(child.name).begins_with("WeaponMount"):
				to_del.append(child)
		for c in to_del:
			skel.remove_child(c)
			c.free()
		await process_frame
		sh = WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", shield_g)
		if sh and GearPaint:
			GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
		var wp = WeaponGrip.attach(m, "res://assets/props/weapons/dory_spear.glb", "melee", {
			"bone": "Wrist.R",
			"position": Vector3(0.0, 0.04, 0.0),
			"rotation_deg": rot,
			"scale": 1.05,
		})
		if wp and GearPaint:
			GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
		anim.play("Idle_Sword")
		for i in 8:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_spear_%02d.png" % idx)
		print("spear_", idx, " rot=", rot)
		idx += 1

	## Prove Idle_Neutral + Walk + Slash with last good-looking rot (update after review)
	print("SPEAR_TUNE_DONE")
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
	return vp
