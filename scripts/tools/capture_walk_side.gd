extends SceneTree
func _init(): call_deferred("run")
func run():
	for tag_clip in [["idle", "Idle_Neutral"], ["walk", "Walk"], ["run", "Run"]]:
		await shot(tag_clip[0], tag_clip[1])
	print("WALKSIDE_OK")
	quit()

func shot(tag: String, clip: String) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(900, 700)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.7, 0.75, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, 20, 0)
	light.light_energy = 1.5
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(hero)

	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play(clip)
	anim.seek(0.4, true)
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 28

	cam.position = Vector3(3.2, 1.2, 0.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 20: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/SIDE_%s.png" % tag)

	cam.position = Vector3(1.8, 1.3, 2.2)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/SIDE_%s_34.png" % tag)
	print("saved ", tag)
	vp.queue_free()
	await process_frame
