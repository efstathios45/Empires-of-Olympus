extends SceneTree
# Smoke: mosaic side-quest accept → paint → seal → floor texture + save roundtrip.

const MosaicArtScript = preload("res://scripts/mosaic_art.gd")

func _init() -> void:
	call_deferred("_run")


func _gs():
	return get_root().get_node_or_null("GameState")


func _run() -> void:
	var gs = _gs()
	if gs == null:
		print("FAIL GameState missing")
		quit(1)
		return
	var ok := true
	gs.mosaic_quest_stage = "none"
	gs.mosaic_tiles = PackedByteArray()
	gs.mosaic_rewarded = false
	gs.gold = 50
	gs.xp = 0

	if not bool(gs.accept_mosaic_quest()):
		print("FAIL accept")
		quit(1)
		return
	if String(gs.mosaic_quest_stage) != "accepted":
		print("FAIL stage after accept")
		ok = false

	gs.ensure_mosaic_tiles()
	var cx: int = int(MosaicArtScript.RES / 2)
	for y in MosaicArtScript.RES:
		for x in MosaicArtScript.RES:
			if not MosaicArtScript.in_circle(x, y):
				continue
			var dx: int = x - cx
			var dy: int = y - cx
			var d2: int = dx * dx + dy * dy
			if d2 > 140 and d2 < 190:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 3)
			elif abs(dx) <= 1 or abs(dy) <= 1:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 6)
			elif d2 < 40:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 1)

	var painted: int = MosaicArtScript.painted_count(gs.mosaic_tiles)
	print("painted=", painted)
	if painted < 24:
		print("FAIL too few painted")
		ok = false

	var gold0: int = int(gs.gold)
	var res: Dictionary = gs.seal_mosaic_artwork()
	if not bool(res.get("ok", false)) or not bool(res.get("first_reward", false)):
		print("FAIL seal ", res)
		ok = false
	if int(gs.gold) != gold0 + int(gs.MOSAIC_QUEST["reward_gold"]):
		print("FAIL gold reward got=", gs.gold)
		ok = false
	if String(gs.mosaic_quest_stage) != "complete":
		print("FAIL not complete")
		ok = false

	var tex = gs.mosaic_floor_texture()
	if tex == null:
		print("FAIL no floor texture")
		ok = false

	var saved: Dictionary = gs.to_save_dict()
	gs.mosaic_quest_stage = "none"
	gs.mosaic_tiles = PackedByteArray()
	gs.mosaic_rewarded = false
	if not bool(gs.apply_save_dict(saved)):
		print("FAIL apply_save")
		ok = false
	if String(gs.mosaic_quest_stage) != "complete" or not bool(gs.mosaic_rewarded):
		print("FAIL save stage")
		ok = false
	if MosaicArtScript.painted_count(gs.mosaic_tiles) != painted:
		print("FAIL save tiles")
		ok = false

	if MosaicArtScript.palette_count() < 12:
		print("FAIL palette small")
		ok = false
	var names := {}
	for e in MosaicArtScript.PALETTE:
		names[String(e["name"])] = true
	for need in ["Leukos", "Melas", "Erythros", "Kyaneos", "Glaukos", "Chryseos", "Porphyra"]:
		if not names.has(need):
			print("FAIL missing colour ", need)
			ok = false

	var g2: int = int(gs.gold)
	var res2: Dictionary = gs.seal_mosaic_artwork()
	if not bool(res2.get("ok", false)) or bool(res2.get("first_reward", true)):
		print("FAIL second seal ", res2)
		ok = false
	if int(gs.gold) != g2:
		print("FAIL double gold")
		ok = false

	if ok:
		print("SMOKE_MOSAIC_QUEST_OK")
		quit(0)
	else:
		print("SMOKE_MOSAIC_QUEST_FAIL")
		quit(1)
