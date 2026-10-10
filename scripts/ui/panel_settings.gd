extends Control


const Kit = preload("res://scripts/ui/ui_kit.gd")

signal closed

var _mode_btns: Dictionary = {}
var _res_option: OptionButton
var _vsync_btn: Button
var _fps_cap_btn: Button
var _quality_btn: Button
var _show_fps_btn: Button
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(Kit.make_dimmer())

	var center: = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel: = Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(640, 720)
	panel.clip_contents = true
	center.add_child(panel)

	var margin: = Kit.make_margin(18)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v)

	v.add_child(Kit.make_label("Video Settings", 28, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.make_label("Display, quality & frame rate", 15, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.spacer(4))

	v.add_child(Kit.make_label("Window mode", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var modes: = VBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	v.add_child(modes)
	for pair in [
		["windowed", "Windowed"],
		["fullscreen", "Fullscreen"],
		["borderless", "Borderless"],
	]:
		var b: = Kit.make_button(str(pair[1]), false)
		b.pressed.connect(_on_mode.bind(str(pair[0])))
		modes.add_child(b)
		_mode_btns[str(pair[0])] = b

	v.add_child(Kit.make_label("Resolution (windowed)", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_res_option = OptionButton.new()
	_res_option.custom_minimum_size = Vector2(280, 40)
	_res_option.add_theme_font_override("font", Kit.font())
	_res_option.add_theme_font_size_override("font_size", 16)
	_res_option.add_theme_color_override("font_color", Kit.INK)
	for r in DisplaySettings.RESOLUTIONS:
		_res_option.add_item(str(r["label"]))
		_res_option.set_item_metadata(_res_option.item_count - 1, str(r["id"]))
	_res_option.item_selected.connect(_on_res_selected)
	var res_wrap: = CenterContainer.new()
	res_wrap.add_child(_res_option)
	v.add_child(res_wrap)

	v.add_child(Kit.make_label("Performance", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_quality_btn = Kit.make_button("Quality: Balanced", false)
	_quality_btn.pressed.connect(_on_quality)
	v.add_child(_quality_btn)

	_vsync_btn = Kit.make_button("V-Sync: Off", false)
	_vsync_btn.pressed.connect(_on_vsync)
	v.add_child(_vsync_btn)

	_fps_cap_btn = Kit.make_button("Max FPS: Uncapped", false)
	_fps_cap_btn.pressed.connect(_on_fps_cap)
	v.add_child(_fps_cap_btn)

	_show_fps_btn = Kit.make_button("Show FPS: Off", false)
	_show_fps_btn.pressed.connect(_on_show_fps)
	v.add_child(_show_fps_btn)

	_status = Kit.make_label("", 14, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(420, 0)
	v.add_child(_status)

	var tip: = Kit.make_label(
		"Tip: leave V-Sync off and Max FPS uncapped so the GPU can work. Quality = Balanced is the default.",
		13, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(420, 0)
	v.add_child(tip)

	var apply_btn: = Kit.make_button("Apply", true)
	apply_btn.pressed.connect(_on_apply)
	v.add_child(apply_btn)

	var back: = Kit.make_button("Back", false)
	back.pressed.connect(_on_back)
	v.add_child(back)

	_refresh_ui()


func _refresh_ui() -> void:
	for id in _mode_btns:
		var b: Button = _mode_btns[id]
		b.modulate = Color(1.15, 1.08, 0.85) if id == DisplaySettings.window_mode else Color.WHITE
	for i in _res_option.item_count:
		if str(_res_option.get_item_metadata(i)) == DisplaySettings.resolution_id:
			_res_option.select(i)
			break
	_vsync_btn.text = "V-Sync: On" if DisplaySettings.vsync else "V-Sync: Off"
	_fps_cap_btn.text = "Max FPS: %s" % DisplaySettings.max_fps_label()
	_quality_btn.text = "Quality: %s" % DisplaySettings.quality_label()
	_show_fps_btn.text = "Show FPS: On" if DisplaySettings.show_fps else "Show FPS: Off"
	_status.text = "%s · %s · %s · %s" % [
		DisplaySettings.window_mode.capitalize(),
		DisplaySettings.resolution_label(),
		DisplaySettings.quality_label(),
		DisplaySettings.max_fps_label(),
	]


func _on_mode(mode: String) -> void:
	DisplaySettings.window_mode = mode
	_refresh_ui()


func _on_res_selected(idx: int) -> void:
	DisplaySettings.resolution_id = str(_res_option.get_item_metadata(idx))
	_refresh_ui()


func _on_vsync() -> void:
	DisplaySettings.vsync = not DisplaySettings.vsync
	_refresh_ui()


func _on_fps_cap() -> void:
	DisplaySettings.cycle_max_fps()
	_refresh_ui()


func _on_quality() -> void:
	DisplaySettings.cycle_quality()
	_refresh_ui()


func _on_show_fps() -> void:
	DisplaySettings.show_fps = not DisplaySettings.show_fps
	_refresh_ui()


func _on_apply() -> void:
	DisplaySettings.apply()
	_refresh_ui()
	_status.text = "Applied — %s · %s · %s · %s" % [
		DisplaySettings.window_mode.capitalize(),
		DisplaySettings.resolution_label(),
		DisplaySettings.quality_label(),
		DisplaySettings.max_fps_label(),
	]
	AudioManager.play_sfx("ui_confirm")


func _on_back() -> void:
	closed.emit()
	queue_free()
