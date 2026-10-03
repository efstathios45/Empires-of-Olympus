extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(1400, 700)
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
	pm.size = Vector2(30, 12)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)

	var NpcScript = load("res://scripts/npc.gd")
	var specs: = [
		["priestess", "Melite", "res://assets/characters/oracle_priestess/oracle_priestess.glb", 
			"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres", 1.75, "ual1_Idle"], 
		["smith", "Brontes", "res://assets/characters/blacksmith_npc/blacksmith_npc.glb", 
			"res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres", 1.8, "ual1_Idle"], 
		["merchant", "Trader", "res://assets/characters/citizen_merchant/citizen_merchant.glb", 
			"res://assets/characters/citizen_merchant/citizen_merchant_animations.tres", 1.78, "ual1_Idle"], 
		["woman", "Citizen", "res://assets/characters/citizen_woman/citizen_woman.glb", 
			"res://assets/characters/citizen_woman/citizen_woman_animations.tres", 1.68, "ual1_Idle"], 
		["guard", "Guard", "res://assets/characters/city_guard/city_guard.glb", 
			"res://assets/characters/city_guard/city_guard_animations.tres", 1.84, "ual1_Idle"], 
		["hoplite", "Hero", "res://assets/characters/spartan_hoplite/spartan_hoplite.glb", 
			"res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres", 1.85, "ual1_Idle"], 
	]
	var x: = -7.5
	var planted: = 0
	for s in specs:

		var n: Node = NpcScript.create_flavour(
			String(s[0]), String(s[1]), String(s[2]), String(s[3]), 
			Vector3(x, 0, 0), float(s[4]), 180.0, String(s[5]), "hello")
		stage.add_child(n)

		await process_frame
		await process_frame
		var skel: Skeleton3D = null
		for c in n.find_children("*", "Skeleton3D", true, false):
			skel = c
			break
		if skel != null and skel.has_node("LegPlantFix"):
			planted += 1
		x += 3.0

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 42
	cam.position = Vector3(0.0, 1.7, 8.5)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 36:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/NPC_lineup_after.png")
	print("PLANTED=", planted, "/", specs.size())
	assert (planted == specs.size(), "not all planted")

	print("CAPTURE_NPC_LINEUP_OK")
	quit(0)
