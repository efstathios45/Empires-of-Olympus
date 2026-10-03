extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	var gs = root.get_node_or_null("GameState")
	gs.empire = "sparta"
	gs.player_class = "hoplite"
	gs.player_name = "Hero"
	change_scene_to_file("res://scenes/game_world.tscn")
	for i in 200:
		await process_frame

	var player = null
	for n in root.find_children("*", "CharacterBody3D", true, false):
		var scr = n.get_script()
		if scr and String(scr.resource_path).ends_with("player.gd"):
			player = n
			break
	assert (player != null, "no player")


	player.set_physics_process(false)
	player.set_process(false)

	var skel: Skeleton3D = null
	for n in player.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert (skel != null and skel.has_node("LegPlantFix"))
	var fix: Node = skel.get_node("LegPlantFix")

	var player_anim: AnimationPlayer = player.get("anim") as AnimationPlayer
	var fix_anim: AnimationPlayer = fix.get("_anim") as AnimationPlayer
	print("player.anim=", player_anim, " path=", player_anim.get_path() if player_anim else "?")
	print("fix._anim=", fix_anim, " path=", fix_anim.get_path() if fix_anim else "NULL")
	print("same_anim=", player_anim == fix_anim)
	if player_anim:
		print("player libs=", player_anim.get_animation_library_list(), 
			" has_Walk=", player_anim.has_animation("ual1_Walk"), 
			" has_Attack=", player_anim.has_animation("ual1_Sword_Attack"), 
			" current=", player_anim.current_animation, 
			" playing=", player_anim.is_playing())
	if fix_anim and fix_anim != player_anim:
		print("FIX libs=", fix_anim.get_animation_library_list(), 
			" has_Walk=", fix_anim.has_animation("ual1_Walk"), 
			" current=", fix_anim.current_animation, 
			" playing=", fix_anim.is_playing())


	for ap in player.find_children("*", "AnimationPlayer", true, false):
		print("AP name=", ap.name, " path=", ap.get_path(), 
			" libs=", ap.get_animation_library_list(), 
			" clip_count=", ap.get_animation_list().size())


	player_anim.play("ual1_Walk")
	for i in 8:
		await process_frame
	print("mode=", fix.call("_clip_mode"), " after play Walk; fix.current=", 
		fix_anim.current_animation if fix_anim else "null", 
		" player.current=", player_anim.current_animation)

	var zs: Array = []
	for i in 30:
		await process_frame
		var lf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
		zs.append(snapped(lf.z, 0.01))
	print("WALK LFz=", zs)
	var zmin: = 999.0
	var zmax: = -999.0
	for z in zs:
		zmin = minf(zmin, float(z))
		zmax = maxf(zmax, float(z))
	print("WALK z_range=", snapped(zmax - zmin, 0.01))


	player_anim.play("ual1_Idle")
	for i in 8:
		await process_frame
	var idle_arm: = 0.0
	var bi_idle: = skel.find_bone("RightUpperArm")
	idle_arm = skel.get_bone_pose_rotation(bi_idle).angle_to(
		skel.get_bone_rest(bi_idle).basis.get_rotation_quaternion())

	player_anim.play("ual1_Sword_Attack")
	for i in 6:
		await process_frame
	print("mode_attack=", fix.call("_clip_mode"), " current=", player_anim.current_animation)
	var arm_angles: Array = []
	var hand0: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("RightHand"))).origin
	var hand_travel: = 0.0
	for i in 25:
		await process_frame
		var bi: = skel.find_bone("RightUpperArm")
		var q: Quaternion = skel.get_bone_pose_rotation(bi)
		var rest_q: Quaternion = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
		arm_angles.append(snapped(q.angle_to(rest_q), 0.01))
		var hand: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("RightHand"))).origin
		hand_travel = maxf(hand_travel, hand.distance_to(hand0))
	print("ATTACK arm_delta=", arm_angles)
	var amin: = 999.0
	var amax: = -999.0
	for a in arm_angles:
		amin = minf(amin, float(a))
		amax = maxf(amax, float(a))
	var attack_vs_idle: = absf(amax - idle_arm)
	print("ATTACK arm_range=", snapped(amax - amin, 0.01), 
		" attack_vs_idle=", snapped(attack_vs_idle, 0.01), 
		" hand_travel=", snapped(hand_travel, 0.01))

	var ok: = player_anim == fix_anim and (zmax - zmin) > 0.05 and hand_travel > 0.12
	print("LIVE_PLAYER_ANIM_DONE same=", player_anim == fix_anim, 
		" z_range=", snapped(zmax - zmin, 0.01), 
		" attack_vs_idle=", snapped(attack_vs_idle, 0.01), 
		" hand_travel=", snapped(hand_travel, 0.01), 
		" OK=", ok)
	quit(0 if ok else 1)
