extends SceneTree
## Capture the M-key Hellas map (capitals + dens) and one den exterior.


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
	for _i in 280:
		await process_frame

	var world: Node = get_first_node_in_group("game_world")
	if world == null:
		print("FAIL no game_world")
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

	var MapData = load("res://scripts/world/hellas_map_data.gd")
	## Centaur March sits on the Athens–Sparta road — clear of city walls.
	var den: Dictionary = MapData.DENS[1]
	var den_pos: Vector2 = den["pos"]
	var den_r: float = float(den["r"])
	## Stand SE of the ring, face NW into the camp.
	var px: = den_pos.x + den_r * 0.95
	var pz: = den_pos.y + den_r * 0.95
	player.global_position = Vector3(px, world.sample_height(px, pz) + 1.6, pz)
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	if "hp" in player and "max_hp" in player:
		player.hp = player.max_hp
	var look: = Vector2(den_pos.x - px, den_pos.y - pz)
	var yaw: = atan2(-look.x, -look.y)
	player.cam_pitch = -0.28
	player.cam_yaw = yaw
	if player.mesh_root:
		player.mesh_root.rotation.y = yaw
	if player.camera_pivot:
		player.camera_pivot.rotation.y = player.cam_yaw
		player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true
	if player.spring_arm:
		player.spring_arm.spring_length = 16.0
		player.spring_arm.position.y = 0.8
	for _j in 60:
		await process_frame
	var den_path: = "/opt/cursor/artifacts/den_centaur_march.png"
	root.get_viewport().get_texture().get_image().save_png(den_path)
	print("SHOT den -> ", den_path, " at ", px, ",", pz)

	var hud = get_first_node_in_group("hud")
	if hud == null or not hud.has_method("toggle_map"):
		print("FAIL no hud toggle_map")
		quit(1)
		return
	hud.toggle_map()
	for _k in 40:
		await process_frame
	var map_path: = "/opt/cursor/artifacts/hellas_map_widget.png"
	root.get_viewport().get_texture().get_image().save_png(map_path)
	print("SHOT map -> ", map_path)

	## Sanity: dens spawned and map panel open.
	var enemies: = 0
	for n in get_nodes_in_group("enemies"):
		if is_instance_valid(n) and not n.is_in_group("oracle_stones"):
			enemies += 1
	if enemies < 50:
		print("FAIL expected dense dens packs, got ", enemies)
		quit(1)
		return
	if not bool(hud.get("ui_open")):
		print("FAIL map panel not open")
		quit(1)
		return
	print("CAPTURE_MAP_DENS_OK enemies=", enemies)
	quit(0)
