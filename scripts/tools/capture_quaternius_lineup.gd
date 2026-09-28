extends SceneTree
## Visual proof: Quaternius hero + plaza NPCs idle / walk / slash / block with gear.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var vp := _stage(1600, 720)
	var stage: Node3D = vp.get_child(0)

	var entries := [
		["hero", "res://assets/characters/quaternius_hero_king/hero_king.glb", 1.85, true],
		["oracle", "res://assets/characters/quaternius_oracle_witch/oracle_witch.glb", 1.72, false],
		["smith", "res://assets/characters/quaternius_smith_worker/smith_worker.glb", 1.8, false],
		["merchant", "res://assets/characters/quaternius_merchant_farmer/merchant_farmer.glb", 1.78, false],
		["woman", "res://assets/characters/quaternius_woman_medieval/woman_medieval.glb", 1.68, false],
		["guard", "res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb", 1.84, true],
	]
	var models: Array = []
	var anims: Array = []
	var x := -7.5
	for entry in entries:
		var m: Node3D = load(String(entry[1])).instantiate()
		stage.add_child(m)
		m.position = Vector3(x, 0.0, 0.0)
		ModelUtils.setup_character_for_movement(m, float(entry[2]))
		var anim := m.find_child("AnimationPlayer", true) as AnimationPlayer
		if anim:
			ModelUtils.set_animation_loops(anim)
			if anim.has_animation("Idle"):
				anim.play("Idle")
		if bool(entry[3]):
			var GearGrip = load("res://scripts/gear_grip.gd")
			GearGrip.attach_weapon(m, "res://assets/props/weapons/dory_spear.glb")
			GearGrip.attach_shield(m, "res://assets/props/gear/aspis_shield.glb")
		models.append(m)
		anims.append(anim)
		x += 3.0
		print("spawned ", entry[0], " name=", m.name, " y=", snapped(m.global_position.y, 0.01),
			" plant=", m.find_child("LegPlantFix", true, false) != null)

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 42
	cam.position = Vector3(0.0, 1.55, 10.5)
	cam.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)

	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_idle_lineup.png")
	print("saved QUAT_idle_lineup.png")

	## Close-up hero walk / slash / block
	var hero: Node3D = models[0]
	var hero_anim: AnimationPlayer = anims[0]
	var skel: Skeleton3D = null
	for n in hero.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break
	cam.position = Vector3(-5.2, 1.45, 4.6)
	cam.look_at(Vector3(-7.5, 0.95, 0.0), Vector3.UP)

	if hero_anim and hero_anim.has_animation("Walk"):
		hero_anim.play("Walk")
	var zmin := 999.0
	var zmax := -999.0
	var ymin := 999.0
	for i in 36:
		await process_frame
		if skel != null and skel.find_bone("Foot.L") >= 0:
			var lf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Foot.L"))).origin
			zmin = minf(zmin, lf.z)
			zmax = maxf(zmax, lf.z)
			ymin = minf(ymin, lf.y)
		if i == 18:
			vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_walk.png")
	print("WALK z_range=", snapped(zmax - zmin, 0.01), " foot_ymin=", snapped(ymin, 0.01))

	if hero_anim and hero_anim.has_animation("Sword_Slash"):
		hero_anim.play("Sword_Slash")
	for i in 16:
		await process_frame
		if i == 8:
			vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_slash.png")

	if hero_anim and hero_anim.has_animation("Idle_Sword"):
		hero_anim.play("Idle_Sword")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_block.png")

	## Side view — head should not sky-gaze
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	cam.position = Vector3(-10.2, 1.15, 0.05)
	cam.look_at(Vector3(-7.5, 1.0, 0.0), Vector3.UP)
	if hero_anim and hero_anim.has_animation("Idle"):
		hero_anim.play("Idle")
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_side.png")

	var ok := (zmax - zmin) > 0.08 and ymin < 0.35
	print("QUATERNIUS_LINEUP_OK=", ok, " walk_span=", snapped(zmax - zmin, 0.01))
	vp.queue_free()
	quit(0 if ok else 1)


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
	e.background_color = Color(0.52, 0.58, 0.64)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.66)
	e.ambient_light_energy = 0.6
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.2
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(28, 14)
	floor_mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.37, 0.32)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
