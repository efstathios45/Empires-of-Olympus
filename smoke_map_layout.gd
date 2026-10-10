extends SceneTree
## Headless: spread capitals/dens, Hellenic roads, olive orchards.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	failed += _check_spread()
	failed += _check_roads()
	failed += _check_olives()
	failed += _check_world_wiring()
	if failed > 0:
		print("SMOKE FAIL: %d" % failed)
		quit(1)
	else:
		print("SMOKE_MAP_LAYOUT_OK")
		quit(0)


func _check_spread() -> int:
	var MapData = load("res://scripts/world/hellas_map_data.gd")
	if MapData == null:
		print("FAIL map data")
		return 1
	var caps: Array = MapData.CAPITALS
	if caps.size() != 3:
		print("FAIL capitals")
		return 1
	## Capitals must form a wide triangle (not a short corridor).
	var a: Vector2 = caps[0]["pos"]
	var b: Vector2 = caps[1]["pos"]
	var c: Vector2 = caps[2]["pos"]
	if a.distance_to(b) < 200.0 or a.distance_to(c) < 200.0 or b.distance_to(c) < 280.0:
		print("FAIL capitals too close", a.distance_to(b), a.distance_to(c), b.distance_to(c))
		return 1
	## Dens not colinear along one axis — variance in both X and Z.
	var xs: Array = []
	var zs: Array = []
	for d in MapData.DENS:
		var p: Vector2 = d["pos"]
		xs.append(p.x)
		zs.append(p.y)
		for cap in caps:
			if p.distance_to(cap["pos"]) < 55.0:
				print("FAIL den too close to capital", d["id"], cap["id"])
				return 1
	xs.sort()
	zs.sort()
	if absf(float(xs[-1]) - float(xs[0])) < 400.0:
		print("FAIL dens not spread on X", xs[0], xs[-1])
		return 1
	if absf(float(zs[-1]) - float(zs[0])) < 400.0:
		print("FAIL dens not spread on Z", zs[0], zs[-1])
		return 1
	## Arena offset from Athens N-S line.
	var arena: Vector2 = MapData.ARENA["pos"]
	if absf(arena.x) < 40.0:
		print("FAIL arena still on Athens meridian")
		return 1
	print("OK spread capitals+dens arena=", arena)
	return 0


func _check_roads() -> int:
	var MapData = load("res://scripts/world/hellas_map_data.gd")
	if MapData.ROADS.size() < 6:
		print("FAIL too few roads", MapData.ROADS.size())
		return 1
	var samples: Array = MapData.road_segment_samples(3.0)
	if samples.size() < 80:
		print("FAIL too few road samples", samples.size())
		return 1
	## Sacred Way should reach Sparta.
	var hit_sparta: = false
	for s in samples:
		if Vector2(s["pos"]).distance_to(MapData.CAPITALS[1]["pos"]) < 8.0:
			hit_sparta = true
			break
	if not hit_sparta:
		print("FAIL roads miss Sparta")
		return 1
	print("OK roads=", MapData.ROADS.size(), " samples=", samples.size())
	return 0


func _check_olives() -> int:
	var MapData = load("res://scripts/world/hellas_map_data.gd")
	if MapData.OLIVE_ORCHARDS.size() < 12:
		print("FAIL too few orchards", MapData.OLIVE_ORCHARDS.size())
		return 1
	var olives: = 0
	var cypress: = 0
	for g in MapData.OLIVE_ORCHARDS:
		if String(g.get("kind", "")) == "cypress":
			cypress += 1
		else:
			olives += 1
		if float(g["r"]) > 18.0 or int(g["count"]) > 8:
			print("FAIL orchard too dense (forest-like)", g)
			return 1
	if olives < 10 or cypress < 3:
		print("FAIL olive/cypress mix", olives, cypress)
		return 1
	print("OK orchards olive=", olives, " cypress=", cypress)
	return 0


func _check_world_wiring() -> int:
	var src: = FileAccess.get_file_as_string("res://scripts/game_world.gd")
	if src.find("_build_roads") < 0 or src.find("_paint_roads_on_splat") < 0:
		print("FAIL game_world missing road builders")
		return 1
	if src.find("cobblestone_large_01") < 0:
		print("FAIL roads not using Poly Haven cobblestone_large_01")
		return 1
	if src.find("white_marble.png") >= 0:
		var roads_fn: = src.find("func _build_roads")
		var dens_fn: = src.find("func _build_dens")
		if roads_fn >= 0 and dens_fn > roads_fn:
			var roads_body: = src.substr(roads_fn, dens_fn - roads_fn)
			if roads_body.find("white_marble") >= 0:
				print("FAIL roads still use white_marble slabs")
				return 1
	if src.find("OLIVE_ORCHARDS") < 0:
		print("FAIL forests not using olive orchards")
		return 1
	if src.find("Vector2(-240.0, 210.0)") >= 0:
		print("FAIL old Sparta coords still in game_world")
		return 1
	var WorldScr: Script = load("res://scripts/game_world.gd") as Script
	var cmap: Dictionary = WorldScr.get_script_constant_map()
	var cities: Array = cmap.get("CITIES", [])
	var sparta: Vector2 = cities[1]["c"]
	if sparta.distance_to(Vector2(-280.0, 200.0)) > 1.0:
		print("FAIL CITIES not synced", sparta)
		return 1
	print("OK game_world roads+olives wiring")
	return 0
