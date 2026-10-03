extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var vp: = _stage(560, 720)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	assert (m.find_child("LegPlantFix", true, false) != null, "hoplite needs LegPlantFix")
	assert (m.find_child("KaykitFootGround", true, false) == null, "hoplite must not use KayKit grounder")
	var skel: Skeleton3D = null
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	assert (skel != null, "no skeleton")
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	ModelUtils.set_animation_loops(anim)
	ModelUtils.bind_leg_plant_anim(m, anim)
	var GearGrip = load("res://scripts/gear_grip.gd")
	var sword = GearGrip.attach_weapon(m, "res://assets/props/weapons/dory_spear.glb")
	var shield = GearGrip.attach_shield(m, "res://assets/props/gear/aspis_shield.glb")
	print("name=", m.name, " spear=", sword != null, " aspis=", shield != null)

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	cam.position = Vector3(3.5, 1.1, 0.1)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	anim.play("ual1_Idle")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOPLITE_idle.png")

	anim.play("ual1_Walk")
	var zmin: = 999.0
	var zmax: = -999.0
	var ymin: = 999.0
	for i in 40:
		await process_frame
		var lf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
		zmin = minf(zmin, lf.z)
		zmax = maxf(zmax, lf.z)
		ymin = minf(ymin, lf.y)
		if i % 10 == 0:
			vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOPLITE_walk_%d.png" % int(i / 10))
	print("WALK z_range=", snapped(zmax - zmin, 0.01), " foot_ymin=", snapped(ymin, 0.01))

	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.1, 1.5, -2.5)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	anim.play("ual1_Sword_Attack")
	for i in 14:
		await process_frame
		if i % 7 == 0:
			vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOPLITE_attack_%d.png" % int(i / 7))

	anim.play("ual2_Sword_Block")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOPLITE_block.png")

	var ok: = (zmax - zmin) > 0.1 and ymin < 0.25 and sword != null and shield != null
	print("HOPLITE_RESTORE_DONE OK=", ok)
	vp.queue_free()
	quit(0 if ok else 1)


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
	e.background_color = Color(0.55, 0.6, 0.66)
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)
	return vp
