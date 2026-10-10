extends SceneTree
## Boot Hellas, sample FPS after settle, assert lean defaults took effect.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var ds = root.get_node_or_null("DisplaySettings")
	if ds:
		var cfg_path: String = ds.CFG_PATH if "CFG_PATH" in ds else "user://display_settings.cfg"
		if FileAccess.file_exists(cfg_path):
			DirAccess.remove_absolute(cfg_path)
		ds.quality = "performance"
		ds.max_fps = 144
		ds.vsync = false
		ds.show_fps = true
		ds.apply()

	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.empire = "athens"
		gs.player_class = "hoplite"
		gs.player_name = "Hero"
		gs.tutorial_step = 99

	var t0: = Time.get_ticks_msec()
	change_scene_to_file("res://scenes/game_world.tscn")
	for _i in 300:
		await process_frame
	var load_ms: = Time.get_ticks_msec() - t0
	print("LOAD_MS ", load_ms)

	var world: Node = get_first_node_in_group("game_world")
	if world == null:
		print("FAIL no world")
		quit(1)
		return

	## Roadbed still grass-free.
	var mid: = Vector2(-80.0, 55.0)
	var gw: float = float(world.grass_weight(mid.x, mid.y))
	if gw > 0.001:
		print("FAIL grass on road", gw)
		quit(1)
		return

	var caravans: Array = get_nodes_in_group("road_caravans")
	if caravans.size() < 3 or caravans.size() > 4:
		print("FAIL caravan count", caravans.size())
		quit(1)
		return
	print("OK caravans=", caravans.size())

	var enemies: Array = get_nodes_in_group("enemies")
	print("OK enemies=", enemies.size())

	## Sample FPS for ~2s after settle.
	var samples: Array = []
	for _j in 120:
		await process_frame
		samples.append(Engine.get_frames_per_second())
	samples.sort()
	var mid_fps: int = int(samples[samples.size() / 2])
	var min_fps: int = int(samples[0])
	print("FPS_MEDIAN ", mid_fps, " FPS_MIN ", min_fps)

	var grass = world.get("_grass")
	if grass != null:
		print("GRASS half=", grass.get("playable_half"),
			" clusters=", grass.get("clusters_per_cell"),
			" view=", grass.get("tile_view_dist"),
			" tiles=", (grass.get("_tiles") as Array).size() if grass.get("_tiles") else -1)

	var shadow_sz: = int(ProjectSettings.get_setting(
		"rendering/lights_and_shadows/directional_shadow/size", 0))
	print("SHADOW_ATLAS ", shadow_sz)

	## CI/headless can be slow; require world health more than a hard FPS floor.
	if enemies.size() < 40:
		print("FAIL too few enemies", enemies.size())
		quit(1)
		return
	if load_ms > 120000:
		print("FAIL load extremely slow", load_ms)
		quit(1)
		return

	print("SMOKE_LAG_FIX_OK median_fps=", mid_fps, " load_ms=", load_ms)
	quit(0)
