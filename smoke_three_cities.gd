extends SceneTree
## Headless checks for Athens / Sparta / Thebes multi-city world.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	failed += _check_constants()
	failed += _check_plaza_api()
	failed += _check_walls_api()
	failed += _check_spawn_helpers()
	if failed > 0:
		print("SMOKE FAIL: %d" % failed)
		quit(1)
	else:
		print("SMOKE_THREE_CITIES_OK")
		quit(0)


func _check_constants() -> int:
	var WorldScr: Script = load("res://scripts/game_world.gd") as Script
	if WorldScr == null:
		print("FAIL game_world load")
		return 1
	var cmap: Dictionary = WorldScr.get_script_constant_map()
	var cities = cmap.get("CITIES", [])
	if typeof(cities) != TYPE_ARRAY or cities.size() != 3:
		print("FAIL city count", cities)
		return 1
	var ids: Dictionary = {}
	for c in cities:
		ids[String(c["id"])] = true
	if not ids.has("athens") or not ids.has("sparta") or not ids.has("thebes"):
		print("FAIL missing city ids", ids)
		return 1
	var wall_half: float = float(cmap.get("WALL_HALF", 0))
	if wall_half < 250.0:
		print("FAIL map not enlarged", wall_half)
		return 1
	var zones = cmap.get("ZONES", [])
	if typeof(zones) != TYPE_ARRAY or zones.size() < 10:
		print("FAIL too few zones", zones)
		return 1
	var a: Vector2 = cities[0]["c"]
	var b: Vector2 = cities[1]["c"]
	var cpos: Vector2 = cities[2]["c"]
	if a.distance_to(b) < 120.0 or a.distance_to(cpos) < 120.0 or b.distance_to(cpos) < 120.0:
		print("FAIL cities too close")
		return 1
	var terrain: int = int(cmap.get("TERRAIN_SIZE", 0))
	if terrain < 700:
		print("FAIL terrain too small", terrain)
		return 1
	print("OK constants cities=3 zones=", zones.size(), " wall_half=", wall_half, " terrain=", terrain)
	return 0


func _check_plaza_api() -> int:
	var Plaza = load("res://scripts/world/city_plaza.gd")
	if Plaza == null or not Plaza.has_method("build"):
		print("FAIL plaza")
		return 1
	print("OK plaza API")
	return 0


func _check_walls_api() -> int:
	var Walls = load("res://scripts/world/city_walls.gd")
	if Walls == null or not Walls.has_method("build"):
		print("FAIL walls")
		return 1
	print("OK walls API")
	return 0


func _check_spawn_helpers() -> int:
	var cities: Array = [
		{"id": "athens", "empire": "athens", "c": Vector2(0.0, 0.0)},
		{"id": "sparta", "empire": "sparta", "c": Vector2(-240.0, 210.0)},
		{"id": "thebes", "empire": "corinth", "c": Vector2(240.0, -190.0)},
	]
	var sc: Dictionary = _map_empire(cities, "sparta")
	if String(sc.get("id", "")) != "sparta":
		print("FAIL sparta mapping", sc)
		return 1
	var tc: Dictionary = _map_empire(cities, "corinth")
	if String(tc.get("id", "")) != "thebes":
		print("FAIL corinth to thebes", tc)
		return 1
	var near: Dictionary = _nearest(cities, Vector2(-200, 200))
	if String(near.get("id", "")) != "sparta":
		print("FAIL nearest sparta", near)
		return 1
	print("OK spawn helpers")
	return 0


func _map_empire(cities: Array, emp: String) -> Dictionary:
	for city in cities:
		if String(city.get("empire", "")) == emp:
			return city
	return cities[0]


func _nearest(cities: Array, pos: Vector2) -> Dictionary:
	var best: Dictionary = cities[0]
	var best_d: = INF
	for city in cities:
		var d: = pos.distance_squared_to(city["c"])
		if d < best_d:
			best_d = d
			best = city
	return best
