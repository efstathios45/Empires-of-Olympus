extends Control
## Agora Psifidoto quest + fullscreen circular tessera painter.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const DIALOG_W: = 820
const DIALOG_H: = 520
## Fullscreen paint board (square takes most of the viewport height).
const BOARD_PX: = 640

enum Mode {OFFER, START, PAINT}

var hud: CanvasLayer
var speaker_name: String = "Old Myrrine"

var _mode: int = Mode.OFFER
var _dialog_shell: Control
var _paint_shell: Control
var _body: VBoxContainer
var _quote: Label
var _title: Label
var _brief: Label
var _status: Label
var _forever: Label
var _action_row: HBoxContainer
var _paint_status: Label
var _paint_result: Label
var _paint_actions: HBoxContainer

var _board: Control
var _palette_box: VBoxContainer
var _selected: int = 1
var _brush: int = 0
var _painting: bool = false
var _draft: PackedByteArray = PackedByteArray()
var _swatch_buttons: Array = []
var _result: Label
var _cell_draw: float = float(BOARD_PX) / float(MosaicArt.RES)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_dialog_shell()
	_build_paint_shell()
	_resolve_mode()
	_refresh()


func _build_dialog_shell() -> void:
	_dialog_shell = Control.new()
	_dialog_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dialog_shell)
	_dialog_shell.add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog_shell.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(DIALOG_W, DIALOG_H)
	center.add_child(panel)

	var margin := Kit.make_margin(18)
	panel.add_child(margin)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	margin.add_child(_body)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	_body.add_child(head)
	head.add_child(Kit.make_icon("icon_laurel", 36))
	head.add_child(Kit.make_label(speaker_name, 28, Kit.INK_TITLE))

	_quote = Kit.make_label("", 16, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote.custom_minimum_size = Vector2(DIALOG_W - 80, 0)
	_body.add_child(_quote)
	_body.add_child(_divider(DIALOG_W - 80))

	_title = Kit.make_label("", 24, Kit.INK_TITLE)
	_body.add_child(_title)
	_brief = Kit.make_label("", 17, Kit.INK)
	_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_brief.custom_minimum_size = Vector2(DIALOG_W - 80, 0)
	_brief.add_theme_constant_override("line_spacing", 6)
	_body.add_child(_brief)

	_status = Kit.make_label("", 16, Kit.INK_GOLD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(DIALOG_W - 80, 0)
	_body.add_child(_status)

	_forever = Kit.make_label(
		"Your Psifidoto will stay on this square forever — for your eyes, on your save.",
		15, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_forever.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_forever.custom_minimum_size = Vector2(DIALOG_W - 80, 0)
	_body.add_child(_forever)

	_result = Kit.make_label("", 16, Kit.INK_GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	_body.add_child(_result)

	_action_row = HBoxContainer.new()
	_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_row.add_theme_constant_override("separation", 16)
	_body.add_child(_action_row)


func _build_paint_shell() -> void:
	_paint_shell = Control.new()
	_paint_shell.visible = false
	_paint_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_paint_shell)

	# Deep temple dusk behind the work.
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.04, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_paint_shell.add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_bottom", 14)
	_paint_shell.add_child(root)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	root.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	top.add_child(Kit.make_icon("icon_laurel", 32))
	var top_title := Kit.make_hud_label("Psifidoto of the Agora — fullscreen", 26, Color(0.97, 0.92, 0.78))
	top_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_title)

	_paint_status = Kit.make_hud_label("", 18, Color(1.0, 0.88, 0.55))
	v.add_child(_paint_status)
	var hint := Kit.make_hud_label(
		"Hand-laid tesserae · Save & leave anytime · Sealed art stays on this square forever",
		15, Color(0.85, 0.80, 0.70))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 18)
	v.add_child(mid)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	mid.add_child(left)

	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.14, 0.10, 0.85)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.72, 0.58, 0.28, 0.95)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	frame.add_theme_stylebox_override("panel", sb)
	left.add_child(frame)

	_board = Control.new()
	_board.custom_minimum_size = Vector2(BOARD_PX, BOARD_PX)
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_on_board_input)
	frame.add_child(_board)

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 10)
	left.add_child(tools)
	tools.add_child(_tool_btn("Fine", func() -> void: _brush = 0))
	tools.add_child(_tool_btn("Broad", func() -> void: _brush = 1))
	tools.add_child(_tool_btn("Scrape", func() -> void: _selected = MosaicArt.EMPTY))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	mid.add_child(right)
	right.add_child(Kit.make_hud_label("Tessera colours", 22, Color(0.97, 0.92, 0.78)))
	right.add_child(Kit.make_hud_label("Named as the poets spoke them", 14, Color(0.8, 0.75, 0.65)))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(360, 420)
	right.add_child(scroll)
	_palette_box = VBoxContainer.new()
	_palette_box.add_theme_constant_override("separation", 4)
	_palette_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_palette_box)
	_fill_palette()

	_paint_result = Kit.make_hud_label("", 17, Color(0.7, 0.95, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_paint_result)

	_paint_actions = HBoxContainer.new()
	_paint_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_paint_actions.add_theme_constant_override("separation", 14)
	v.add_child(_paint_actions)


func _fill_palette() -> void:
	_swatch_buttons.clear()
	for i in MosaicArt.PALETTE.size():
		var entry: Dictionary = MosaicArt.PALETTE[i]
		var idx: = i + 1
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(340, 38)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text = "  %s — %s" % [entry["name"], entry["gloss"]]
		row.add_theme_font_override("font", Kit.font())
		row.add_theme_font_size_override("font_size", 14)
		var style := StyleBoxFlat.new()
		style.bg_color = entry["color"]
		style.set_border_width_all(2)
		style.border_color = Color(0.2, 0.15, 0.1, 0.55)
		style.set_corner_radius_all(4)
		style.content_margin_left = 8
		for st in ["normal", "hover", "pressed", "focus"]:
			row.add_theme_stylebox_override(st, style)
		var lum: = float(entry["color"].r * 0.3 + entry["color"].g * 0.59 + entry["color"].b * 0.11)
		var ink: = Kit.INK if lum > 0.45 else Color(0.96, 0.93, 0.86)
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			row.add_theme_color_override(st, ink)
		row.pressed.connect(_select_color.bind(idx))
		_palette_box.add_child(row)
		_swatch_buttons.append(row)


func _divider(w: float) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.42, 0.32, 0.14, 0.3)
	d.custom_minimum_size = Vector2(w, 2)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


