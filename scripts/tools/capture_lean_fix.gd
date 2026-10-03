extends SceneTree
func _init(): call_deferred("r")
func r():
	var root = get_root()
	var vp: = SubViewport.new()
	vp.size = Vector2i(480, 640)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new();vp.add_child(stage)
	var light: = DirectionalLight3D.new();light.rotation_degrees = Vector3(-45, 30, 0);light.light_energy = 1.4;stage.add_child(light)
	var floor: = MeshInstance3D.new(); var pm: = PlaneMesh.new();pm.size = Vector2(10, 10);floor.mesh = pm
	var fm: = StandardMaterial3D.new();fm.albedo_color = Color(0.3, 0.35, 0.25);floor.material_override = fm;stage.add_child(floor)
	var body: = CharacterBody3D.new();body.set_script(load("res://scripts/player.gd"));stage.add_child(body)
	body.set_physics_process(false)
	for i in 25: await process_frame
	body.set_physics_process(false);body.global_position = Vector3.ZERO
	if body.anim: body.anim.play("ual1_Idle")
	for i in 15: await process_frame
	var cam: = Camera3D.new();cam.projection = Camera3D.PROJECTION_ORTHOGONAL;cam.size = 2.5;stage.add_child(cam);cam.current = true
	cam.position = Vector3(3.2, 1.15, 0);cam.look_at(Vector3(0, 1, 0), Vector3.UP)
	for deg in [0, 20, -20, 35, -35]:
		if body.mesh_root:
			body.mesh_root.rotation.x = deg_to_rad(float(deg))
		for i in 5: await process_frame
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		var img = vp.get_texture().get_image()
		var path = "/opt/cursor/artifacts/lean_meshroot_x%d.png" % deg
		img.save_png(path)
		print("SAVED ", path)

	var model = body.mesh_root.get_child(0) as Node3D
	body.mesh_root.rotation.x = 0
	for deg in [0, 25, -25]:
		model.rotation.x = deg_to_rad(float(deg))

		model.rotation.y = - PI
		for i in 5: await process_frame
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/lean_model_x%d.png" % deg)
		print("SAVED model x", deg)
	print("LEANFIX_CAPTURE_OK")
	quit(0)
