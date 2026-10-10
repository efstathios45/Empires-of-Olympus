extends SceneTree
## Capture a road caravan on the Sacred Way.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.empire = "athens"
		gs.player_class = "hoplite"
		gs.player_name = "Hero"
		gs.tutorial_step = 99
	change_scene_to_file("res://scenes/game_world.tscn")
	for _i in 280:
		await process_frame

	var world: Node = get_first_node_in_group("game_world")
	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	if world == null or player == null:
		print("FAIL no world/player")
		quit(1)
		return

	var caravans: Array = get_nodes_in_group("road_caravans")
	if caravans.is_empty():
		print("FAIL no caravans")
		quit(1)
		return
	## Pick the caravan closest to Athens on Sacred Way.
	var best: Node3D = caravans[0]
	var best_d: = INF
	for c in caravans:
		var d: float = Vector2(c.global_position.x, c.global_position.z).distance_to(Vector2(-60, 40))
		if d < best_d:
			best_d = d
			best = c

	## Stand south of the caravan; cam look = (-sin(yaw), -cos(yaw)).
	var cx: = best.global_position.x
	var cz: = best.global_position.z
	var px: = cx
	var pz: = cz + 12.0
	player.global_position = Vector3(px, world.sample_height(px, pz) + 1.6, pz)
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	var yaw: = atan2(-(cx - px), -(cz - pz))
	player.cam_pitch = -0.22
	player.cam_yaw = yaw
	if player.mesh_root:
		player.mesh_root.rotation.y = yaw
	if player.camera_pivot:
		player.camera_pivot.rotation.y = player.cam_yaw
		player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true
	if player.spring_arm:
		player.spring_arm.spring_length = 6.5
		player.spring_arm.position.y = 1.0
	for _j in 120:
		await process_frame
	cx = best.global_position.x
	cz = best.global_position.z
	px = cx
	pz = cz + 11.0
	player.global_position = Vector3(px, world.sample_height(px, pz) + 1.6, pz)
	yaw = atan2(-(cx - px), -(cz - pz))
	player.cam_yaw = yaw
	if player.camera_pivot:
		player.camera_pivot.rotation.y = player.cam_yaw
		player.camera_pivot.rotation.x = player.cam_pitch
	for _k in 25:
		await process_frame

	var path: = "/opt/cursor/artifacts/hellas_road_caravan.png"
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SHOT caravan -> ", path, " at ", best.global_position)
	print("CAPTURE_CARAVAN_OK")
	quit(0)
