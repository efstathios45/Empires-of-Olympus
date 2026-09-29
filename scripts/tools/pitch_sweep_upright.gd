extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var root: = get_root()
	var vp: = SubViewport.new()
	vp.size = Vector2i(400, 560)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.75, 0.78, 0.82)
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 25, 0)
	light.light_energy = 1.5
	stage.add_child(light)
	var floor: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.2, 0.45, 0.2)
	floor.material_override = fm
	stage.add_child(floor)

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)

	ModelUtils.scale_to_height(m, 1.85)
	ModelUtils.ground_model(m)

	for n in m.find_children("*", "Skeleton3D", true, false):
		var fix = n.get_node_or_null("SkyGazeFix")
		if fix:
			fix.queue_free()
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.play("ual1_Idle")

	print("BASE_MODEL_ROT=", m.rotation)

	var cam: = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	stage.add_child(cam)
	cam.current = true

	cam.position = Vector3(3.5, 1.0, 0.0)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)

	for i in 30:
		await process_frame

	var best_deg: = 0
	var best_score: = 999.0
	var results: Array = []

	for deg in range(-50, 55, 5):
		m.rotation.x = deg_to_rad(float(deg))

		for i in 6:
			await process_frame
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		var img: = vp.get_texture().get_image()
		var path: = "/opt/cursor/artifacts/pitch_sweep_%+d.png" % deg
		img.save_png(path)
		var score: = _silhouette_abs_slope(img)
		results.append([deg, score])
		print("PITCH_DEG=", deg, " SLOPE=", score)
		if score < best_score:
			best_score = score
			best_deg = deg
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	print("BEST_DEG=", best_deg, " BEST_SLOPE=", best_score)

	m.rotation.x = deg_to_rad(float(best_deg))
	for i in 6:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/pitch_sweep_BEST.png")

	cam.position = Vector3(0, 1.0, 3.5)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 6:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/pitch_sweep_BEST_front.png")
	print("SWEEP_OK")
	quit(0)


func _silhouette_abs_slope(img: Image) -> float:

	var w: = img.get_width()
	var h: = img.get_height()
	var bg: = img.get_pixel(2, 2)
	var bands: Array = []
	for bi in 8:
		var y0: = int(h * (0.15 + bi * 0.08))
		var y1: = mini(h - 1, y0 + int(h * 0.05))
		var xs: Array = []
		for y in range(y0, y1):
			for x in range(w):
				var c: = img.get_pixel(x, y)
				var d: float = absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b)
				if d > 0.35:
					xs.append(float(x))
		if xs.size() < 8:
			continue
		var mean: = 0.0
		for v in xs:
			mean += v
		mean /= float(xs.size())
		bands.append(Vector2(mean, float(y0 + y1) * 0.5))
	if bands.size() < 3:
		return 999.0

	var n: = float(bands.size())
	var sum_x: = 0.0
	var sum_y: = 0.0
	var sum_xy: = 0.0
	var sum_yy: = 0.0
	for b in bands:
		sum_x += b.x
		sum_y += b.y
		sum_xy += b.x * b.y
		sum_yy += b.y * b.y
	var den: = n * sum_yy - sum_y * sum_y
	if absf(den) < 0.001:
		return 999.0
	var a: = (n * sum_xy - sum_x * sum_y) / den
	return absf(a)
