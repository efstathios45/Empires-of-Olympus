extends SceneTree
## Boot world, force min zoom + max look-up, capture player camera framing.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("NO_GAMESTATE")
		quit(1)
		return
	gs.empire = "sparta"
	gs.player_class = "hoplite"
	gs.player_name = "ZoomHero"
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

	player._apply_cam_zoom(0.1)  ## clamp to min
	player.cam_pitch = player._max_pitch_for_zoom(player._cam_zoom)
	player.cam_yaw = 0.0
	player.camera_pivot.rotation.y = player.cam_yaw
	player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true
	for i in 20:
		await process_frame

	var cam: Camera3D = player.camera
	var cam_y: float = cam.global_position.y
	var pivot_y: float = player.camera_pivot.global_position.y
	print(
		"ZOOM=", player._cam_zoom,
		" PITCH=", rad_to_deg(player.cam_pitch),
		" CAM_Y=", cam_y,
		" PIVOT_Y=", pivot_y,
		" SPRING_MASK=", player.spring_arm.collision_mask,
		" MARGIN=", player.spring_arm.margin
	)
	if cam_y < 0.9:
		push_error("camera still worm's-eye at min zoom: %s" % cam_y)
		quit(1)
		return

	var img = root.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/zoom_min_lookup.png")
	print("SAVED zoom_min_lookup.png")

	## Also capture a slightly pulled-back default framing for comparison.
	player._apply_cam_zoom(5.6)
	player.cam_pitch = -0.28
	player.camera_pivot.rotation.x = player.cam_pitch
	for i in 12:
		await process_frame
	img = root.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/zoom_default.png")
	print("SAVED zoom_default.png CAM_Y=", player.camera.global_position.y)
	print("CAPTURE_ZOOM_CAMERA_OK")
	quit(0)
