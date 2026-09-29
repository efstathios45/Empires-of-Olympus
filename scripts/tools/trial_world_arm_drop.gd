extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var meshes: = [
		["hoplite", "res://assets/characters/spartan_hoplite/spartan_hoplite.glb", 1.85], 
		["woman", "res://assets/characters/citizen_woman/citizen_woman.glb", 1.68], 
		["smith", "res://assets/characters/blacksmith_npc/blacksmith_npc.glb", 1.8], 
		["merchant", "res://assets/characters/citizen_merchant/citizen_merchant.glb", 1.78], 
		["guard", "res://assets/characters/city_guard/city_guard.glb", 1.84], 
		["priestess", "res://assets/characters/oracle_priestess/oracle_priestess.glb", 1.75], 
	]
	for bone_axis in ["y", "x", "-y", "-x", "z", "-z"]:
		print("AXIS=", bone_axis)
		for m in meshes:
			await _one(String(m[0]), String(m[1]), float(m[2]), bone_axis)
	print("WORLD_ARM_OK")
	quit(0)


func _one(tag: String, glb: String, height: float, bone_axis: String) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(400, 520)
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
	pm.size = Vector2(8, 8)
	floor.mesh = pm
	var fm: = StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)

	var model: Node3D = load(glb).instantiate()
	stage.add_child(model)
	ModelUtils.scale_to_height(model, height)
	ModelUtils.ground_model(model)
	var skel: Skeleton3D
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	skel.reset_bone_poses()
	_aim_arm_down(skel, "LeftUpperArm", bone_axis)
	_aim_arm_down(skel, "RightUpperArm", bone_axis)

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.0, 1.55, -2.6)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 6:
		await process_frame
	var path: = "/opt/cursor/artifacts/WARM_%s_%s_front.png" % [bone_axis.replace("-", "n"), tag]
	vp.get_texture().get_image().save_png(path)


	var lh: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftHand"))).origin
	var rh: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("RightHand"))).origin
	var la: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftUpperArm"))).origin
	var drop: = ((la.y - lh.y) + (la.y - rh.y)) * 0.5
	var span: = absf(lh.x - rh.x)
	print("  ", tag, " drop=", snapped(drop, 0.01), " span=", snapped(span, 0.01), " -> ", path)
	vp.queue_free()
	await process_frame


func _aim_arm_down(skel: Skeleton3D, bone_name: String, axis_name: String) -> void :
	var bi: = skel.find_bone(bone_name)
	if bi < 0:
		return
	skel.set_bone_pose_rotation(bi, skel.get_bone_rest(bi).basis.get_rotation_quaternion())
	skel.set_bone_pose_position(bi, skel.get_bone_rest(bi).origin)

	var g: Transform3D = skel.global_transform * skel.get_bone_global_pose(bi)
	var along: Vector3
	match axis_name:
		"y": along = g.basis.y
		"x": along = g.basis.x
		"z": along = g.basis.z
		"-y": along = - g.basis.y
		"-x": along = - g.basis.x
		"-z": along = - g.basis.z
		_: along = g.basis.y
	along = along.normalized()
	var target: = Vector3.DOWN
	if along.length_squared() < 0.0001 or along.dot(target) > 0.999:
		return
	var q_delta: = Quaternion(along, target)


	var parent_i: = skel.get_bone_parent(bi)
	var parent_g: Transform3D
	if parent_i >= 0:
		parent_g = skel.global_transform * skel.get_bone_global_pose(parent_i)
	else:
		parent_g = skel.global_transform
	var new_g_basis: Basis = Basis(q_delta) * g.basis
	var local_basis: Basis = parent_g.basis.inverse() * new_g_basis
	skel.set_bone_pose_rotation(bi, local_basis.get_rotation_quaternion())
