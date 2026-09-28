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
	var nlow := String(model.name).to_lower()
	print("model=", model.name)
	print("is_hoplite=", ("spartan" in nlow or "hoplite" in nlow))
	print("is_kaykit=", ("knight" in nlow or "kaykit" in nlow))
	print("has_LegPlant=", model.find_child("LegPlantFix", true, false) != null)
	print("shield=", player.get("shield_node") != null, " weapon=", player.get("weapon_node") != null)
	var anim: AnimationPlayer = player.get("anim")
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")
	print("walk=", HeroAnim.resolve(anim, "walk"), " block=", HeroAnim.resolve(anim, "block"))
	var ok := ("spartan" in nlow or "hoplite" in nlow) and player.get("shield_node") != null \
		and HeroAnim.resolve(anim, "block") != ""
	print("SMOKE_HOPLITE OK=", ok)
	quit(0 if ok else 1)
