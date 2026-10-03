extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :

	var vp: = SubViewport.new()
	vp.size = Vector2i(720, 960)
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
	light.rotation_degrees = Vector3(-50, 25, 0)
	light.light_energy = 1.35
	stage.add_child(light)
	var floor: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.22, 0.38, 0.2)
	floor.material_override = fm
	stage.add_child(floor)

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert (skel != null and not skel.has_node("SkyGazeFix"))
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.play("ual1_Idle")
	for i in 30:
		await process_frame

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	cam.position = Vector3(3.5, 1.05, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HUMAN_raw_idle_side.png")
	print("SAVED HUMAN_raw_idle_side.png")

	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 50
	cam.position = Vector3(0, 2.6, -5.2)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HUMAN_raw_idle_behind.png")
	print("SAVED HUMAN_raw_idle_behind.png")

	var hi: = skel.find_bone("Head")
	var hips: = skel.find_bone("Hips")
	var ht: = skel.global_transform * skel.get_bone_global_pose(hi)
	var hp: = skel.global_transform * skel.get_bone_global_pose(hips)
	var col: = (ht.origin - hp.origin).normalized()
	print("SIDE_UPRIGHT=", col.dot(Vector3.UP), " SLOPE=", Vector2(col.x, col.z).length())


	vp.queue_free()
	await process_frame
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("NO_GAMESTATE")
		quit(1)
		return
	gs.empire = "sparta"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	change_scene_to_file("res://scenes/game_world.tscn")
	for i in 150:
		await process_frame
	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	if player == null:
		print("NO_PLAYER")
		quit(1)
		return
	player.cam_pitch = player.CAM_PITCH_DEFAULT
	player.cam_yaw = deg_to_rad(35.0)
	player.camera_pivot.rotation.y = player.cam_yaw
	player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true
	for i in 20:
		await process_frame
	print("DIST=", player.spring_arm.spring_length, " PITCH=", rad_to_deg(player.cam_pitch))
	root.get_texture().get_image().save_png("/opt/cursor/artifacts/FIXED_cam_human.png")
	print("SAVED FIXED_cam_human.png")
	print("CAPTURE_HUMAN_SIDE_OK")
	quit(0)
