extends SceneTree

func _init(): call_deferred("run")

func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var WeaponGrip = load("res://scripts/weapon_grip.gd")

	var spear_rots: = [
		Vector3(0, 0, -90), 
		Vector3(-90, 0, -90), 
		Vector3(-90, -90, 0), 
		Vector3(0, -90, -90), 
		Vector3(90, 0, -90), 
		Vector3(-90, 90, 0), 
		Vector3(0, 180, -90), 
		Vector3(-90, 0, 90), 
		Vector3(0, 0, 90), 
		Vector3(-70, 0, -90), 
		Vector3(-90, -45, 0), 
		Vector3(0, -90, 0), 
	]
	var shield_rots: = [
		Vector3(-90, 0, 90), 
		Vector3(0, 0, 0), 
		Vector3(-90, 90, 0), 
		Vector3(0, 90, 90), 
		Vector3(90, 0, 0), 
		Vector3(-90, 0, 0), 
		Vector3(0, 180, 0), 
		Vector3(0, 0, 90), 
		Vector3(-90, -90, 90), 
		Vector3(0, -90, 90), 
	]

	for i in spear_rots.size():
		await _shot("spear", i, spear_rots[i], GreekLook, WeaponGrip)
	for i in shield_rots.size():
		await _shot("shield", i, shield_rots[i], GreekLook, WeaponGrip)
	print("GRIP_SWEEP_OK")
	quit()

func _shot(kind: String, idx: int, rot: Vector3, GreekLook, WeaponGrip) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(700, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.58, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")

	var grip: = {
		"bone": "Wrist.R" if kind == "spear" else "Wrist.L", 
		"position": Vector3(0.0, 0.05, 0.0) if kind == "spear" else Vector3(0.0, 0.04, 0.08), 
		"rotation_deg": rot, 
		"scale": 1.05 if kind == "spear" else 1.0, 
	}
	var path: = "res://assets/props/weapons/dory_spear.glb" if kind == "spear"\
	else "res://assets/props/gear/aspis_shield.glb"
	var wclass: = "melee" if kind == "spear" else "shield"
	WeaponGrip.attach(hero, path, wclass, grip)

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30

	cam.position = Vector3(1.1, 1.35, -2.8)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 18: await process_frame
	var out: = "/opt/cursor/artifacts/GRIP_%s_%02d_%d_%d_%d.png" % [
		kind, idx, int(rot.x), int(rot.y), int(rot.z)]
	vp.get_texture().get_image().save_png(out)
	print("saved ", out)
	vp.queue_free()
	await process_frame
