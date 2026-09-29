extends SceneTree

func _init(): call_deferred("run")

func run():
	var vp: = SubViewport.new()
	vp.size = Vector2i(1000, 1200)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.52, 0.6)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
	e.ambient_light_energy = 1.05
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.4
	stage.add_child(light)

	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.strip_arm_animation_tracks(anim)
	anim.play("Idle_Neutral")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	for i in 20:
		await process_frame

	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var wr_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
	var wl_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.L"))
	var lar_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LowerArm.R"))
	var lal_g: = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LowerArm.L"))


	var mi: MeshInstance3D = null
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		mi = n as MeshInstance3D
		if mi and mi.mesh:
			break
	var aabb: AABB = mi.global_transform * mi.get_aabb()
	print("mesh global aabb pos=", aabb.position, " size=", aabb.size, " end=", aabb.end)


	_sphere(stage, wr_g.origin, Color(1, 0, 0), 0.04)
	_sphere(stage, wl_g.origin, Color(1, 0.2, 0.2), 0.04)
	_sphere(stage, lar_g.origin, Color(1, 0.5, 0), 0.035)
	_sphere(stage, lal_g.origin, Color(1, 0.55, 0), 0.035)


	var grip_local: = Vector3(-0.05, -0.05, 0.24)
	var grip_w: = wr_g * grip_local
	_sphere(stage, grip_w, Color(0, 1, 0), 0.045)
	print("grip_w=", grip_w)


	var grip2: = wr_g * Vector3(-0.08, -0.02, 0.34)
	_sphere(stage, grip2, Color(0, 1, 1), 0.045)
	print("grip2=", grip2)


	var grip3: = wr_g * Vector3(-0.1, 0.0, 0.42)
	_sphere(stage, grip3, Color(0.2, 0.4, 1), 0.045)
	print("grip3=", grip3)



	var maxx: = -999.0
	var maxxv: = Vector3.ZERO
	for si in mi.mesh.get_surface_count():
		var arr: = mi.mesh.surface_get_arrays(si)
		for v in arr[Mesh.ARRAY_VERTEX]:
			var g: Vector3 = mi.global_transform * v
			if g.x > maxx:
				maxx = g.x
				maxxv = g
	_sphere(stage, maxxv, Color(1, 0, 1), 0.05)
	print("raw_outer_R=", maxxv)


	var right_tip: = Vector3(aabb.end.x, wr_g.origin.y, (aabb.position.z + aabb.end.z) * 0.5)

	right_tip = Vector3(aabb.end.x - 0.02, clampf(wr_g.origin.y, aabb.position.y, aabb.end.y), aabb.position.z + aabb.size.z * 0.45)
	_sphere(stage, right_tip, Color(1, 1, 0), 0.05)
	print("aabb_right_tip=", right_tip)

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 28
	cam.position = Vector3(1.2, 1.35, -3.0)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 24:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/MARKERS_face.png")

	cam.position = Vector3(wr_g.origin.x + 1.0, wr_g.origin.y + 0.2, wr_g.origin.z - 1.2)
	cam.look_at(wr_g.origin + Vector3(0.2, 0, 0), Vector3.UP)
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/MARKERS_hand.png")

	cam.position = Vector3(3.2, 1.3, 0.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/MARKERS_side.png")

	print("MARKERS_OK")
	quit()


func _sphere(parent: Node3D, pos: Vector3, col: Color, r: float) -> void :
	var mi: = MeshInstance3D.new()
	var s: = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos
