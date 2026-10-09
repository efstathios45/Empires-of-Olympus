extends SceneTree
## Headless checks: equal party split + world patch apply/sanitize.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	failed += _check_split()
	failed += _check_world_patch()
	failed += _check_mosaic_sanitize()
	failed += _check_spawn_gate()
	if failed > 0:
		print("SMOKE FAIL: %d check(s)" % failed)
		quit(1)
	else:
		print("SMOKE OK: party share + world patch")
		quit(0)


func _check_split() -> int:
	var ps = get_root().get_node_or_null("PartyShare")
	if ps == null:
		print("FAIL PartyShare missing")
		return 1
	var parts: Array = ps._split_int(101, 2)
	if parts.size() != 2 or int(parts[0]) + int(parts[1]) != 101:
		print("FAIL split sum", parts)
		return 1
	if abs(int(parts[0]) - int(parts[1])) > 1:
		print("FAIL split balance", parts)
		return 1
	## Equal parts are level-agnostic (no level in the splitter).
	var a: Array = ps._split_int(50, 2)
	if int(a[0]) != 25 or int(a[1]) != 25:
		print("FAIL even split", a)
		return 1
	print("OK split", parts)
	return 0


func _check_world_patch() -> int:
	var gs = get_root().get_node_or_null("GameState")
	if gs == null:
		print("FAIL GameState missing")
		return 1
	gs.mosaic_quest_stage = "none"
	gs.mosaic_tiles = PackedByteArray()
	gs.mosaic_rewarded = false
	gs.quest_index = 0
	gs.quest_kills = {}
	gs.apply_world_patch({
		"mosaic_quest_stage": "accepted",
	})
	if gs.mosaic_quest_stage != "accepted":
		print("FAIL patch accept stage", gs.mosaic_quest_stage)
		return 1
	gs.apply_world_patch({
		"quest_index": 2,
		"quest_kills": {},
	})
	if gs.quest_index != 2:
		print("FAIL patch quest_index", gs.quest_index)
		return 1
	print("OK world patch")
	return 0


func _check_mosaic_sanitize() -> int:
	var ns = get_root().get_node_or_null("NetSession")
	var gs = get_root().get_node_or_null("GameState")
	if ns == null or gs == null:
		print("FAIL NetSession/GameState missing")
		return 1
	gs.mosaic_quest_stage = "complete"
	gs.quest_index = 3
	var bad: Dictionary = ns._sanitize_world_patch({
		"mosaic_quest_stage": "none",
		"quest_index": 1,
	})
	if bad.has("mosaic_quest_stage"):
		print("FAIL sanitize allowed mosaic regress", bad)
		return 1
	if bad.has("quest_index"):
		print("FAIL sanitize allowed quest regress", bad)
		return 1
	var good: Dictionary = ns._sanitize_world_patch({
		"mosaic_quest_stage": "complete",
		"mosaic_rewarded": true,
		"quest_index": 4,
	})
	if not good.has("quest_index") or int(good["quest_index"]) != 4:
		print("FAIL sanitize advance", good)
		return 1
	print("OK sanitize")
	return 0


func _check_spawn_gate() -> int:
	var ns = get_root().get_node_or_null("NetSession")
	if ns == null:
		print("FAIL NetSession missing")
		return 1
	if not ns.has_method("should_spawn_world_mobs_locally"):
		print("FAIL missing should_spawn_world_mobs_locally")
		return 1
	if not ns.has_method("propose_world_patch"):
		print("FAIL missing propose_world_patch")
		return 1
	if not ns.has_method("distribute_party_rewards"):
		print("FAIL missing distribute_party_rewards")
		return 1
	## Solo offline: may spawn locally.
	if not ns.should_spawn_world_mobs_locally():
		print("FAIL solo should spawn locally")
		return 1
	ns.pending_join_address = "127.0.0.1"
	if ns.should_spawn_world_mobs_locally():
		print("FAIL pending join should not spawn")
		return 1
	ns.pending_join_address = ""
	print("OK spawn gate")
	return 0
