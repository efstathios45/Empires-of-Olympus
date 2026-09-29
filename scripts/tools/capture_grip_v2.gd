extends SceneTree
func _init(): call_deferred("run")
func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var pairs = [

		{"tag": "s90_0_0", "spear": Vector3(90, 0, 0), "shield": Vector3(0, 0, 0)}, 
		{"tag": "s90_0_180", "spear": Vector3(90, 0, 180), "shield": Vector3(0, 0, 0)}, 
		{"tag": "s90_90_0", "spear": Vector3(90, 90, 0), "shield": Vector3(0, 90, 0)}, 
		{"tag": "s90_-90_0", "spear": Vector3(90, -90, 0), "shield": Vector3(0, -90, 0)}, 
		{"tag": "s0_90_90", "spear": Vector3(0, 90, 90), "shield": Vector3(90, 0, 0)}, 
		{"tag": "s_m90_0_0", "spear": Vector3(-90, 0, 0), "shield": Vector3(0, 180, 0)}, 
		{"tag": "s90_0_0_sh90", "spear": Vector3(90, 0, 0), "shield": Vector3(-90, 0, 0)}, 
		{"tag": "s90_0_0_sh0_90", "spear": Vector3(90, 0, 0), "shield": Vector3(0, 0, 90)}, 
		{"tag": "combat_s90", "spear": Vector3(90, 0, 0), "shield": Vector3(0, 0, 0), "clip": "Idle_Sword"}, 
		{"tag": "combat_s90b", "spear": Vector3(90, 0, 180), "shield": Vector3(0, 0, 0), "clip": "Idle_Sword"}, 
	]
	for p in pairs:
		await shot(p, GreekLook, WeaponGrip)
	print("GRIPV2_OK")
	quit()

func shot(p: Dictionary, GreekLook, WeaponGrip) -> void :
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
	var clip: = String(p.get("clip", "Idle_Neutral"))
	anim.play(clip)
	WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R", "position": Vector3(0.02, 0.06, 0.0), 
		"rotation_deg": p["spear"], "scale": 1.05, 
	})
	WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
		"bone": "Wrist.L", "position": Vector3(0.0, 0.02, 0.06), 
		"rotation_deg": p["shield"], "scale": 1.0, 
	})
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.2, 1.4, -3.0)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 22: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GRIPV2_%s_front.png" % p["tag"])
	cam.position = Vector3(3.0, 1.3, -0.5)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GRIPV2_%s_side.png" % p["tag"])
	print("saved ", p["tag"])
	vp.queue_free()
	await process_frame
