extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var root: = get_root()
	var vp: = SubViewport.new()
	vp.size = Vector2i(720, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.7)
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 35, 0)
	light.light_energy = 1.35
	stage.add_child(light)
	var floor: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(12, 12)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.28, 0.32, 0.24)
	floor.material_override = fm
	stage.add_child(floor)

	var glb: = "res://assets/characters/citizen_woman/citizen_woman.glb"
	var m: Node3D = load(glb).instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.7)
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var lib_path: = "res://assets/characters/citizen_woman/citizen_woman_animations.tres"
	if anim and ResourceLoader.exists(lib_path):
		var lib = load(lib_path)
		if anim.has_animation_library(""):
			anim.remove_animation_library("")
		anim.add_animation_library("", lib)
		if anim.has_animation("ual1_Idle"):
			anim.play("ual1_Idle")
		elif anim.get_animation_list().size() > 0:
			anim.play(anim.get_animation_list()[0])
	for i in 36:
		await process_frame
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	if skel:
		var hi: = skel.find_bone("Head")
		var hips: = skel.find_bone("Hips")
		if hi >= 0 and hips >= 0:
			var ht: = skel.global_transform * skel.get_bone_global_pose(hi)
			var hp: = skel.global_transform * skel.get_bone_global_pose(hips)
			print(
				"WOMAN_UPRIGHT=", (ht.origin - hp.origin).normalized().dot(Vector3.UP), 
				" FWD_UP=", ( - ht.basis.z).normalized().dot(Vector3.UP), 
				" HAS_FIX=", skel.has_node("SkyGazeFix"), 
				" FIX_CLASS=", skel.get_node("SkyGazeFix").get_class() if skel.has_node("SkyGazeFix") else "?"
			)
	var cam: = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	stage.add_child(cam)
	cam.current = true
	cam.position = Vector3(3.2, 1.0, 0)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/upright_woman_side.png")
	print("SAVED upright_woman_side.png")
	quit(0)
