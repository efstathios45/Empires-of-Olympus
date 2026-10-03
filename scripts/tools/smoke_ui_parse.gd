extends SceneTree
func _init():
	call_deferred("_r")
func _r():
	for p in [
		"res://scripts/ui/main_menu.gd", 
		"res://scripts/ui/panel_inventory.gd", 
		"res://scripts/ui/panel_pause.gd", 
		"res://scripts/game_world.gd", 
		"res://scripts/autoloads/account_system.gd", 
	]:
		var s = load(p)
		print("LOAD ", p, " -> ", s != null)
	print("SMOKE_UI_PARSE_OK")
	quit(0)
