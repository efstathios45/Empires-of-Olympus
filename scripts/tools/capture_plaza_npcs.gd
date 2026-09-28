extends SceneTree
## In-world plaza shot of NPCs after stand-plant — must look human, not melted.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var gs = root.get_node_or_null("GameState")
	gs.empire = "sparta"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	change_scene_to_file("res://scenes/game_world.tscn")
	for i in 180:
		await process_frame

	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	assert(player != null)

	## Plaza center near fountain / townsfolk.
	player.global_position = Vector3(2.0, 0.0, 4.0)
	var world: Node = root.get_first_node_in_group("game_world")
	if world != null and world.has_method("sample_height"):
		player.global_position.y = float(world.call("sample_height", player.global_position.x, player.global_position.z)) + 0.1

	player.cam_pitch = -0.25
	player.cam_yaw = deg_to_rad(200.0)
	player.camera_pivot.rotation.y = player.cam_yaw
	player.camera_pivot.rotation.x = player.cam_pitch
	if player.camera:
		player.camera.current = true

	## Count planted NPCs
	var planted := 0
	var total_human := 0
	for n in root.find_children("*", "Skeleton3D", true, false):
		var skel := n as Skeleton3D
		if skel.find_bone("Hips") < 0:
			continue
		total_human += 1
		if skel.has_node("LegPlantFix"):
			planted += 1
	print("PLANTED=", planted, "/", total_human)

	for i in 30:
		await process_frame
	root.get_texture().get_image().save_png("/opt/cursor/artifacts/PLAZA_npcs_after.png")

	## Second angle — smith yard
	player.global_position = Vector3(10.0, 0.0, 14.0)
	if world != null and world.has_method("sample_height"):
		player.global_position.y = float(world.call("sample_height", player.global_position.x, player.global_position.z)) + 0.1
	player.cam_yaw = deg_to_rad(140.0)
	player.camera_pivot.rotation.y = player.cam_yaw
	for i in 20:
		await process_frame
	root.get_texture().get_image().save_png("/opt/cursor/artifacts/PLAZA_smith_after.png")

	assert(planted >= 6, "expected plaza humanoids planted, got %d" % planted)
	print("CAPTURE_PLAZA_NPCS_OK")
	quit(0)
