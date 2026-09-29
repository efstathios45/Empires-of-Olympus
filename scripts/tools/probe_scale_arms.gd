extends SceneTree
func _init(): call_deferred("run")
func run():
	var cases = [
		{"tag": "scale1_walk", "scale": 1.0}, 
		{"tag": "scale119_walk", "scale": 1.195823}, 
		{"tag": "scale_mesh_only", "scale_mesh_only": true}, 
	]
	for c in cases:
		await shot(c)
	print("SCALE_ARMS_OK")
	quit()

func shot(c: Dictionary) -> void :
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

	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	wrap.add_child(hero)

	await process_frame
	var aabb: = AABB()
	var first: = true
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi.mesh == null: continue
		var a: AABB = mi.global_transform * mi.get_aabb()
		if first: aabb = a;first = false
		else: aabb = aabb.merge(a)
	print(c["tag"], " raw_h=", aabb.size.y)

	if c.get("scale_mesh_only", false):

		wrap.scale = Vector3.ONE * (1.85 / maxf(0.01, aabb.size.y))
		ModelUtils.ground_model(wrap)
	elif c.has("scale"):
		hero.scale = Vector3.ONE * float(c["scale"])
		ModelUtils.ground_model(hero)

	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Walk")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(0.85, 1.4, 2.9)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 28: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/SCALE_%s.png" % c["tag"])
	print("saved ", c["tag"])
	vp.queue_free()
	await process_frame
