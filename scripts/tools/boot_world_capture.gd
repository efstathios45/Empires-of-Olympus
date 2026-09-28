extends SceneTree
func _init():
	call_deferred("run")
func run():
	await process_frame
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("NO_GAMESTATE")
		quit(1)
		return
	gs.empire = "sparta"
	gs.player_class = "hoplite"
	if gs.get("player_name") != null:
		gs.player_name = "TestHero"
	change_scene_to_file("res://scenes/game_world.tscn")
	for i in 120:
		await process_frame
	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	print("PLAYER=", player)
	if player == null:
		print("NO_PLAYER children=", root.get_child_count())
		for c in root.get_children():
			print(" ROOT_CHILD=", c.name, c.get_class())
		quit(1)
		return
	player.set_physics_process(false)
	# Keep on terrain height
	var p = player.global_position
	player.global_position = Vector3(p.x, p.y, p.z)
	if player.get("anim") and player.anim:
		player.anim.play("ual1_Idle")
	for i in 40:
		await process_frame
	var host = player.get_parent()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.0
	host.add_child(cam)
	cam.global_position = player.global_position + Vector3(4.0, 1.3, 0.0)
	cam.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	cam.current = true
	for i in 12:
		await process_frame
	var img = root.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/ingame_hero_idle_side.png")
	print("SAVED ingame_hero_idle_side.png")
	var skel = null
	if player.get("mesh_root"):
		for n in player.mesh_root.find_children("*", "Skeleton3D", true, false):
			skel = n; break
	if skel:
		print("HAS_FIX=", skel.has_node("SkyGazeFix"))
		var hi = skel.find_bone("Head")
		var hips = skel.find_bone("Hips")
		var ht = skel.global_transform * skel.get_bone_global_pose(hi)
		var hp = skel.global_transform * skel.get_bone_global_pose(hips)
		var upright = (ht.origin - hp.origin).normalized().dot(Vector3.UP)
		print("INGAME_FWD_UP=", (-ht.basis.z).normalized().dot(Vector3.UP), " HEAD_EX=", rad_to_deg(ht.basis.get_euler().x), " UPRIGHT=", upright)
	if player.get("anim") and player.anim:
		player.anim.play("ual1_Walk")
	for i in 30:
		await process_frame
	img = root.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/ingame_hero_walk_side.png")
	print("SAVED ingame_hero_walk_side.png")
	if skel:
		var ht2 = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Head"))
		print("WALK_FWD_UP=", (-ht2.basis.z).normalized().dot(Vector3.UP))
	var npc = null
	for n in root.find_children("*", "Node3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("npc.gd"):
			npc = n
			break
	print("NPC=", npc)
	if npc:
		cam.global_position = npc.global_position + Vector3(3.5, 1.2, 0)
		cam.look_at(npc.global_position + Vector3(0, 1.0, 0), Vector3.UP)
		for i in 20:
			await process_frame
		img = root.get_texture().get_image()
		img.save_png("/opt/cursor/artifacts/ingame_npc_side.png")
		print("SAVED ingame_npc_side.png")
		var nskel = null
		for n in npc.find_children("*", "Skeleton3D", true, false):
			nskel = n; break
		if nskel:
			print("NPC_HAS_FIX=", nskel.has_node("SkyGazeFix"))
			var nhi = nskel.find_bone("Head")
			if nhi >= 0:
				var nht = nskel.global_transform * nskel.get_bone_global_pose(nhi)
				print("NPC_FWD_UP=", (-nht.basis.z).normalized().dot(Vector3.UP))
	print("INGAME_CAPTURE_OK")
	quit(0)
