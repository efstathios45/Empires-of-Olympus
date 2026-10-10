extends SceneTree
## Headless checks: Melite chain to ~30 + high dens on the map.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	failed += _check_quests()
	failed += _check_dens()
	failed += _check_xp_band()
	if failed > 0:
		print("SMOKE FAIL: %d" % failed)
		quit(1)
	else:
		print("SMOKE_QUEST_CHAIN_OK")
		quit(0)


func _check_quests() -> int:
	var GS: Script = load("res://scripts/autoloads/game_state.gd") as Script
	if GS == null:
		print("FAIL game_state load")
		return 1
	var cmap: Dictionary = GS.get_script_constant_map()
	var quests: Array = cmap.get("QUESTS", [])
	if quests.size() < 14:
		print("FAIL quest chain too short", quests.size())
		return 1
	var ids: Dictionary = {}
	var total_xp: = 0
	for q in quests:
		ids[String(q["id"])] = true
		total_xp += int(q.get("reward_xp", 0))
	for need in ["wolves", "minotaur", "sirens", "lerna", "olympus"]:
		if not ids.has(need):
			print("FAIL missing quest", need)
			return 1
	## Olympus should be last.
	if String(quests[quests.size() - 1]["id"]) != "olympus":
		print("FAIL olympus not final")
		return 1
	print("OK quests=", quests.size(), " turn_in_xp=", total_xp)
	return 0


func _check_dens() -> int:
	var MapData = load("res://scripts/world/hellas_map_data.gd")
	if MapData == null:
		print("FAIL map data")
		return 1
	var need: = [
		"isthmus_shore", "serpent_hollow", "taygetus_ridge", "boreas_crags",
		"acheron_gate", "lerna_marsh", "ossa_foot", "olympus_approach",
	]
	var have: Dictionary = {}
	for d in MapData.DENS:
		have[String(d["id"])] = d
	for id in need:
		if not have.has(id):
			print("FAIL missing den", id)
			return 1
		var dp: Vector2 = have[id]["pos"]
		for c in MapData.CAPITALS:
			if dp.distance_to(c["pos"]) < 50.0:
				print("FAIL den too close to capital", id, c["name"])
				return 1
	## Lerna must include hydra.
	var lerna_ids: Array = have["lerna_marsh"]["ids"]
	if not lerna_ids.has("hydra_boss"):
		print("FAIL lerna missing hydra")
		return 1
	print("OK dens high-tier=", need.size(), " total=", MapData.DENS.size())
	return 0


func _check_xp_band() -> int:
	## Sum of turn-in XP should reach into the mid/high 20s when combined with kills.
	var GS: Script = load("res://scripts/autoloads/game_state.gd") as Script
	var quests: Array = GS.get_script_constant_map().get("QUESTS", [])
	var turn_xp: = 0
	for q in quests:
		turn_xp += int(q.get("reward_xp", 0))
	## xp_needed(L) = 60 + (L-1)*45 + (L-1)^2*6 — cumulative to reach level N.
	var cum: = 0
	var level: = 1
	while level < 30 and cum < turn_xp * 2:
		## Assume kills ≈ turn-in XP over the chain.
		cum += 60 + (level - 1) * 45 + (level - 1) * (level - 1) * 6
		level += 1
		if cum >= turn_xp + int(turn_xp * 0.85):
			break
	## With turn-in + ~equal kill XP, should clear at least level 22+.
	var kill_bonus: = int(turn_xp * 0.9)
	var total: = turn_xp + kill_bonus
	var lvl: = 1
	var pool: = total
	while lvl < 40:
		var need: = 60 + (lvl - 1) * 45 + (lvl - 1) * (lvl - 1) * 6
		if pool < need:
			break
		pool -= need
		lvl += 1
	if lvl < 22:
		print("FAIL chain XP too low for mid-20s, estimated level=", lvl, " total_xp=", total)
		return 1
	print("OK estimated level from chain rewards≈", lvl, " (turn_in=", turn_xp, ")")
	return 0
