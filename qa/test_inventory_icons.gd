extends SceneTree
## Verify every ITEM_DEFS icon path loads as a Texture2D.
## Run: godot --headless --path . --script res://qa/test_inventory_icons.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var GS = load("res://scripts/autoloads/game_state.gd").new()
	root.add_child(GS)
	await process_frame
	var failed := 0
	failed += _test_item_icon_paths(GS)
	failed += _test_ui_fallbacks()
	failed += _test_panel_compiles()
	if failed == 0:
		print("INVENTORY_ICONS_OK")
		quit(0)
	else:
		print("INVENTORY_ICONS_FAIL count=", failed)
		quit(1)


func _test_item_icon_paths(GS) -> int:
	var fails := 0
	var checked := 0
	for id in GS.ITEM_DEFS.keys():
		var def: Dictionary = GS.ITEM_DEFS[id]
		var path := str(def.get("icon", ""))
		if path == "":
			print("FAIL missing icon for ", id)
			fails += 1
			continue
		if not ResourceLoader.exists(path):
			print("FAIL icon missing on disk ", id, " -> ", path)
			fails += 1
			continue
		var tex = load(path)
		if tex == null or not (tex is Texture2D):
			print("FAIL icon failed to load ", id, " -> ", path)
			fails += 1
			continue
		checked += 1
		print("ICON OK ", id, " ", path.get_file())
	if checked < 10:
		print("FAIL too few icons checked ", checked)
		fails += 1
	return fails


func _test_ui_fallbacks() -> int:
	var fails := 0
	for name in ["icon_sword", "icon_shield", "icon_potion", "icon_scroll", "icon_boot", "icon_anvil", "icon_laurel"]:
		var path := "res://assets/ui/%s.png" % name
		if not ResourceLoader.exists(path):
			print("FAIL fallback ui icon ", name)
			fails += 1
	return fails


func _test_panel_compiles() -> int:
	var pan = load("res://scripts/ui/panel_inventory.gd")
	if pan == null:
		print("FAIL panel_inventory.gd failed to compile")
		return 1
	print("PANEL script OK")
	return 0
