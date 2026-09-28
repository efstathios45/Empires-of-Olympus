extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var gs = root.get_node("GameState")
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
	var model = player.get_node("MeshRoot").get_child(0)
	print("model=", model.name, " kaykit=", load("res://scripts/utils/hero_anim.gd").is_kaykit(model))
	print("has_LegPlant=", model.find_child("LegPlantFix", true, false) != null)
	var anim: AnimationPlayer = player.get("anim")
	print("has_Walking_A=", anim.has_animation("Walking_A"), " has_Blocking=", anim.has_animation("Blocking"))
	print("shield=", player.get("shield_node") != null, " weapon=", player.get("weapon_node") != null)
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")
	print("alias_walk=", HeroAnim.resolve(anim, "walk"), " alias_block=", HeroAnim.resolve(anim, "block"))
	# force walk a bit and check foot y
	player.set_physics_process(false)
	anim.play("Walking_A")
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var ymin := 999.0
	var zmin := 999.0
	var zmax := -999.0
	for i in 30:
		await process_frame
		var lf = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("foot.l"))).origin
		ymin = minf(ymin, lf.y)
		zmin = minf(zmin, lf.z)
		zmax = maxf(zmax, lf.z)
	print("LIVE foot_ymin=", snapped(ymin, 0.01), " z_range=", snapped(zmax-zmin, 0.01), " player_y=", snapped(player.global_position.y, 0.01))
	var ok = anim.has_animation("Walking_A") and anim.has_animation("Blocking") and player.get("shield_node") != null and (zmax-zmin) > 0.1
	print("SMOKE_KAYKIT OK=", ok)
	quit(0 if ok else 1)
