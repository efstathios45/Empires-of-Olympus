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
	for m in meshes:
		await _trial_mesh(String(m[0]), String(m[1]), float(m[2]))
	print("STAND_TRIAL_OK")
	quit(0)


func _trial_mesh(tag: String, glb: String, height: float) -> void :
	print("=== ", tag, " ===")
	var model: Node3D = load(glb).instantiate()
	root.add_child(model)
	ModelUtils.scale_to_height(model, height)
	ModelUtils.ground_model(model)
	var skel: Skeleton3D
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert (skel != null)
	skel.reset_bone_poses()


	for bn in ["LeftUpperArm", "RightUpperArm", "Hips", "LeftHand", "RightHand"]:
		var bi: = skel.find_bone(bn)
		if bi < 0:
			continue
		var g: Transform3D = skel.global_transform * skel.get_bone_global_pose(bi)
		print("  REST ", bn, " pos=", g.origin, " basisX=", g.basis.x, " basisY=", g.basis.y, " basisZ=", g.basis.z)

	var best_score: = -1000000000.0
	var best_cfg: = {}

	var axes: = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
	var angs: = [0.7, 0.9, 1.1, 1.3, 1.5]
	var sign_patterns: = [[1.0, -1.0], [1.0, 1.0], [-1.0, 1.0], [-1.0, -1.0]]
	for axis in axes:
		for ang in angs:
			for signs in sign_patterns:
				skel.reset_bone_poses()
				_apply_drop(skel, "LeftUpperArm", axis, float(signs[0]) * ang)
				_apply_drop(skel, "RightUpperArm", axis, float(signs[1]) * ang)
				var score: = _score(skel)
				if score > best_score:
					best_score = score
					best_cfg = {
						"axis": axis, "ang": ang, "L": signs[0], "R": signs[1], "score": score
					}

	print("  BEST ", best_cfg)

	skel.reset_bone_poses()
	_apply_drop(skel, "LeftUpperArm", best_cfg.axis, float(best_cfg.L) * float(best_cfg.ang))
	_apply_drop(skel, "RightUpperArm", best_cfg.axis, float(best_cfg.R) * float(best_cfg.ang))
	await _capture(tag, model, skel)
	model.queue_free()
	await process_frame


func _apply_drop(skel: Skeleton3D, bone_name: String, axis: Vector3, ang: float) -> void :
	var bi: = skel.find_bone(bone_name)
	if bi < 0:
		return
	var rest_q: Quaternion = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
	skel.set_bone_pose_rotation(bi, rest_q * Quaternion(axis.normalized(), ang))


func _score(skel: Skeleton3D) -> float:
	var lh: Variant = _bone_pos(skel, "LeftHand")
	var rh: Variant = _bone_pos(skel, "RightHand")
	var la: Variant = _bone_pos(skel, "LeftUpperArm")
	var ra: Variant = _bone_pos(skel, "RightUpperArm")
	var head: Variant = _bone_pos(skel, "Head")
	var hips: Variant = _bone_pos(skel, "Hips")
	if lh == null or rh == null or la == null or ra == null or head == null or hips == null:
		return -1000000000.0
	var lhv: Vector3 = lh
	var rhv: Vector3 = rh
	var lav: Vector3 = la
	var rav: Vector3 = ra
	var headv: Vector3 = head
	var hipsv: Vector3 = hips
	var span: = absf(lhv.x - rhv.x) + absf(lhv.z - rhv.z)

	var hand_drop: float = ((lav.y - lhv.y) + (rav.y - rhv.y)) * 0.5

	var fwd: = absf(lhv.z - hipsv.z) + absf(rhv.z - hipsv.z)
	var upright: float = (headv - hipsv).normalized().dot(Vector3.UP)

	return upright * 5.0 + hand_drop * 8.0 - span * 3.0 - fwd * 2.0


func _bone_pos(skel: Skeleton3D, name: String) -> Variant:
	var bi: = skel.find_bone(name)
	if bi < 0:
		return null
	return (skel.global_transform * skel.get_bone_global_pose(bi)).origin


func _capture(tag: String, model: Node3D, skel: Skeleton3D) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(480, 640)
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

	var parent: = model.get_parent()
	parent.remove_child(model)
	stage.add_child(model)
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.35
	cam.position = Vector3(3.4, 1.05, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/STAND_%s_side.png" % tag)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.0, 1.55, -2.6)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/STAND_%s_front.png" % tag)
	print("  SAVED STAND_", tag)

	stage.remove_child(model)
	parent.add_child(model)
	vp.queue_free()
	await process_frame
