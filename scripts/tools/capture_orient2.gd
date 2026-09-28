extends SceneTree
## Capture hero with idle anim + game-like third-person camera.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := get_root()
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 540)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.55, 0.65)
	env.environment = e
	stage.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.light_energy = 1.5
	light.shadow_enabled = false
	stage.add_child(light)

	# Floor
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mi.mesh = plane
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.35, 0.4, 0.28)
	floor_mi.material_override = fmat
	stage.add_child(floor_mi)

	var body := CharacterBody3D.new()
	body.set_script(load("res://scripts/player.gd"))
	stage.add_child(body)
	body.global_position = Vector3(0, 0, 0)
	body.set_physics_process(false)
	body.velocity = Vector3.ZERO
	# Wait for player _ready / deferred
	for i in 30:
		await process_frame
	body.global_position = Vector3(0, 0, 0)
	body.set_physics_process(false)

	# Force idle
	if body.anim and body.anim.has_animation("ual1_Idle"):
		body.anim.play("ual1_Idle")
	for i in 20:
		await process_frame

	print("PLAYER_MESH_ROT=", body.mesh_root.rotation if body.mesh_root else null)
	if body.mesh_root and body.mesh_root.get_child_count() > 0:
		var model: Node3D = body.mesh_root.get_child(0)
		print("MODEL_ROT=", model.rotation, " SCALE=", model.scale)
	print("CAM_PITCH=", body.cam_pitch, " DIST=", body.spring_arm.spring_length if body.spring_arm else null)
	print("SPRING_LEN=", body.spring_arm.spring_length if body.spring_arm else null)
	print("SPRING_MASK=", body.spring_arm.collision_mask if body.spring_arm else null)

	# Use the player's own camera to capture what the game shows
	if body.camera:
		body.camera.current = true
		# Make SubViewport use a copy? Player camera is in the main tree under stage->body
		# Actually SubViewport has its own world - player's camera is inside vp via stage.
		pass

	# Reposition orbit to a clear side-behind view on the spring arm
	body.cam_yaw = deg_to_rad(40.0)
	body.cam_pitch = -0.28
	if body.spring_arm:
		body.spring_arm.spring_length = body.CAM_DISTANCE
	body.camera_pivot.rotation.y = body.cam_yaw
	body.camera_pivot.rotation.x = body.cam_pitch
	for i in 15:
		await process_frame

	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	var img: Image = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/orient_gamecam.png")

	# Extra: orthographic side of the live animated player mesh
	var cam2 := Camera3D.new()
	cam2.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam2.size = 2.4
	stage.add_child(cam2)
	cam2.current = true
	cam2.position = Vector3(3.5, 1.2, 0)
	cam2.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	img = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/orient_idle_side.png")

	# Measure head bone up vector
	var skel: Skeleton3D = null
	for n in body.mesh_root.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	if skel:
		var hi := skel.find_bone("Head")
		var ht := skel.global_transform * skel.get_bone_global_pose(hi)
		print("HEAD_ORIGIN=", ht.origin)
		print("HEAD_Y_AXIS(world)=", ht.basis.y)  # should point roughly +Y if upright
		print("HEAD_Z_AXIS(world)=", ht.basis.z)
		var hips := skel.find_bone("Hips")
		var hp := skel.global_transform * skel.get_bone_global_pose(hips)
		print("HIPS_ORIGIN=", hp.origin)
		print("HIPS_Y_AXIS=", hp.basis.y)

	print("CAPTURE2_OK")
	quit(0)
