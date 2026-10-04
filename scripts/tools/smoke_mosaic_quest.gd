extends SceneTree
# Smoke: Psifidoto accept → paint denser circle → save progress → seal → save roundtrip.

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

	if MosaicArtScript.RES < 50 or MosaicArtScript.SEAL_MIN < 48:
		print("FAIL denser grid expected RES>=50 SEAL_MIN>=48 got ", MosaicArtScript.RES, " ", MosaicArtScript.SEAL_MIN)
		ok = false

	if not bool(gs.accept_mosaic_quest()):
		print("FAIL accept")
		quit(1)
		return

	gs.ensure_mosaic_tiles()
	if gs.mosaic_tiles.size() != MosaicArtScript.RES * MosaicArtScript.RES:
		print("FAIL tile size ", gs.mosaic_tiles.size())
		ok = false

	# Paint a ring + cross so we exceed SEAL_MIN.
	var cx: int = int(MosaicArtScript.RES / 2)
	for y in MosaicArtScript.RES:
		for x in MosaicArtScript.RES:
			if not MosaicArtScript.in_circle(x, y):
				continue
			var dx: int = x - cx
			var dy: int = y - cx
			var d2: int = dx * dx + dy * dy
			if d2 > 280 and d2 < 380:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 3)
			elif abs(dx) <= 1 or abs(dy) <= 1:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 6)
			elif d2 < 80:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 1)

	var painted: int = MosaicArtScript.painted_count(gs.mosaic_tiles)
	print("painted=", painted, " seal_min=", MosaicArtScript.SEAL_MIN, " capacity=", MosaicArtScript.circle_capacity())
	if painted < MosaicArtScript.SEAL_MIN:
		print("FAIL too few painted for seal")
		ok = false

	# Save & continue path
	if not bool(gs.save_mosaic_progress(gs.mosaic_tiles)):
		print("FAIL save progress")
		ok = false
	var mid: int = MosaicArtScript.painted_count(gs.mosaic_tiles)

	var title: String = String(gs.MOSAIC_QUEST["title"])
	if not title.begins_with("Psifidoto"):
		print("FAIL title should be Greeklish Psifidoto: ", title)
		ok = false
	var brief: String = String(gs.MOSAIC_QUEST["brief"])
	if "forever" not in brief.to_lower():
		print("FAIL brief should mention forever")
		ok = false
	if "ψιφιδωτό" in brief or "Ψιφιδωτό" in brief or "ψιφιδωτό" in title:
		print("FAIL still has Greek letters")
		ok = false

	var gold0: int = int(gs.gold)
	var res: Dictionary = gs.seal_mosaic_artwork()
	if not bool(res.get("ok", false)) or not bool(res.get("first_reward", false)):
		print("FAIL seal ", res)
		ok = false
	if int(gs.gold) != gold0 + int(gs.MOSAIC_QUEST["reward_gold"]):
		print("FAIL gold reward")
		ok = false

	# Too-sparse rejection
	var sparse = MosaicArtScript.empty_tiles()
	MosaicArtScript.set_tile(sparse, cx, cx, 1)
	gs.mosaic_tiles = sparse
	gs.mosaic_quest_stage = "accepted"
	gs.mosaic_rewarded = false
	var bad: Dictionary = gs.seal_mosaic_artwork()
	if bool(bad.get("ok", true)) or String(bad.get("reason", "")) != "too_sparse":
		print("FAIL sparse seal should fail ", bad)
		ok = false

	# Restore sealed state for save roundtrip
	gs.mosaic_quest_stage = "complete"
	gs.mosaic_rewarded = true
	# rebuild painted emblem
	gs.mosaic_tiles = MosaicArtScript.empty_tiles()
	for y in MosaicArtScript.RES:
		for x in MosaicArtScript.RES:
			if not MosaicArtScript.in_circle(x, y):
				continue
			var dx2: int = x - cx
			var dy2: int = y - cx
			var d22: int = dx2 * dx2 + dy2 * dy2
			if d22 > 280 and d22 < 380:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 3)
			elif abs(dx2) <= 1 or abs(dy2) <= 1:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 6)
			elif d22 < 80:
				MosaicArtScript.set_tile(gs.mosaic_tiles, x, y, 1)
	painted = MosaicArtScript.painted_count(gs.mosaic_tiles)

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
		print("FAIL save tiles got=", MosaicArtScript.painted_count(gs.mosaic_tiles), " want=", painted)
		ok = false

	# Migrate old 40×40 blob
	var old := PackedByteArray()
	old.resize(40 * 40)
	old.fill(0)
	old[20 * 40 + 20] = 3
	var migrated = MosaicArtScript.ensure_tiles(old)
	if migrated.size() != MosaicArtScript.RES * MosaicArtScript.RES:
		print("FAIL migrate size")
		ok = false
	elif MosaicArtScript.painted_count(migrated) < 1:
		print("FAIL migrate lost tiles")
		ok = false

	if mid < MosaicArtScript.SEAL_MIN:
		print("FAIL mid progress")
		ok = false

	if ok:
		print("SMOKE_MOSAIC_QUEST_OK")
		quit(0)
	else:
		print("SMOKE_MOSAIC_QUEST_FAIL")
		quit(1)