func _resolve_mode() -> void:
	var stage := GameState.mosaic_quest_stage
	if stage == "none":
		_mode = Mode.OFFER
	elif stage == "accepted":
		_mode = Mode.START
	else:
		_mode = Mode.PAINT


func _refresh() -> void:
	_clear_actions(_action_row)
	_clear_actions(_paint_actions)
	_result.text = ""
	_paint_result.text = ""
	GameState.ensure_mosaic_tiles()
	_draft = GameState.mosaic_tiles.duplicate()
	_cell_draw = float(BOARD_PX) / float(MosaicArt.RES)

	var painting: = (_mode == Mode.PAINT)
	_dialog_shell.visible = not painting
	_paint_shell.visible = painting

	match _mode:
		Mode.OFFER:
			_quote.text = _offer_quote()
			_title.text = String(GameState.MOSAIC_QUEST["title"])
			_brief.text = String(GameState.MOSAIC_QUEST["brief"])
			_status.text = "Reward: %d gold  •  %d glory" % [
				GameState.MOSAIC_QUEST["reward_gold"], GameState.MOSAIC_QUEST["reward_xp"],
			]
			_forever.text = "Your Psifidoto will stay on this square forever — for you, on your save."
			_add_btn(_action_row, "Accept", true, _on_accept)
			_add_btn(_action_row, "Not yet", false, func() -> void: hud.close_panel_from_click())
		Mode.START:
			var painted: = MosaicArt.painted_count(_draft)
			_quote.text = _start_quote(painted > 0)
			_title.text = String(GameState.MOSAIC_QUEST["title"])
			if painted > 0:
				_brief.text = "Continue your Psifidoto where you left off?"
				_status.text = "%d tesserae already laid (need %d to seal). Progress is saved." % [
					painted, MosaicArt.SEAL_MIN,
				]
				_add_btn(_action_row, "Continue", true, _on_begin_paint)
			else:
				_brief.text = "Do you want to start now?"
				_status.text = "Fullscreen the square, lay tesserae by hand, save anytime, seal when ready."
				_add_btn(_action_row, "Yes — begin", true, _on_begin_paint)
			_forever.text = "Leave and return whenever you like — the Psifidoto waits on this square forever."
			_add_btn(_action_row, "Later", false, func() -> void: hud.close_panel_from_click())
		Mode.PAINT:
			_paint_status.text = _status_line()
			_board.queue_redraw()
			_sync_swatches()
			_add_btn(_paint_actions, "Seal artwork", true, _on_seal)
			_add_btn(_paint_actions, "Save & leave", true, _on_save_leave)
			_add_btn(_paint_actions, "Clear", false, _on_clear)
			_add_btn(_paint_actions, "Back", false, _on_back)


