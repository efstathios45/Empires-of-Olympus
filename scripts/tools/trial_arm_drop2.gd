extends SceneTree
func _init(): call_deferred("run")
func run():
	var trials = [
		["same_x", Vector3(1, 0, 0), 1.2, false], 
		["same_z", Vector3(0, 0, 1), 1.2, false], 
		["opp_x", Vector3(1, 0, 0), 1.2, true], 
		["opp_z", Vector3(0, 0, 1), 1.2, true], 
		["same_x_n", Vector3(1, 0, 0), -1.2, false], 
		["same_z_n", Vector3(0, 0, 1), -1.2, false], 
		["mix_xz", Vector3(1, 0, 1).normalized(), 1.2, true], 
		["none", Vector3(1, 0, 0), 0.0, true], 
	]
	for t in trials:
		await _one(String(t[0]), t[1], float(t[2]), bool(t[3]))
	print("OK");quit(0)
func _one(tag, axis, ang, opposite):
	var vp: = SubViewport.new();vp.size = Vector2i(480, 600);vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS;vp.msaa_3d = Viewport.MSAA_4X;root.add_child(vp)
	var stage: = Node3D.new();vp.add_child(stage)
	var env: = WorldEnvironment.new(); var e: = Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color(0.55, 0.6, 0.66);env.environment = e;stage.add_child(env)
	var light: = DirectionalLight3D.new();light.rotation_degrees = Vector3(-45, 35, 0);light.light_energy = 1.4;stage.add_child(light)
	var floor: = MeshInstance3D.new(); var pm: = PlaneMesh.new();pm.size = Vector2(8, 8);floor.mesh = pm; var fm: = StandardMaterial3D.new();fm.albedo_color = Color(0.25, 0.4, 0.22);floor.material_override = fm;stage.add_child(floor)
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate();stage.add_child(m)
	ModelUtils.scale_to_height(m, 1.85);ModelUtils.ground_model(m)
	var skel: Skeleton3D;for n in m.find_children("*", "Skeleton3D", true, false): skel = n;break
	skel.reset_bone_poses()
	for pair in [["LeftUpperArm", 1.0], ["RightUpperArm", -1.0 if opposite else 1.0]]:
		var bi: = skel.find_bone(String(pair[0]))
		var rest_q: Quaternion = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
		var drop: = Quaternion(axis.normalized(), float(pair[1]) * ang)
		skel.set_bone_pose_rotation(bi, rest_q * drop)
	var cam: = Camera3D.new();stage.add_child(cam);cam.current = true;cam.projection = Camera3D.PROJECTION_ORTHOGONAL;cam.size = 2.35;cam.position = Vector3(3.4, 1.05, 0);cam.look_at(Vector3(0, 1, 0), Vector3.UP)
	for i in 8: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/ARM2_%s_side.png" % tag)
	print("SAVED ", tag)

	cam.projection = Camera3D.PROJECTION_PERSPECTIVE;cam.fov = 40;cam.position = Vector3(0, 1.4, -3.0);cam.look_at(Vector3(0, 1, 0), Vector3.UP)
	for i in 6: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/ARM2_%s_front.png" % tag)
	vp.queue_free(); await process_frame
