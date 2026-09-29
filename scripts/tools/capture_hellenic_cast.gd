extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var vp: = _stage(1100, 700)
	var stage: Node3D = vp.get_child(0)
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")


	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	hero.name = "greek_hoplite"
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	assert (anim != null)
	ModelUtils.set_animation_loops(anim)
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	var plant: = hero.find_child("LegPlantFix", true, false)
	print("HERO plant=", plant != null, " clips=", anim.get_animation_list())
	assert (plant == null)
	assert (anim.has_animation("Walk"))
	assert (anim.has_animation("Sword_Slash"))
	assert (anim.has_animation("Idle"))
	assert (anim.has_animation("Idle_Neutral"))

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 32
	cam.position = Vector3(2.4, 1.45, 3.4)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)

	anim.play("Idle_Neutral")
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLENIC_hero_idle.png")

	anim.play("Walk")
	for i in 22:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLENIC_hero_walk.png")

	anim.play("Kick_Right")
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLENIC_hero_attack.png")

	anim.play("Idle_Sword")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLENIC_hero_block.png")


	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	cam.position = Vector3(3.6, 1.15, 0.05)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	anim.play("Walk")
	for i in 18:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLENIC_hero_walk_side.png")


	hero.queue_free()
	await process_frame
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(0.0, 1.7, 7.2)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	var cast: = [
		["res://assets/characters/greek_hoplite/greek_hoplite.glb", 1.85, "Idle_Neutral"], 
		["res://assets/characters/greek_hoplite/greek_hoplite.glb", 1.84, "Idle_Sword"], 
		["res://assets/characters/citizen_merchant/citizen_merchant.glb", 1.78, ""], 
		["res://assets/characters/citizen_woman/citizen_woman.glb", 1.68, ""], 
		["res://assets/characters/blacksmith_npc/blacksmith_npc.glb", 1.75, ""], 
		["res://assets/characters/oracle_priestess/oracle_priestess.glb", 1.68, ""], 
	]
	var x: = -5.0
	for entry in cast:
		var n: Node3D = load(String(entry[0])).instantiate()
		stage.add_child(n)
		ModelUtils.setup_character_for_movement(n, float(entry[1]))
		n.position = Vector3(x, 0.0, 0.0)
		assert (n.find_child("LegPlantFix", true, false) == null)
		var clip: = String(entry[2])
		if clip != "":
			var a: = n.find_child("AnimationPlayer", true) as AnimationPlayer
			assert (a != null and a.has_animation(clip))
			a.play(clip)
		print("npc ", n.name, " plant=false clip=", clip)
		x += 2.0
	for i in 18:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLENIC_cast.png")
	print("HELLENIC_CAST_OK")
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
	e.background_color = Color(0.55, 0.62, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.68, 0.62)
	e.ambient_light_energy = 0.75
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 35, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(20, 14)
	floor_mi.mesh = plane
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.64, 0.5)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
