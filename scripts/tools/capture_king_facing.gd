extends SceneTree
func _init(): call_deferred("run")
func run():
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var vp: = SubViewport.new()
	vp.size = Vector2i(800, 1000)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.55, 0.65)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.75)
	e.ambient_light_energy = 0.9
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 35, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var stripe: = MeshInstance3D.new()
	var box: = BoxMesh.new()
	box.size = Vector3(0.35, 0.02, 6.0)
	stripe.mesh = box
	stripe.position = Vector3(0, 0.01, -3.0)
	var sm: = StandardMaterial3D.new()
	sm.albedo_color = Color(0.15, 0.85, 0.25)
	stripe.material_override = sm
	stage.add_child(stripe)

	for variant in [
		{"tag": "stock0", "yaw_extra": 0.0, "greek": false}, 
		{"tag": "stockPI", "yaw_extra": PI, "greek": false}, 
		{"tag": "greekPI", "yaw_extra": PI, "greek": true}, 
	]:
		var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
		stage.add_child(hero)
		ModelUtils.setup_character_for_movement(hero, 1.85)
		if variant["greek"]:
			GreekLook.apply(hero, "hoplite")
		var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
		ModelUtils.set_animation_loops(anim)
		var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
		var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
		if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
		if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")

		hero.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1)) + variant["yaw_extra"]
		anim.play("Walk")
		var cam: = Camera3D.new()
		stage.add_child(cam)
		cam.current = true
		cam.fov = 32

		cam.position = Vector3(1.0, 1.45, -3.4)
		cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
		for i in 24: await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KINGFIX_%s_face.png" % variant["tag"])

		cam.position = Vector3(3.2, 1.35, 0.0)
		cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
		for i in 16: await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KINGFIX_%s_side.png" % variant["tag"])
		print("saved ", variant["tag"])
		hero.queue_free()
		cam.queue_free()
		await process_frame
	print("KINGFIX_OK")
	quit()
