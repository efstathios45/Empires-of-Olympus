extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	await _strip("x")
	print("WALK_STRIP_OK")
	quit(0)


func _strip(tag: String) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(360, 520)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.66)
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(8, 8)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.process_priority = -100
	skel.get_node("LegPlantFix").process_priority = 1000
	anim.play("ual1_Walk")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	cam.position = Vector3(3.5, 1.05, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for frame in 8:
		for i in 5:
			await process_frame
		var lf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
		var rf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("RightFoot"))).origin
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/WSTRIP_%s_%d.png" % [tag, frame])
		print("frame ", frame, " LFz=", snapped(lf.z, 0.01), " RFz=", snapped(rf.z, 0.01), 
			" LFy=", snapped(lf.y, 0.01), " RFy=", snapped(rf.y, 0.01))
	vp.queue_free()
	await process_frame
