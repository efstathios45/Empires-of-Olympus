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

	var body: = CharacterBody3D.new()
	body.set_script(load("res://scripts/player.gd"))
	stage.add_child(body)
	for i in 40:
		await process_frame
	body.set_physics_process(false)
	body.global_position = Vector3.ZERO
	if body.anim:
		body.anim.play("ual1_Idle")
	for i in 24:
		await process_frame

	var skel: Skeleton3D
	for n in body.mesh_root.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var hi: = skel.find_bone("Head")
	var hips: = skel.find_bone("Hips")
	var ht: = skel.global_transform * skel.get_bone_global_pose(hi)
	var hp: = skel.global_transform * skel.get_bone_global_pose(hips)
	var upright: = (ht.origin - hp.origin).normalized().dot(Vector3.UP)
	var fwd_up: = ( - ht.basis.z).normalized().dot(Vector3.UP)
	print("HERO_UPRIGHT=", upright, " FWD_UP=", fwd_up, " HIPS_E=", skel.get_bone_pose(hips).basis.get_euler())

	var cam: = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	stage.add_child(cam)
	cam.current = true

	cam.position = Vector3(3.4, 1.05, 0.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/upright_hero_side.png")
	print("SAVED upright_hero_side.png")
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	cam.position = Vector3(0.0, 1.05, 3.4)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/upright_hero_front.png")
	print("SAVED upright_hero_front.png")


	var npc_scene: = "res://scripts/npc.gd"
	var npc: = Node3D.new()
	npc.set_script(load(npc_scene))

	var npc_paths: = [
		"res://scenes/npc_citizen.tscn", 
		"res://scenes/npcs/citizen.tscn", 
	]
	var npc_node: Node3D = null
	for p in npc_paths:
		if ResourceLoader.exists(p):
			npc_node = load(p).instantiate()
			break
	if npc_node == null:

		var m2: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
		stage.add_child(m2)
		m2.global_position = Vector3(2.2, 0, 0)
		ModelUtils.setup_character_for_movement(m2, 1.85)
		var a2: = m2.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if a2:
			var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres")
			if a2.has_animation_library(""):
				a2.remove_animation_library("")
			a2.add_animation_library("", lib)
			a2.play("ual1_Idle")
		for i in 20:
			await process_frame
		cam.position = Vector3(2.2 + 3.4, 1.05, 0)
		cam.look_at(Vector3(2.2, 1.0, 0), Vector3.UP)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		for i in 6:
			await process_frame
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/upright_npc_side.png")
		print("SAVED upright_npc_side.png (hoplite stand-in)")
	print("CAPTURE_UPRIGHT_OK")
	quit(0)
