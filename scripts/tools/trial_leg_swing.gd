extends SceneTree
func _init(): call_deferred("run")
func run():
	var axes = [["x", Vector3(1, 0, 0)], ["y", Vector3(0, 1, 0)], ["z", Vector3(0, 0, 1)], 
		["nx", Vector3(-1, 0, 0)], ["ny", Vector3(0, -1, 0)], ["nz", Vector3(0, 0, -1)]]
	for a in axes:
		await _one(String(a[0]), a[1])
	print("LEG_SWING_TRIAL_OK")
	quit(0)
func _one(tag, axis):
	var vp = SubViewport.new()
	vp.size = Vector2i(320, 480)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage = Node3D.new();vp.add_child(stage)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR;e.background_color = Color(0.55, 0.6, 0.66)
	env.environment = e;stage.add_child(env)
	var light = DirectionalLight3D.new();light.rotation_degrees = Vector3(-45, 35, 0);light.light_energy = 1.4;stage.add_child(light)
	var floor = MeshInstance3D.new(); var pm = PlaneMesh.new();pm.size = Vector2(8, 8);floor.mesh = pm
	var fm = StandardMaterial3D.new();fm.albedo_color = Color(0.25, 0.4, 0.22);floor.material_override = fm;stage.add_child(floor)
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.scale_to_height(m, 1.85);ModelUtils.ground_model(m)
	var skel
	for n in m.find_children("*", "Skeleton3D", true, false): skel = n;break
	skel.reset_bone_poses()

	var bi = skel.find_bone("LeftUpperLeg")
	var q = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
	skel.set_bone_pose_rotation(bi, q * Quaternion(axis.normalized(), 0.9))
	var cam = Camera3D.new();stage.add_child(cam);cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL;cam.size = 2.4
	cam.position = Vector3(3.5, 1.05, 0);cam.look_at(Vector3(0, 1, 0), Vector3.UP)
	for i in 6: await process_frame
	var lf = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
	var hips = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Hips"))).origin
	var fwd = lf.z - hips.z
	print(tag, " foot=", lf, " dZ=", snapped(lf.z, 0.01), " dY=", snapped(lf.y, 0.01))
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/LSWING_%s.png" % tag)
	vp.queue_free(); await process_frame
