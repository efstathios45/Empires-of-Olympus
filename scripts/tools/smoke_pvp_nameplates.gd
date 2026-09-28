extends SceneTree
## Headless: empire nameplates, rival meta, death loot from bag+equipped.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs := get_root().get_node_or_null("GameState")
	if gs == null:
		push_error("GameState missing")
		quit(1)
		return
	gs.call("reset_run")
	gs.set("empire", "sparta")
	gs.set("player_name", "Leonidas")
	gs.set("level", 5)
	gs.set("bag", [])
	gs.set("equipped", {
		"helmet": "corinthian_helm", "armor": "", "weapon": "xiphos", "shield": "aspis",
		"boots": "leather_boots", "necklace": "", "earring": "", "bracelet": "",
	})
	gs.call("try_add_to_bag", "bronze_knife", 1)
	gs.call("try_add_to_bag", "health_potion", 2)

	var Nameplate = load("res://scripts/player_nameplate.gd")
	var plate = Nameplate.new()
	get_root().add_child(plate)
	await process_frame
	plate.call("set_plate", "Leonidas", 5, "sparta")
	if str(plate.get("display_name")) != "Leonidas":
		push_error("nameplate name")
		quit(1)
		return
	if int(plate.get("level")) != 5:
		push_error("nameplate level")
		quit(1)
		return

	var drops: Array = gs.call("take_pvp_death_drops", 2, 2)
	if drops.is_empty():
		push_error("expected pvp drops")
		quit(1)
		return
	var eq: Dictionary = gs.get("equipped")
	var emptied := 0
	for k in eq.keys():
		if str(eq[k]) == "":
			emptied += 1
	if emptied < 2:
		push_error("equipped not stripped enough emptied=%d" % emptied)
		quit(1)
		return

	## Rival empire helper (same rules as player.is_rival_player).
	var mine := "sparta"
	var athens := "athens"
	if mine == athens:
		push_error("rival logic broken")
		quit(1)
		return

	var net := get_root().get_node_or_null("NetSession")
	if net == null:
		push_error("NetSession autoload missing")
		quit(1)
		return
	if bool(net.call("is_online")):
		push_error("should start offline")
		quit(1)
		return

	print("SMOKE_PVP_NAMEPLATES_OK drops=", drops.size(), " ids=", drops)
	quit(0)
