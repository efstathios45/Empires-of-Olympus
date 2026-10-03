extends SceneTree

func _init(): call_deferred("run")

func run():
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")

	var spears: Array = [
		Vector3(-0.08, 0.08, 0.34), 
		Vector3(-0.1, 0.1, 0.38), 
		Vector3(-0.12, 0.12, 0.4), 
		Vector3(-0.06, 0.14, 0.36), 
		Vector3(-0.14, 0.06, 0.42), 
	]
	var shields: Array = [
		{"bone": "LowerArm.L", "pos": Vector3(0.04, 0.18, 0.22)}, 
		{"bone": "LowerArm.L", "pos": Vector3(0.02, 0.16, 0.26)}, 
		{"bone": "Wrist.L", "pos": Vector3(0.08, 0.1, 0.36)}, 
		{"bone": "Wrist.L", "pos": Vector3(0.06, 0.08, 0.4)}, 
		{"bone": "LowerArm.L", "pos": Vector3(0.0, 0.2, 0.28)}, 
	]
	for i in spears.size():
		await _shot("sp%d" % i, spears[i], shields[2], WeaponGrip, GearPaint)
	for i in shields.size():
		await _shot("sh%d" % i, spears[2], shields[i], WeaponGrip, GearPaint)

	await _shot("FINAL", Vector3(-0.12, 0.12, 0.4), {"bone": "Wrist.L", "pos": Vector3(0.08, 0.1, 0.36)}, WeaponGrip, GearPaint)
	print("PICK_OK")
	quit()


func _shot(tag: String, spear_pos: Vector3, shield: Dictionary, WeaponGrip, GearPaint) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(800, 1000)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
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
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.strip_arm_animation_tracks(anim)
	var wp = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R", "position": spear_pos, "rotation_deg": Vector3(90, 0, 0), "scale": 1.05, 
	})
	var sh = WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
		"bone": shield.bone, "position": shield.pos, "rotation_deg": Vector3.ZERO, "scale": 1.0, 
	})
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Idle_Neutral")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.0, 1.35, -2.95)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 22:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PICK_%s_face.png" % tag)
	cam.position = Vector3(2.9, 1.15, 0.05)
	cam.look_at(Vector3(0.1, 0.95, 0), Vector3.UP)
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PICK_%s_side.png" % tag)
	print("saved ", tag, " spear=", spear_pos, " shield=", shield)
	vp.queue_free()
	await process_frame
