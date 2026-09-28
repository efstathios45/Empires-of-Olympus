extends SceneTree
## Headless: item tooltips, party XP split, display settings round-trip.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs := get_root().get_node_or_null("GameState")
	if gs == null:
		push_error("GameState missing")
		quit(1)
		return
	var tip: String = str(gs.call("item_tooltip_text", "leather_boots"))
	if tip.find("Leather") < 0 and tip.find("Sandals") < 0:
		push_error("tooltip missing name: " + tip)
		quit(1)
		return
	if tip.find("ATK") < 0 and tip.find("DEF") < 0 and tip.find("HP") < 0:
		push_error("tooltip missing bonus: " + tip)
		quit(1)
		return

	var ps := get_root().get_node_or_null("PartyShare")
	if ps == null:
		push_error("PartyShare missing")
		quit(1)
		return
	var target := Node.new()
	get_root().add_child(target)
	var p1 := Node.new()
	p1.add_to_group("player")
	get_root().add_child(p1)
	var p2 := Node.new()
	p2.add_to_group("player")
	get_root().add_child(p2)
	ps.call("note", target, p1)
	ps.call("note", target, p2)
	var before_xp: int = int(gs.get("xp"))
	var before_gold: int = int(gs.get("gold"))
	ps.call("award_xp_and_gold", target, 100, 50)
	var after_xp: int = int(gs.get("xp"))
	var after_gold: int = int(gs.get("gold"))
	if after_xp - before_xp != 50:
		push_error("xp share expected 50 got %d" % (after_xp - before_xp))
		quit(1)
		return
	if after_gold - before_gold != 25:
		push_error("gold share expected 25 got %d" % (after_gold - before_gold))
		quit(1)
		return

	var ds := get_root().get_node_or_null("DisplaySettings")
	if ds == null:
		push_error("DisplaySettings missing")
		quit(1)
		return
	ds.set("window_mode", "windowed")
	ds.set("resolution_id", "1280x720")
	ds.call("save_settings")
	ds.call("load_settings")
	if str(ds.get("resolution_id")) != "1280x720":
		push_error("display settings persist failed")
		quit(1)
		return

	if load("res://scripts/ui/panel_inventory.gd") == null:
		push_error("panel_inventory failed")
		quit(1)
		return
	if load("res://scripts/ui/panel_settings.gd") == null:
		push_error("panel_settings failed")
		quit(1)
		return

	print("SMOKE_PANOPLY_SHARE_SETTINGS_OK tip_len=", tip.length())
	quit(0)
