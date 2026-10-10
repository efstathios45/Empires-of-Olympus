extends SceneTree
## Boot the world and capture Athens / Sparta / Thebes plazas + a wild belt.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var gs = root.get_node_or_null("GameState")
	gs.empire = "athens"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	change_scene_to_file("res://scenes/game_world.tscn")
	## Larger map needs more settle frames.
	for _i in 240:
		await process_frame

	var world: Node = root.get_first_node_in_group("game_world")
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

	var cities: Array = world.CITIES
	var shots: = [
		["athens", cities[0]["c"], 25.0, deg_to_rad(200.0)],
		["sparta", cities[1]["c"], 28.0, deg_to_rad(160.0)],
		["thebes", cities[2]["c"], 28.0, deg_to_rad(210.0)],
		["wilds_sparta_road", Vector2(-150.0, 140.0), 20.0, deg_to_rad(90.0)],
	]
	for shot in shots:
		var name: String = String(shot[0])
		var c: Vector2 = shot[1]
		var dist: float = float(shot[2])
		var yaw: float = float(shot[3])
		var px: = c.x + sin(yaw) * dist
		var pz: = c.y + cos(yaw) * dist
		player.global_position = Vector3(px, world.sample_height(px, pz) + 1.2, pz)
		player.cam_pitch = -0.35
		player.cam_yaw = yaw + PI
		if player.camera_pivot:
			player.camera_pivot.rotation.y = player.cam_yaw
			player.camera_pivot.rotation.x = player.cam_pitch
		if player.camera:
			player.camera.current = true
		for _j in 40:
			await process_frame
		var path: = "/opt/cursor/artifacts/city_%s.png" % name
		root.get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", name, " -> ", path)

	## Sanity: walls / plazas present, mobs exist
	var gates: = 0
	var enemies: = 0
	for n in root.get_children():
		pass
	for n in world.get_children():
		if String(n.name).begins_with("PlazaMosaicDisc"):
			gates += 1
	for n in world.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(n) and not n.is_in_group("oracle_stones"):
			enemies += 1
	var discs: = world.get_tree().get_nodes_in_group("plaza_mosaic_disc").size()
	print("mosaic_discs=", discs, " enemies=", enemies)
	if discs < 1:
		print("FAIL expected athens mosaic disc")
		quit(1)
		return
	if enemies < 40:
		print("FAIL expected wide mob range, got ", enemies)
		quit(1)
		return
	print("CAPTURE_THREE_CITIES_OK")
	quit(0)
