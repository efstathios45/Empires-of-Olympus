extends SceneTree

func _init(): call_deferred("run")

func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var cases: = [
		{"tag": "A_raw_idle", "setup": false, "greek": false, "clip": "Idle_Neutral", "yaw": 0.0}, 
		{"tag": "B_setup_idle", "setup": true, "greek": false, "clip": "Idle_Neutral", "yaw": 0.0}, 
		{"tag": "C_setup_walk", "setup": true, "greek": false, "clip": "Walk", "yaw": 0.0}, 
		{"tag": "D_greek_idle", "setup": true, "greek": true, "clip": "Idle_Neutral", "yaw": 0.0}, 
		{"tag": "E_greek_walk", "setup": true, "greek": true, "clip": "Walk", "yaw": 0.0}, 
		{"tag": "F_face_plusz", "setup": true, "greek": false, "clip": "Walk", "yaw": 0.0}, 
		{"tag": "G_face_minusz_pi", "setup": true, "greek": false, "clip": "Walk", "yaw": PI}, 
	]
	for c in cases:
		await _shot(c, GreekLook)
	print("ARM_BISECT_OK")
	quit()

func _shot(c: Dictionary, GreekLook) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(640, 800)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 35, 0)
	light.light_energy = 1.35
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(hero)
	print(c["tag"], " after_add rot=", hero.rotation, " scale=", hero.scale)
	if c["setup"]:
		ModelUtils.setup_character_for_movement(hero, 1.85)
		print(c["tag"], " after_setup rot=", hero.rotation, " scale=", hero.scale, " pos=", hero.position)
	if c["greek"]:
		GreekLook.apply(hero, "hoplite")
	hero.rotation.y = float(c["yaw"])
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play(String(c["clip"]))
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30

	cam.position = Vector3(0.85, 1.4, 2.9)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	if String(c["tag"]).begins_with("G_"):

		cam.position = Vector3(0.85, 1.4, -2.9)
		cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 28:
		await process_frame
	var path: = "/opt/cursor/artifacts/ARMBI_%s.png" % c["tag"]
	vp.get_texture().get_image().save_png(path)
	print("saved ", path)
	vp.queue_free()
	await process_frame
