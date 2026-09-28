extends SceneTree
## Side-view capture of player idle WITH sky-gaze fix (needs GPU / xvfb, not --headless).

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var root := get_root()
	var vp := SubViewport.new()
	vp.size = Vector2i(480, 640)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.52, 0.62)
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.3, 0.35, 0.25)
	floor.material_override = fm
	stage.add_child(floor)

	var body := CharacterBody3D.new()
	body.set_script(load("res://scripts/player.gd"))
	stage.add_child(body)
	body.set_physics_process(false)
	for i in 30:
		await process_frame
	body.set_physics_process(false)
	body.global_position = Vector3.ZERO
	if body.anim:
		body.anim.play("ual1_Idle")
	for i in 20:
		await process_frame

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	stage.add_child(cam)
	cam.current = true
	cam.position = Vector3(3.2, 1.15, 0)
	cam.look_at(Vector3(0, 1, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/gaze_idle_fixed_side.png")
	print("SAVED gaze_idle_fixed_side.png")

	# Metrics
	var skel: Skeleton3D
	for n in body.mesh_root.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	if skel:
		var hi := skel.find_bone("Head")
		var ht := skel.global_transform * skel.get_bone_global_pose(hi)
		var fwd := (-ht.basis.z).normalized()
		print("FIX_FWD_UP=", fwd.dot(Vector3.UP), " HEAD_EX=", rad_to_deg(ht.basis.get_euler().x))
		print("HAS_GAZE_FIX=", skel.has_node("SkyGazeFix"))

	# Also walk
	if body.anim:
		body.anim.play("ual1_Walk")
	for i in 20:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/gaze_walk_fixed_side.png")
	print("SAVED gaze_walk_fixed_side.png")
	if skel:
		var hi2 := skel.find_bone("Head")
		var ht2 := skel.global_transform * skel.get_bone_global_pose(hi2)
		var fwd2 := (-ht2.basis.z).normalized()
		print("WALK_FWD_UP=", fwd2.dot(Vector3.UP))

	print("CAPTURE_GAZE_FIXED_OK")
	quit(0)
