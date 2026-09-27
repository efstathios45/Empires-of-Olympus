extends SceneTree
const Kit = preload("res://scripts/ui/ui_kit.gd")
func _init() -> void:
	call_deferred("_r")
func _r() -> void:
	var labels := [
		"Register","Sign In","Play Guest","Continue","New Game","Sign Out",
		"Back","Map","Enter","Close","Pledge","Choose","Save","Resume","Quit",
		"Equip","Sell","Unequip","Panoply","Clan","Complete","Farewell",
		"Leave","Use ×9","Buy 999","Continue",
	]
	var bad: Array = []
	for t in labels:
		if not Kit.button_text_fits(t):
			bad.append(t)
		var b := Kit.make_button(t, true)
		if b.custom_minimum_size != Kit.BTN_SIZE:
			bad.append("size:"+t)
		if b.get_theme_font_size("font_size") != Kit.BTN_FONT:
			bad.append("font:"+t)
	if bad.is_empty():
		print("SMOKE_BUTTON_FIT_OK size=", Kit.BTN_SIZE, " font=", Kit.BTN_FONT)
		quit(0)
	else:
		push_error("BAD %s" % str(bad))
		print("SMOKE_BUTTON_FIT_FAIL ", bad)
		quit(1)
