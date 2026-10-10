extends SceneTree
## Headless checks: peer combat FX sync (skills/attacks) + mob hit feedback.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	failed += _check_remote_lock()
	failed += _check_net_rpcs()
	failed += _check_player_emits()
	failed += _check_proxy_hit()
	if failed > 0:
		print("SMOKE FAIL: %d" % failed)
		quit(1)
	else:
		print("SMOKE_COMBAT_FX_SYNC_OK")
		quit(0)


func _check_remote_lock() -> int:
	var src: = FileAccess.get_file_as_string("res://scripts/remote_avatar.gd")
	if src.find("_fx_lock") < 0:
		print("FAIL remote missing _fx_lock")
		return 1
	if src.find("play_combat_fx") < 0:
		print("FAIL remote missing play_combat_fx")
		return 1
	if src.find("_fx_lock <= 0.0") < 0 and src.find("_fx_lock <= 0") < 0:
		print("FAIL apply_state does not guard on fx lock")
		return 1
	print("OK remote fx lock")
	return 0


func _check_net_rpcs() -> int:
	var src: = FileAccess.get_file_as_string("res://scripts/autoloads/net_session.gd")
	if src.find("request_combat_fx") < 0 or src.find("_rpc_combat_fx") < 0:
		print("FAIL net_session missing combat fx RPC")
		return 1
	if src.find('hit_amount') < 0:
		print("FAIL mob hp sync missing hit_amount")
		return 1
	if src.find("apply_proxy_hit") < 0:
		print("FAIL mob hp sync does not call apply_proxy_hit")
		return 1
	## Must be reliable so casts are not dropped.
	if src.find('@rpc("any_peer", "reliable")') < 0:
		print("FAIL combat fx not reliable")
		return 1
	print("OK net combat RPCs")
	return 0


func _check_player_emits() -> int:
	var src: = FileAccess.get_file_as_string("res://scripts/player.gd")
	if src.find("request_combat_fx") < 0:
		print("FAIL player never emits combat fx")
		return 1
	if src.find("_start_attack(clip: String, duration: float, fx_alias") < 0 \
			and src.find("fx_alias: String") < 0:
		print("FAIL _start_attack missing fx_alias")
		return 1
	print("OK player combat emit")
	return 0


func _check_proxy_hit() -> int:
	var src: = FileAccess.get_file_as_string("res://scripts/enemy.gd")
	if src.find("func apply_proxy_hit") < 0:
		print("FAIL enemy missing apply_proxy_hit")
		return 1
	var EnemyScr: Script = load("res://scripts/enemy.gd") as Script
	if EnemyScr == null:
		print("FAIL enemy load")
		return 1
	var cmap: Dictionary = EnemyScr.get_script_constant_map()
	var configs: Dictionary = cmap.get("ENCODER", {}) ## wrong key guard
	configs = cmap.get("ENEMY_CONFIGS", {})
	for id in ["siren_enemy", "hydra_boss", "olympian_shade", "hellhound_enemy"]:
		if not configs.has(id):
			print("FAIL missing enemy config", id)
			return 1
	print("OK proxy hit + high-tier enemies")
	return 0
