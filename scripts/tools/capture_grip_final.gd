extends SceneTree
func _init(): call_deferred("run")
func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	var WeaponGrip = load("res://scripts/weapon_grip.gd")

	var trials = [
		{"tag": "A", "spear_r": Vector3(90, 0, 0), "spear_p": Vector3(0.02, 0.08, 0.0), 
			"shield_r": Vector3(0, 0, 0), "shield_p": Vector3(0.0, 0.05, 0.02), "shield_bone": "Wrist.L"}, 
		{"tag": "B", "spear_r": Vector3(90, 0, 0), "spear_p": Vector3(0.02, 0.08, 0.0), 
			"shield_r": Vector3(0, 180, 0), "shield_p": Vector3(0.0, 0.05, 0.02), "shield_bone": "Wrist.L"}, 
		{"tag": "C", "spear_r": Vector3(90, 0, 180), "spear_p": Vector3(0.02, 0.08, 0.0), 
			"shield_r": Vector3(0, 0, 0), "shield_p": Vector3(0.0, 0.08, 0.0), "shield_bone": "LowerArm.L"}, 
		{"tag": "D", "spear_r": Vector3(90, 0, 0), "spear_p": Vector3(0.0, 0.1, 0.02), 
			"shield_r": Vector3(90, 0, 90), "shield_p": Vector3(0.0, 0.1, 0.0), "shield_bone": "LowerArm.L"}, 
		{"tag": "E", "spear_r": Vector3(90, 0, 0), "spear_p": Vector3(0.02, 0.08, 0.0), 
			"shield_r": Vector3(0, -90, 0), "shield_p": Vector3(0.04, 0.05, 0.0), "shield_bone": "Wrist.L"}, 
		{"tag": "F", "spear_r": Vector3(80, 15, 0), "spear_p": Vector3(0.03, 0.07, 0.0), 
			"shield_r": Vector3(0, 0, 0), "shield_p": Vector3(0.02, 0.06, 0.04), "shield_bone": "Wrist.L"}, 
	]
	for t in trials:
		await shot(t, GreekLook, WeaponGrip, GearPaint)
	print("GRIPFINAL_OK")
	quit()

func shot(t, GreekLook, WeaponGrip, GearPaint) -> void :
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
	e.background_color = Color(0.5, 0.58, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)
	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")
	var wp = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R", "position": t["spear_p"], "rotation_deg": t["spear_r"], "scale": 1.05, 
	})
	var sh = WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
		"bone": t["shield_bone"], "position": t["shield_p"], "rotation_deg": t["shield_r"], "scale": 1.0, 
	})
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.15, 1.4, -3.05)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 22: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GFIN_%s_front.png" % t["tag"])
	cam.position = Vector3(2.8, 1.3, -0.3)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GFIN_%s_side.png" % t["tag"])
	print("saved ", t["tag"])
	vp.queue_free()
	await process_frame
