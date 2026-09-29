extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	await process_frame
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("NO_GAMESTATE")
		quit(1)
		return
	gs.empire = "sparta"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	change_scene_to_file("res://scenes/game_world.tscn")
	for i in 150:
		await process_frame
	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	if player == null:
		print("NO_PLAYER")
		quit(1)
		return

	player.cam_pitch = player.CAM_PITCH_DEFAULT
	player.cam_yaw = 0.0
	player.camera_pivot.rotation.y = 0.0
	player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true
	for i in 20:
		await process_frame

	print(
		"DIST=", player.spring_arm.spring_length, 
		" PITCH=", rad_to_deg(player.cam_pitch), 
		" CAM_Y=", player.camera.global_position.y, 
		" PIVOT_Y=", player.camera_pivot.global_position.y
	)
	var img = root.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/FIXED_cam_default.png")
	print("SAVED FIXED_cam_default.png")


	player.cam_yaw = deg_to_rad(40.0)
	player.camera_pivot.rotation.y = player.cam_yaw
	for i in 12:
		await process_frame
	img = root.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/FIXED_cam_orbit.png")
	print("SAVED FIXED_cam_orbit.png")
	print("CAPTURE_FIXED_CAM_OK")
	quit(0)
