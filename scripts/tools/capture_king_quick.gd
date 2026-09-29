extends SceneTree
func _init(): call_deferred("run")
func run():
	var vp: = SubViewport.new()
	vp.size = Vector2i(700, 900)
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
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 40, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(hero)

	print("raw scale=", hero.scale, " name=", hero.name)
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		print(" mesh ", mi.name, " vis=", mi.visible, " surfaces=", mi.mesh.get_surface_count() if mi.mesh else -1)
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var mat = mi.get_active_material(s)
				print("   surf", s, " mat=", mat)
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(0.9, 1.4, 2.8)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 30:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KINGFIX_raw_idle.png")
	print("saved raw")


	hero.queue_free()
	await process_frame
	hero = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)

	hero.rotate_y(PI)
	anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	GreekLook.apply(hero, "hoplite")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")

	hero.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1)) + PI
	anim.play("Walk")

	cam.position = Vector3(0.9, 1.4, -3.2)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 30:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KINGFIX_pi_walk_face.png")
	cam.position = Vector3(3.0, 1.35, 0.0)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 20:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KINGFIX_pi_walk_side.png")
	print("KINGFIX_QUICK_OK")
	quit()
