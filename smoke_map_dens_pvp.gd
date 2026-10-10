extends SceneTree
## Headless checks: Hellas map capitals + dens + open cross-empire PvP.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	failed += _check_map_data()
	failed += _check_world_zones()
	failed += _check_hud_map()
	failed += _check_open_pvp()
	if failed > 0:
		print("SMOKE FAIL: %d" % failed)
		quit(1)
	else:
		print("SMOKE_MAP_DENS_PVP_OK")
		quit(0)


func _check_map_data() -> int:
	var MapData = load("res://scripts/world/hellas_map_data.gd")
	if MapData == null:
		print("FAIL hellas_map_data load")
		return 1
	if MapData.CAPITALS.size() != 3:
		print("FAIL capital count", MapData.CAPITALS.size())
		return 1
	var ids: Dictionary = {}
	for c in MapData.CAPITALS:
		ids[String(c["id"])] = true
	if not ids.has("athens") or not ids.has("sparta") or not ids.has("thebes"):
		print("FAIL missing capitals", ids)
		return 1
	if MapData.DENS.size() < 6:
		print("FAIL too few dens", MapData.DENS.size())
		return 1
	if float(MapData.MAP_WORLD_SPAN) < 600.0:
		print("FAIL map span too small", MapData.MAP_WORLD_SPAN)
		return 1
	## Dens should sit between capitals, not inside plazas.
	for d in MapData.DENS:
		var dp: Vector2 = d["pos"]
		for c in MapData.CAPITALS:
			var cp: Vector2 = c["pos"]
			if dp.distance_to(cp) < 50.0:
				print("FAIL den too close to capital", d["name"], c["name"])
				return 1
	var regions: Array = MapData.map_regions()
	var kinds: Dictionary = {}
	for r in regions:
		kinds[String(r.get("kind", ""))] = true
	if not kinds.has("capital") or not kinds.has("den") or not kinds.has("boss"):
		print("FAIL map_regions kinds", kinds)
		return 1
	var zones: Array = MapData.zones_for_spawns()
	if zones.size() != MapData.DENS.size():
		print("FAIL zones/dens mismatch")
		return 1
	for z in zones:
		if not z.has("c") or not z.has("r") or not z.has("ids"):
			print("FAIL zone shape", z)
			return 1
		if (z["ids"] as Array).size() < 6:
			print("FAIL den understocked", z.get("name", "?"))
			return 1
	print("OK map_data capitals=3 dens=", MapData.DENS.size(), " span=", MapData.MAP_WORLD_SPAN)
	return 0


func _check_world_zones() -> int:
	var WorldScr: Script = load("res://scripts/game_world.gd") as Script
	if WorldScr == null:
		print("FAIL game_world load")
		return 1
	## ZONES is a var filled at ready — ensure script still has CITIES + dens builder.
	var src: = FileAccess.get_file_as_string("res://scripts/game_world.gd")
	if src.find("HellasMapData") < 0 or src.find("_build_dens") < 0:
		print("FAIL game_world not wired to HellasMapData dens")
		return 1
	if src.find("zones_for_spawns") < 0:
		print("FAIL game_world missing zones_for_spawns")
		return 1
	print("OK game_world dens wiring")
	return 0


func _check_hud_map() -> int:
	var src: = FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	if src.find("HellasMapData") < 0:
		print("FAIL hud missing HellasMapData")
		return 1
	if src.find("Open war") < 0 and src.find("open war") < 0:
		print("FAIL hud missing open-war copy")
		return 1
	if src.find("_add_map_war_roads") < 0:
		print("FAIL hud missing war roads")
		return 1
	if src.find("MAP_WORLD_SPAN: = 300.0") >= 0:
		print("FAIL hud still on old 300 span")
		return 1
	print("OK hud map capitals/dens/war")
	return 0


func _check_open_pvp() -> int:
	var PlayerScr: Script = load("res://scripts/player.gd") as Script
	if PlayerScr == null:
		print("FAIL player load")
		return 1
	var src: = FileAccess.get_file_as_string("res://scripts/player.gd")
	if src.find("func is_rival_player") < 0:
		print("FAIL missing is_rival_player")
		return 1
	if src.find("their_emp != empire_id()") < 0:
		print("FAIL rival rule not empire-based open PvP")
		return 1
	## Chronicle should advertise open war at empire pick.
	var chron: = FileAccess.get_file_as_string("res://scripts/ui/empire_map_view.gd")
	if chron.find("open war") < 0 and chron.find("Open war") < 0:
		print("FAIL empire chronicle missing open war")
		return 1
	print("OK open cross-empire PvP")
	return 0
