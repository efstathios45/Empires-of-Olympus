extends Control
## Rest menu — controls, and the road back to the title.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const TEXT_W := 520

var hud: CanvasLayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(700, 620)
	center.add_child(panel)

	var margin := Kit.make_margin(34)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	v.add_child(Kit.make_label("Rest a Moment", 34, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.make_label("Ways of the Champion", 19, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.spacer(4))

	for line in [
			"WASD — move   •   Mouse — look",
			"Left click — strike   •   Right click — heavy blow",
			"Q — god-skill   •   F — raise shield   •   C — dodge roll",
			"Shift — sprint   •   Space — leap   •   E — speak / touch",
			"1 / 2 — health & spirit potions",
			"I — spoils   •   L — clan   •   M — map of Hellas"]:
		var l := Kit.make_label(String(line), 17, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(TEXT_W, 0)
		v.add_child(l)

	v.add_child(Kit.spacer(10))

	var resume := Kit.make_button("Return to Battle", true)
	resume.custom_minimum_size = Vector2(300, 64)
	resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume.pressed.connect(func() -> void: hud.close_panel_from_click())
	v.add_child(resume)

	var menu := Kit.make_button("Abandon the Hunt", false)
	menu.custom_minimum_size = Vector2(300, 62)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(_on_menu)
	v.add_child(menu)

func _on_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	LoadingScreen.preload_and_change_scene("res://scenes/ui/main_menu.tscn", 1.0)
