extends SceneTree
## Boot world briefly and assert caravans + zero grass on a road sample.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.empire = "athens"
		gs.player_class = "hoplite"
		gs.player_name = "Hero"
		gs.tutorial_step = 99
	change_scene_to_file("res://scenes/game_world.tscn")
	for _i in 240:
		await process_frame

	var world: Node = get_first_node_in_group("game_world")
	if world == null:
		print("FAIL no world")
		quit(1)
		return

	## Grass must be zero on the Sacred Way mid-point.
	var mid: = Vector2(-80.0, 55.0)
	var gw: float = float(world.grass_weight(mid.x, mid.y))
	if gw > 0.001:
		print("FAIL grass on road mid=", gw)
		quit(1)
		return
	print("OK grass_weight on road=", gw)

	var caravans: Array = get_nodes_in_group("road_caravans")
	if caravans.size() < 3:
		print("FAIL too few caravans", caravans.size())
		quit(1)
		return
	print("OK caravans=", caravans.size())

	var escorts: = 0
	for c in caravans:
		if c.has_method("is_moving"):
			pass
		var members = c.get("_members")
		if members is Array:
			escorts += (members as Array).size()
	if escorts < 6:
		print("FAIL too few escorts", escorts)
		quit(1)
		return
	print("OK escorts=", escorts)
	print("SMOKE_ROAD_CARAVAN_OK")
	quit(0)