func _status_line() -> String:
	var n: = MosaicArt.painted_count(_draft)
	return "Tesserae laid by hand: %d  ·  seal needs %d  ·  your Psifidoto stays here forever" % [
		n, MosaicArt.SEAL_MIN,
	]


func _offer_quote() -> String:
	match speaker_name:
		"Thalia":
			return "\"The priestess speaks of omens — I speak of beauty. Restore the Psifidoto, and the agora will smile again.\""
		"Eirene":
			return "\"Athena watches this fountain. Offer her a Psifidoto of Leukos, Kyaneos, Chryseos — stone by stone.\""
		_:
			return "\"Child, the square once glittered. Will you set the Psifidoto anew, tessera by tessera?\""


func _start_quote(continuing: bool) -> String:
	if continuing:
		match speaker_name:
			"Thalia":
				return "\"Ah — your pebbles still wait. Continue when you are ready.\""
			"Eirene":
				return "\"Blessed be your return. Shall we continue the Psifidoto?\""
			_:
				return "\"The mortar is not yet dry. Continue your Psifidoto?\""
	match speaker_name:
		"Thalia":
			return "\"Good. The pebbles are waiting by the fountain — shall we begin?\""
		"Eirene":
			return "\"Blessed be your hands. Do you want to start now?\""
		_:
			return "\"The pebbles wait. Athena's court is watching. Do you want to start now?\""


func _clear_actions(row: HBoxContainer) -> void:
	if row == null:
		return
	for c in row.get_children():
		c.queue_free()


func _add_btn(row: HBoxContainer, text: String, primary: bool, cb: Callable) -> void:
	var b := Kit.make_button(text, primary)
	b.pressed.connect(cb)
	row.add_child(b)


func _tool_btn(text: String, cb: Callable) -> Button:
	var b := Kit.make_button(text, false)
	b.custom_minimum_size = Vector2(120, 48)
	b.pressed.connect(cb)
	return b


func _on_accept() -> void:
	if GameState.accept_mosaic_quest():
		AudioManager.play_sfx("ui_click")
		_mode = Mode.START
		_refresh()


func _on_begin_paint() -> void:
	_mode = Mode.PAINT
	_refresh()


func _on_back() -> void:
	_commit_draft(false)
	if GameState.mosaic_quest_stage == "complete":
		hud.close_panel_from_click()
	else:
		_mode = Mode.START
		_refresh()


func _on_clear() -> void:
	MosaicArt.clear_circle(_draft)
	_paint_status.text = _status_line()
	_board.queue_redraw()


func _commit_draft(persist_account: bool) -> void:
	GameState.mosaic_tiles = _draft
	if persist_account:
		GameState.save_mosaic_progress(_draft)
	else:
		GameState.mosaic_changed.emit()


