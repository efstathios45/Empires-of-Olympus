extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(1600, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.52, 0.58, 0.65)
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, 30, 0)
	light.light_energy = 1.35
	stage.add_child(light)
	var floor: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(36, 14)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.28, 0.42, 0.24)
	floor.material_override = fm
	stage.add_child(floor)

	var NpcScript = load("res://scripts/npc.gd")
	var specs: = [
		["oracle", "Melite", "res://assets/characters/greek_oracle/greek_oracle.glb", "", 1.75, "Idle_Neutral"], 
		["smith", "Brontes", "res://assets/characters/greek_smith/greek_smith.glb", "", 1.8, "Idle_Neutral"], 
		["merchant", "Trader", "res://assets/characters/greek_merchant/greek_merchant.glb", "", 1.78, "Idle_Neutral"], 
		["woman", "Citizen", "res://assets/characters/greek_citizen_woman/greek_citizen_woman.glb", "", 1.68, "Idle_Neutral"], 
		["guard", "Lysandros", "res://assets/characters/greek_guard/greek_guard.glb", "", 1.84, "Idle_Sword"], 
	]
	var x: = -8.0
	var anim_ok: = 0
	for s in specs:
		var n: Node = NpcScript.create_flavour(
			String(s[0]), String(s[1]), String(s[2]), String(s[3]), 
			Vector3(x, 0, 0), float(s[4]), 180.0, String(s[5]), "hello")
		stage.add_child(n)
		await process_frame
		await process_frame
		var ap: = n.find_child("AnimationPlayer", true, true) as AnimationPlayer
		if ap != null and ap.is_playing():
			anim_ok += 1
		x += 4.0

	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	stage.add_child(hero)
	hero.position = Vector3(10.0, 0, 0)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var hap: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	if hap != null and hap.has_animation("Walk"):
		hap.play("Walk")
	for i in 40:
		if hap != null:
			hap.advance(1.0 / 60.0)
		await process_frame

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(1.0, 1.65, 9.2)
	cam.look_at(Vector3(1.0, 1.05, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/hellenic_pose_lineup.png")
	print("NPC_ANIM_PLAYING=", anim_ok, "/", specs.size())
	print("CAPTURE_HELLENIC_POSE_OK")
	quit(0)
