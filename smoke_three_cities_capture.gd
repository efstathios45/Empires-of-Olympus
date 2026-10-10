extends SceneTree
## Boot the world and capture Athens / Sparta / Thebes from outside the south gates.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var gs = root.get_node_or_null("GameState")
	gs.empire = "athens"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	change_scene_to_file("res://scenes/game_world.tscn")
	for _i in 260:
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

	## Hide tutorial overlay text for cleaner shots.
	var hud = get_first_node_in_group("hud")
	if hud != null and hud.has_method("hide"):
		pass

	var cities: Array = world.CITIES
	## Stand south of each city's wall, look north into the gate / agora.
	var shots: Array = [
		["athens", cities[0]["c"]],
		["sparta", cities[1]["c"]],
		["thebes", cities[2]["c"]],
		["wilds_sparta_road", Vector2(-150.0, 140.0)],
	]
	for shot in shots:
		var shot_name: String = String(shot[0])
		var c: Vector2 = shot[1]
		var px: float
		var pz: float
		var yaw: float
		if shot_name.begins_with("wilds"):
			px = c.x
			pz = c.y
			## Look roughly toward Sparta (SW).
			yaw = deg_to_rad(-40.0)
		else:
			## Outside south gate (larger +Z), face -Z into the gate / agora.
			px = c.x
			pz = c.y + 48.0
			yaw = 0.0
		player.global_position = Vector3(px, world.sample_height(px, pz) + 1.6, pz)
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		## Survive teleport across the large map (no fall / stray hits).
		if "hp" in player and "max_hp" in player:
			player.hp = player.max_hp
		if "dead" in player:
			player.dead = false
		player.cam_pitch = -0.18
		player.cam_yaw = yaw
		if player.mesh_root:
			player.mesh_root.rotation.y = yaw
		if player.camera_pivot:
			player.camera_pivot.rotation.y = player.cam_yaw
			player.camera_pivot.rotation.x = player.cam_pitch
		if player.camera:
			player.camera.current = true
		if player.spring_arm:
			player.spring_arm.spring_length = 9.0
			player.spring_arm.position.y = 0.45
		## Close any death panel from a prior shot.
		var hud2 = get_first_node_in_group("hud")
		if hud2 != null and hud2.has_method("hide_death"):
			hud2.hide_death()
		elif hud2 != null:
			for ch in hud2.get_children():
				if String(ch.name).to_lower().contains("death") or String(ch.name).to_lower().contains("fallen"):
					ch.visible = false
		for _j in 55:
			await process_frame
		var path: = "/opt/cursor/artifacts/city_%s.png" % shot_name
		root.get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", shot_name, " pos=", px, ",", pz, " -> ", path)

	var enemies: = 0
	for n in get_nodes_in_group("enemies"):
		if is_instance_valid(n) and not n.is_in_group("oracle_stones"):
			enemies += 1
	var discs: = get_nodes_in_group("plaza_mosaic_disc").size()
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
