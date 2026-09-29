extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")

	var vp: = _stage(1400, 800)
	var stage: Node3D = vp.get_child(0)

	var hero: Node3D = load("res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb").instantiate()
	hero.name = "hero_hoplite"
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)

	var sh = WeaponGrip.attach(hero, "res://assets/props/gear/aspis_shield.glb", "shield", {
		"bone": "Wrist.L", 
		"position": Vector3(0.0, 0.04, 0.08), 
		"rotation_deg": Vector3(-90.0, 0.0, 90.0), 
		"scale": 1.0, 
	})
	var wp = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R", 
		"position": Vector3(0.0, 0.04, 0.0), 
		"rotation_deg": Vector3(-90.0, 0.0, 0.0), 
		"scale": 1.05, 
	})
	if sh:

		for mi in sh.find_children("*", "MeshInstance3D", true, false):
			var mat: = StandardMaterial3D.new()
			mat.albedo_color = Color(0.72, 0.55, 0.28)
			mat.metallic = 0.55
			mat.roughness = 0.4
			if ResourceLoader.exists("res://assets/props/gear/aspis_face.png"):
				mat.albedo_texture = load("res://assets/props/gear/aspis_face.png")
				mat.albedo_color = Color(1, 1, 1)
			mi.material_override = mat
	if wp and GearPaint:
		GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	var helm: = hero.find_child("CorinthianHelmMount", true, false)
	var pack: = hero.find_child("Backpack", true, false)
	print("greek helm=", helm != null, " backpack_hidden=", pack == null or not pack.visible)
	print("clips idle=", HeroAnim.resolve(anim, "idle"), 
		" walk=", HeroAnim.resolve(anim, "walk"), 
		" atk=", HeroAnim.resolve(anim, "attack_1"))

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 38
	cam.position = Vector3(2.4, 1.45, 3.2)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)

	anim.play("Idle_Sword")
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEKLOOK_hero_idle.png")

	anim.play("Walk")
	for i in 20:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEKLOOK_hero_walk.png")

	anim.play("Sword_Slash")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEKLOOK_hero_slash.png")

	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	cam.position = Vector3(3.6, 1.15, 0.05)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	anim.play("Idle_Sword")
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEKLOOK_hero_side.png")

	vp.queue_free()
	await process_frame
	vp = _stage(1600, 720)
	stage = vp.get_child(0)
	cam = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36
	cam.position = Vector3(0, 1.7, 14.5)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)

	var entries: = [
		["res://assets/characters/quaternius_oracle_witch/oracle_witch.glb", 1.72, "oracle"], 
		["res://assets/characters/quaternius_smith_worker/smith_worker.glb", 1.8, "smith"], 
		["res://assets/characters/quaternius_merchant_farmer/merchant_farmer.glb", 1.78, "merchant"], 
		["res://assets/characters/quaternius_citizen_beach/citizen_beach.glb", 1.78, "merchant"], 
		["res://assets/characters/quaternius_woman_casual/woman_casual.glb", 1.68, "citizen"], 
		["res://assets/characters/quaternius_woman_formal/woman_formal.glb", 1.68, "citizen"], 
		["res://assets/characters/quaternius_woman_worker/woman_worker.glb", 1.68, "citizen"], 
		["res://assets/characters/quaternius_guard_soldier_f/guard_soldier_f.glb", 1.78, "guard"], 
		["res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb", 1.85, "hoplite"], 
	]
	var x: = -12.0
	for e in entries:
		var n: Node3D = load(String(e[0])).instantiate()
		stage.add_child(n)
		n.position = Vector3(x, 0, 0)
		ModelUtils.setup_character_for_movement(n, float(e[1]))
		GreekLook.apply(n, String(e[2]))
		var a: = n.find_child("AnimationPlayer", true) as AnimationPlayer
		if a and a.has_animation("Idle_Sword") and String(e[2]) in ["hoplite", "guard"]:
			a.play("Idle_Sword")
		elif a and a.has_animation("Idle_Neutral"):
			a.play("Idle_Neutral")
		elif a and a.has_animation("Idle"):
			a.play("Idle")
		var bp: = n.find_child("Backpack", true, false)
		var hm: = n.find_child("CorinthianHelmMount", true, false)
		print("npc ", n.name, " role=", e[2], " helm=", hm != null, 
			" pack_vis=", bp != null and bp.visible)
		x += 3.0
	for i in 18:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEKLOOK_npc_lineup.png")

	print("GREEKLOOK_PROOF_OK")
	quit()


func _stage(w: int, h: int) -> SubViewport:
	var vp: = SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.68, 0.6)
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 28, 0)
	light.light_energy = 1.25
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(36, 16)
	floor_mi.mesh = plane
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.4, 0.32)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
