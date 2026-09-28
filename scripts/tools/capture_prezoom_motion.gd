extends SceneTree
## Proof: raw UAL walk/idle (no LegPlant) on Ancient Greek Tripo cast.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var GearGrip = load("res://scripts/gear_grip.gd")
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")
	var vp := _stage(1200, 900)
	var stage: Node3D = vp.get_child(0)

	var hero: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var plant := hero.find_child("LegPlantFix", true, false)
	print("hero plant=", plant != null, " (expected true — Tripo needs plant)")
	var anim := hero.find_child("AnimationPlayer", true) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		hero.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if lib:
		if anim.has_animation_library(""):
			anim.remove_animation_library("")
		anim.add_animation_library("", lib)
	ModelUtils.set_animation_loops(anim)
	ModelUtils.bind_leg_plant_anim(hero, anim)
	plant = hero.find_child("LegPlantFix", true, false)
	print("hero plant_after_bind=", plant != null)

	GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36
	cam.position = Vector3(2.3, 1.45, -3.1)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)

	HeroAnim.play(anim, "idle")
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PREZOOM_hero_idle.png")

	HeroAnim.play(anim, "walk")
	## Sample mid-walk so legs are clearly mid-stride.
	if anim.current_animation != "":
		anim.seek(0.35, true)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PREZOOM_hero_walk.png")

	HeroAnim.play(anim, "attack_1")
	if anim.current_animation != "":
		anim.seek(0.25, true)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PREZOOM_hero_slash.png")

	## Side walk strip — prove legs swing (not planted A-pose).
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	cam.position = Vector3(3.8, 1.1, 0.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	HeroAnim.play(anim, "walk")
	for frame_i in 6:
		anim.seek(0.08 + float(frame_i) * 0.12, true)
		for i in 4:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PREZOOM_walk_%d.png" % frame_i)

	vp.queue_free()
	await process_frame
	vp = _stage(1600, 720)
	stage = vp.get_child(0)
	cam = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36
	cam.position = Vector3(0, 1.7, -14.0)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	var entries := [
		["res://assets/characters/oracle_priestess/oracle_priestess.glb",
			"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres", 1.72],
		["res://assets/characters/blacksmith_npc/blacksmith_npc.glb",
			"res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres", 1.8],
		["res://assets/characters/citizen_merchant/citizen_merchant.glb",
			"res://assets/characters/citizen_merchant/citizen_merchant_animations.tres", 1.78],
		["res://assets/characters/citizen_woman/citizen_woman.glb",
			"res://assets/characters/citizen_woman/citizen_woman_animations.tres", 1.68],
		["res://assets/characters/city_guard/city_guard.glb",
			"res://assets/characters/city_guard/city_guard_animations.tres", 1.84],
		["res://assets/characters/spartan_hoplite/spartan_hoplite.glb",
			"res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres", 1.85],
	]
	var x := -8.5
	for e in entries:
		var n: Node3D = load(String(e[0])).instantiate()
		stage.add_child(n)
		n.position = Vector3(x, 0, 0)
		ModelUtils.setup_character_for_movement(n, float(e[2]))
		var a := n.find_child("AnimationPlayer", true) as AnimationPlayer
		if a == null:
			a = AnimationPlayer.new()
			n.add_child(a)
		if ResourceLoader.exists(String(e[1])):
			var l2 := load(String(e[1])) as AnimationLibrary
			if l2:
				a.add_animation_library("", l2)
		ModelUtils.bind_leg_plant_anim(n, a)
		var p2 := n.find_child("LegPlantFix", true, false)
		if a.has_animation("ual1_Idle"):
			a.play("ual1_Idle")
		print("npc ", n.name, " plant=", p2 != null)
		x += 3.2
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PREZOOM_cast.png")
	print("PREZOOM_MOTION_OK")
	quit()


func _stage(w: int, h: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.72, 0.65)
	e.ambient_light_energy = 0.85
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 28, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 14)
	floor_mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.4, 0.32)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
