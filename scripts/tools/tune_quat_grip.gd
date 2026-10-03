extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var vp: = _stage(720, 900)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim: = m.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	var skel: Skeleton3D = null
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n as Skeleton3D
		break

	for clip in ["", "Idle", "Idle_Neutral", "Idle_Sword", "Walk"]:
		if clip != "":
			anim.play(clip)
			for i in 8:
				await process_frame
		else:
			anim.stop()
			skel.reset_bone_poses()
			for i in 4:
				await process_frame
		var hi: = skel.find_bone("Head")
		var pose: = skel.get_bone_global_pose(hi)
		var e: = pose.basis.get_euler()
		var world_fwd: Vector3 = (skel.global_transform * pose).basis * Vector3(0, 0, -1)
		print("HEAD clip=", clip if clip != "" else "REST", 
			" euler_deg=", Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)), 
			" world_fwd=", world_fwd)


	for bn in ["Wrist.R", "LowerArm.L", "Wrist.L"]:
		var bi: = skel.find_bone(bn)
		var gp: = skel.global_transform * skel.get_bone_global_pose(bi)
		print("BONE ", bn, " origin=", gp.origin, 
			" X=", gp.basis.x, " Y=", gp.basis.y, " Z=", gp.basis.z)

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36
	cam.position = Vector3(2.6, 1.35, 3.2)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)

	anim.play("Idle_Sword")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var WeaponGrip = load("res://scripts/weapon_grip.gd")


	var trials: = [
		[Vector3(0.05, 0.1, 0.0), Vector3(0, 90, 90)], 
		[Vector3(0.05, 0.1, 0.0), Vector3(90, 0, 90)], 
		[Vector3(0.05, 0.1, 0.0), Vector3(0, 0, 90)], 
		[Vector3(0.02, 0.08, 0.04), Vector3(-90, 90, 0)], 
		[Vector3(0.02, 0.08, 0.04), Vector3(0, 180, 90)], 
		[Vector3(0.04, 0.12, 0.02), Vector3(8, 95, 90)], 
		[Vector3(0.0, 0.15, 0.0), Vector3(90, 90, 0)], 
		[Vector3(0.0, 0.12, 0.05), Vector3(-20, 90, 80)], 
		[Vector3(0.06, 0.0, 0.0), Vector3(0, 90, 0)], 
		[Vector3(0.0, 0.1, 0.0), Vector3(180, 0, 90)], 
	]
	var idx: = 0
	for t in trials:

		for child in skel.get_children():
			if String(child.name).begins_with("WeaponMount") or String(child.name).begins_with("Shield"):
				child.queue_free()
		await process_frame
		var grip: = {
			"bone": "LowerArm.L", 
			"position": t[0], 
			"rotation_deg": t[1], 
			"scale": 1.05, 
		}
		WeaponGrip.attach(m, "res://assets/props/gear/aspis_shield.glb", "shield", grip)

		GearGrip.attach_weapon(m, "res://assets/props/weapons/dory_spear.glb")
		for i in 6:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_grip_%02d.png" % idx)
		print("grip_", idx, " pos=", t[0], " rot=", t[1])
		idx += 1


	for child in skel.get_children():
		if String(child.name).begins_with("WeaponMount"):
			child.queue_free()
	await process_frame
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	cam.position = Vector3(3.4, 1.1, 0.05)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for clip in ["Idle", "Idle_Neutral", "Idle_Sword", "Walk"]:
		anim.play(clip)
		for i in 10:
			await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/QUAT_head_%s.png" % clip)
		print("saved head ", clip)

	print("TUNE_DONE")
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
	e.background_color = Color(0.55, 0.6, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65, 0.66, 0.7)
	e.ambient_light_energy = 0.65
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 35, 0)
	light.light_energy = 1.2
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.38, 0.33)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
