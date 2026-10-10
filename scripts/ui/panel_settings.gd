extends Control
## Dedicated Video Settings: renderer, FPS cap, quality, shadows, grass.


const Kit = preload("res://scripts/ui/ui_kit.gd")

signal closed

var _mode_btns: Dictionary = {}
var _res_option: OptionButton
var _quality_option: OptionButton
var _fps_option: OptionButton
var _shadow_option: OptionButton
var _grass_option: OptionButton
var _vsync_btn: Button
var _show_fps_btn: Button
var _renderer_lbl: Label
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
	panel.custom_minimum_size = Vector2(680, 760)
	panel.clip_contents = true
	center.add_child(panel)

	var margin: = Kit.make_margin(16)
	panel.add_child(margin)

	var outer: = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	outer.add_child(Kit.make_label("Video Settings", 28, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	_renderer_lbl = Kit.make_label("Renderer: …", 14, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_renderer_lbl)
	outer.add_child(Kit.make_label(
		"Tune these for a smooth 144 FPS. Vulkan Forward+ stays on.",
		14, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	## Give the VBox a width so labels wrap inside the scroll.
	v.custom_minimum_size = Vector2(620, 0)

	v.add_child(Kit.make_label("Window mode", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var modes: = HBoxContainer.new()
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	modes.add_theme_constant_override("separation", 8)
	v.add_child(modes)
	for pair in [
		["windowed", "Windowed"],
		["fullscreen", "Fullscreen"],
		["borderless", "Borderless"],
	]:
		var b: = Kit.make_button(str(pair[1]), false)
		b.custom_minimum_size = Vector2(150, 40)
		b.pressed.connect(_on_mode.bind(str(pair[0])))
		modes.add_child(b)
		_mode_btns[str(pair[0])] = b

	v.add_child(Kit.make_label("Resolution (windowed)", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_res_option = _make_option()
	for r in DisplaySettings.RESOLUTIONS:
		_res_option.add_item(str(r["label"]))
		_res_option.set_item_metadata(_res_option.item_count - 1, str(r["id"]))
	_res_option.item_selected.connect(_on_res_selected)
	v.add_child(_wrap_center(_res_option))

	v.add_child(Kit.make_label("Frame rate", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_fps_option = _make_option()
	for fps in DisplaySettings.MAX_FPS_OPTIONS:
		var label: = "Unlimited" if int(fps) <= 0 else "%d FPS" % int(fps)
		_fps_option.add_item(label)
		_fps_option.set_item_metadata(_fps_option.item_count - 1, int(fps))
	_fps_option.item_selected.connect(_on_fps_selected)
	v.add_child(_wrap_center(_fps_option))

	_vsync_btn = Kit.make_button("V-Sync: Off", false)
	_vsync_btn.pressed.connect(_on_vsync)
	v.add_child(_vsync_btn)

	_show_fps_btn = Kit.make_button("Show FPS: On", false)
	_show_fps_btn.pressed.connect(_on_show_fps)
	v.add_child(_show_fps_btn)

	v.add_child(Kit.make_label("Graphics quality", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_quality_option = _make_option()
	for key in ["performance", "balanced", "quality"]:
		var preset: Dictionary = DisplaySettings.QUALITY_PRESETS[key]
		_quality_option.add_item(String(preset.get("label", key)))
		_quality_option.set_item_metadata(_quality_option.item_count - 1, key)
	_quality_option.item_selected.connect(_on_quality_selected)
	v.add_child(_wrap_center(_quality_option))

	v.add_child(Kit.make_label("Shadows", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_shadow_option = _make_option()
	for pair in [["preset", "Follow quality"], ["low", "Low"], ["med", "Medium"], ["high", "High"]]:
		_shadow_option.add_item(str(pair[1]))
		_shadow_option.set_item_metadata(_shadow_option.item_count - 1, str(pair[0]))
	_shadow_option.item_selected.connect(_on_shadow_selected)
	v.add_child(_wrap_center(_shadow_option))

	v.add_child(Kit.make_label("Grass density", 16, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_grass_option = _make_option()
	for pair in [["preset", "Follow quality"], ["low", "Low"], ["med", "Medium"], ["high", "High"]]:
		_grass_option.add_item(str(pair[1]))
		_grass_option.set_item_metadata(_grass_option.item_count - 1, str(pair[0]))
	_grass_option.item_selected.connect(_on_grass_selected)
	v.add_child(_wrap_center(_grass_option))

	_status = Kit.make_label("", 13, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(560, 0)
	v.add_child(_status)

	var tip: = Kit.make_label(
		"Tip: Max FPS 144 + V-Sync Off is the smooth default. If you lag, set Quality → Performance and Grass → Low. Ancient GPUs: launch with --rendering-method gl_compatibility.",
		12, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(560, 0)
	v.add_child(tip)

	var apply_btn: = Kit.make_button("Apply", true)
	apply_btn.pressed.connect(_on_apply)
	outer.add_child(apply_btn)

	var back: = Kit.make_button("Back", false)
	back.pressed.connect(_on_back)
	outer.add_child(back)

	_refresh_ui()


func _make_option() -> OptionButton:
	var ob: = OptionButton.new()
	ob.custom_minimum_size = Vector2(300, 40)
	ob.add_theme_font_override("font", Kit.font())
	ob.add_theme_font_size_override("font_size", 16)
	ob.add_theme_color_override("font_color", Kit.INK)
	return ob


func _wrap_center(ctrl: Control) -> CenterContainer:
	var wrap: = CenterContainer.new()
	wrap.add_child(ctrl)
	return wrap


func _select_meta(ob: OptionButton, meta) -> void:
	for i in ob.item_count:
		if ob.get_item_metadata(i) == meta:
			ob.select(i)
			return


func _refresh_ui() -> void:
	_renderer_lbl.text = "Renderer: %s" % DisplaySettings.renderer_label()
	for id in _mode_btns:
		var b: Button = _mode_btns[id]
		b.modulate = Color(1.15, 1.08, 0.85) if id == DisplaySettings.window_mode else Color.WHITE
	_select_meta(_res_option, DisplaySettings.resolution_id)
	_select_meta(_fps_option, DisplaySettings.max_fps)
	_select_meta(_quality_option, DisplaySettings.quality)
	_select_meta(_shadow_option, DisplaySettings.shadow_override)
	_select_meta(_grass_option, DisplaySettings.grass_override)
	_vsync_btn.text = "V-Sync: On" if DisplaySettings.vsync else "V-Sync: Off"
	_show_fps_btn.text = "Show FPS: On" if DisplaySettings.show_fps else "Show FPS: Off"
	_status.text = "%s · %s · %s · Shadows %s · Grass %s" % [
		DisplaySettings.quality_label(),
		DisplaySettings.max_fps_label(),
		"V-Sync On" if DisplaySettings.vsync else "V-Sync Off",
		DisplaySettings.shadow_label(),
		DisplaySettings.grass_label(),
	]


func _on_mode(mode: String) -> void:
	DisplaySettings.window_mode = mode
	_refresh_ui()


func _on_res_selected(idx: int) -> void:
	DisplaySettings.resolution_id = str(_res_option.get_item_metadata(idx))
	_refresh_ui()


func _on_fps_selected(idx: int) -> void:
	DisplaySettings.set_max_fps(int(_fps_option.get_item_metadata(idx)))
	_refresh_ui()


func _on_quality_selected(idx: int) -> void:
	DisplaySettings.set_quality(str(_quality_option.get_item_metadata(idx)))
	_refresh_ui()


func _on_shadow_selected(idx: int) -> void:
	DisplaySettings.set_shadow_override(str(_shadow_option.get_item_metadata(idx)))
	_refresh_ui()


func _on_grass_selected(idx: int) -> void:
	DisplaySettings.set_grass_override(str(_grass_option.get_item_metadata(idx)))
	_refresh_ui()


func _on_vsync() -> void:
	DisplaySettings.vsync = not DisplaySettings.vsync
	_refresh_ui()


func _on_show_fps() -> void:
	DisplaySettings.show_fps = not DisplaySettings.show_fps
	_refresh_ui()


func _on_apply() -> void:
	DisplaySettings.apply()
	_refresh_ui()
	_status.text = "Applied — %s · %s · %s" % [
		DisplaySettings.renderer_label(),
		DisplaySettings.max_fps_label(),
		DisplaySettings.quality_label(),
	]
	AudioManager.play_sfx("ui_confirm")


func _on_back() -> void:
	closed.emit()
	queue_free()