func _on_save_leave() -> void:
	_commit_draft(true)
	AudioManager.play_sfx("ui_click")
	_paint_result.text = "Saved. Your Psifidoto stays on this square forever — return anytime to continue."
	_paint_result.add_theme_color_override("font_color", Color(0.75, 0.95, 0.7))
	await get_tree().create_timer(0.55).timeout
	if is_instance_valid(hud):
		hud.close_panel_from_click()


func _on_seal() -> void:
	_commit_draft(false)
	var res: Dictionary = GameState.seal_mosaic_artwork()
	if not bool(res.get("ok", false)):
		if String(res.get("reason", "")) == "too_sparse":
			_paint_result.text = "Lay at least %d tesserae by hand before sealing." % MosaicArt.SEAL_MIN
			_paint_result.add_theme_color_override("font_color", Color(1.0, 0.7, 0.55))
		return
	AudioManager.play_sfx("quest_complete")
	if bool(res.get("first_reward", false)):
		_paint_result.text = "Sealed forever! +%d gold, +%d glory — your Psifidoto remains on this square." % [
			int(res.get("gold", 0)), int(res.get("xp", 0)),
		]
	else:
		_paint_result.text = "Sealed anew — your Psifidoto still stays here forever."
	_paint_result.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
	_paint_status.text = _status_line()
	var worlds := get_tree().get_nodes_in_group("game_world")
	if worlds.size() > 0 and worlds[0].has_method("apply_player_mosaic"):
		worlds[0].call("apply_player_mosaic")


func _select_color(idx: int) -> void:
	_selected = idx
	_sync_swatches()


func _sync_swatches() -> void:
	for i in _swatch_buttons.size():
		var btn: Button = _swatch_buttons[i]
		btn.modulate = Color(1.15, 1.1, 0.95) if (_selected == i + 1) else Color.WHITE


func _draw_board() -> void:
	var cx: = BOARD_PX * 0.5
	var cy: = BOARD_PX * 0.5
	var radius: = BOARD_PX * 0.5 - 2.0
	# Outer bronze ring — ancient craft frame.
	_board.draw_circle(Vector2(cx, cy), radius + 6.0, Color(0.42, 0.30, 0.14, 1.0))
	_board.draw_circle(Vector2(cx, cy), radius + 2.0, Color(0.72, 0.58, 0.28, 0.95))
	_board.draw_circle(Vector2(cx, cy), radius, Color(0.70, 0.62, 0.50))
	for y in MosaicArt.RES:
		for x in MosaicArt.RES:
			if not MosaicArt.in_circle(x, y):
				continue
			var idx: = int(_draft[MosaicArt.index_of(x, y)])
			var col: = MosaicArt.color_at(idx) if idx != MosaicArt.EMPTY else MosaicArt.UNDERLAY
			var r := Rect2(x * _cell_draw + 0.4, y * _cell_draw + 0.4, _cell_draw - 0.8, _cell_draw - 0.8)
			_board.draw_rect(r, col, true)
	_board.draw_arc(Vector2(cx, cy), radius - 1.0, 0.0, TAU, 72, Color(0.35, 0.26, 0.12, 0.9), 3.0, true)


func _on_board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_painting = mb.pressed
			if mb.pressed:
				_paint_at(mb.position)
	elif event is InputEventMouseMotion and _painting:
		_paint_at((event as InputEventMouseMotion).position)


func _paint_at(local: Vector2) -> void:
	var x: = int(local.x / _cell_draw)
	var y: = int(local.y / _cell_draw)
	if x < 0 or y < 0 or x >= MosaicArt.RES or y >= MosaicArt.RES:
		return
	if not MosaicArt.in_circle(x, y):
		return
	MosaicArt.paint_brush(_draft, x, y, _selected, _brush)
	GameState.mosaic_tiles = _draft
	_paint_status.text = _status_line()
	_board.queue_redraw()
