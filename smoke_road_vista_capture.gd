extends SceneTree
## Capture Hellenic road + olive vista between Athens and Sparta.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var gs = root.get_node_or_null("GameState")
	gs.empire = "athens"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	gs.tutorial_step = 99
	change_scene_to_file("res://scenes/game_world.tscn")
	for _i in 300:
		await process_frame

	var world: Node = get_first_node_in_group("game_world")
	if world == null:
		print("FAIL no world")
		quit(1)
		return
	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	if player == null:
		print("FAIL no player")
		quit(1)
		return

	## On the Sacred Way bend toward Sparta.
	var px: = -90.0
	var pz: = 70.0
	player.global_position = Vector3(px, world.sample_height(px, pz) + 1.6, pz)
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	if "hp" in player and "max_hp" in player:
		player.hp = player.max_hp
	## Look southwest along the road toward Sparta / Centaur March.
	var yaw: = atan2(160.0, -100.0) ## toward (-250, 170) roughly
	player.cam_pitch = -0.2
	player.cam_yaw = yaw
	if player.mesh_root:
		player.mesh_root.rotation.y = yaw
	if player.camera_pivot:
		player.camera_pivot.rotation.y = player.cam_yaw
		player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true
	if player.spring_arm:
		player.spring_arm.spring_length = 12.0
		player.spring_arm.position.y = 0.7
	for _j in 55:
		await process_frame
	var path: = "/opt/cursor/artifacts/hellas_road_olives.png"
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SHOT road -> ", path)
	print("CAPTURE_ROAD_VISTA_OK")
	quit(0)
