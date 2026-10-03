extends SceneTree


func _init() -> void :
	call_deferred("_run")

func _acc() -> Node:
	return get_root().get_node_or_null("AccountSystem")

func _gs() -> Node:
	return get_root().get_node_or_null("GameState")

func _run() -> void :
	var acc: = _acc()
	var gs: = _gs()
	print("ACC=", acc, " GS=", gs)
	if acc == null or gs == null:
		push_error("autoloads missing")
		quit(1)
		return
	var user: = "smoke_%d" % Time.get_unix_time_from_system()
	var password: = "testpass99"
	if not bool(acc.call("register", user, password, "SmokeHero")):
		push_error("register failed: %s" % acc.get("last_error"))
		quit(1)
		return
	gs.call("reset_run")
	gs.set("empire", "athens")
	gs.set("player_class", "toxotes")
	gs.set("level", 4)
	gs.set("gold", 777)
	gs.set("player_name", "SmokeHero")
	if not bool(acc.call("save_game", {"pos": {"x": 3.0, "y": 1.0, "z": -5.0}})):
		push_error("save failed: %s" % acc.get("last_error"))
		quit(1)
		return
	acc.call("logout")
	gs.call("reset_run")
	if not bool(acc.call("login", user, password)):
		push_error("login failed: %s" % acc.get("last_error"))
		quit(1)
		return
	if not bool(acc.call("load_game")):
		push_error("load failed: %s" % acc.get("last_error"))
		quit(1)
		return
	if String(gs.get("empire")) != "athens" or int(gs.get("level")) != 4 or int(gs.get("gold")) != 777:
		push_error("bad state empire=%s lvl=%s gold=%s" % [gs.get("empire"), gs.get("level"), gs.get("gold")])
		quit(1)
		return
	print("SMOKE_ACCOUNT_SAVE_OK user=", user, " gold=", gs.get("gold"))
	quit(0)
