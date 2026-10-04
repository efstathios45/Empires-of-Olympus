extends Control
## Agora ψιφιδωτό quest + circular tessera painter.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const PANEL_W: = 980
const PANEL_H: = 700
const BOARD_PX: = 420
const CELL_DRAW: = float(BOARD_PX) / float(MosaicArt.RES)

enum Mode {OFFER, START, PAINT}

var hud: CanvasLayer
var speaker_name: String = "Old Myrrine"

var _mode: int = Mode.OFFER
var _body: VBoxContainer
var _quote: Label
var _title: Label
var _brief: Label
var _status: Label
var _action_row: HBoxContainer

var _paint_root: Control
var _board: Control
var _palette_box: VBoxContainer
var _selected: int = 1
var _brush: int = 0
var _painting: bool = false
var _draft: PackedByteArray = PackedByteArray()
var _swatch_buttons: Array = []
var _result: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	center.add_child(panel)

	var margin := Kit.make_margin(18)
	panel.add_child(margin)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	margin.add_child(_body)

	_build_header()
	_quote = Kit.make_label("", 16, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote.custom_minimum_size = Vector2(PANEL_W - 80, 0)
	_body.add_child(_quote)
	_body.add_child(_divider())

	_title = Kit.make_label("", 24, Kit.INK_TITLE)
	_body.add_child(_title)
	_brief = Kit.make_label("", 17, Kit.INK)
	_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_brief.custom_minimum_size = Vector2(PANEL_W - 80, 0)
	_brief.add_theme_constant_override("line_spacing", 6)
	_body.add_child(_brief)

	_status = Kit.make_label("", 16, Kit.INK_GOLD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_status)

	_paint_root = HBoxContainer.new()
	_paint_root.add_theme_constant_override("separation", 16)
	_paint_root.visible = false
	_body.add_child(_paint_root)
	_build_painter()

	_result = Kit.make_label("", 16, Kit.INK_GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	_body.add_child(_result)

	_action_row = HBoxContainer.new()
	_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_row.add_theme_constant_override("separation", 16)
	_body.add_child(_action_row)

	_resolve_mode()
	_refresh()


func _build_header() -> void:
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	_body.add_child(head)
	head.add_child(Kit.make_icon("icon_laurel", 36))
	head.add_child(Kit.make_label(speaker_name, 28, Kit.INK_TITLE))


func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.42, 0.32, 0.14, 0.3)
	d.custom_minimum_size = Vector2(PANEL_W - 80, 2)
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
	_clear_actions()
	_result.text = ""
	GameState.ensure_mosaic_tiles()
	_draft = GameState.mosaic_tiles.duplicate()

	match _mode:
		Mode.OFFER:
			_paint_root.visible = false
			_quote.text = _offer_quote()
			_title.text = String(GameState.MOSAIC_QUEST["title"])
			_brief.text = String(GameState.MOSAIC_QUEST["brief"])
			_status.text = "Reward: %d gold  •  %d glory  •  your mosaic stays on this square for you alone" % [
				GameState.MOSAIC_QUEST["reward_gold"], GameState.MOSAIC_QUEST["reward_xp"],
			]
			_add_btn("Accept", true, _on_accept)
			_add_btn("Not yet", false, func() -> void: hud.close_panel_from_click())
		Mode.START:
			_paint_root.visible = false
			_quote.text = _start_quote()
			_title.text = String(GameState.MOSAIC_QUEST["title"])
			_brief.text = "Do you want to start now?"
			_status.text = "Lay coloured tesserae in the circle, then seal the artwork to claim your reward."
			_add_btn("Yes — begin", true, _on_begin_paint)
			_add_btn("Later", false, func() -> void: hud.close_panel_from_click())
		Mode.PAINT:
			_paint_root.visible = true
			_quote.text = _paint_quote()
			_title.text = "Set the Tesserae"
			_brief.text = "Paint the circular ψιφιδωτό. Classical colours are named as the poets knew them."
			_status.text = "Tesserae set: %d   (seal needs at least 24)" % MosaicArt.painted_count(_draft)
			_board.queue_redraw()
			_sync_swatches()
			_add_btn("Seal artwork", true, _on_seal)
			_add_btn("Clear", false, _on_clear)
			_add_btn("Farewell", false, func() -> void: hud.close_panel_from_click())


func _offer_quote() -> String:
	match speaker_name:
		"Thalia":
			return "\"The priestess speaks of omens — I speak of beauty. Restore the wheel of pebbles, and the agora will smile again.\""
		"Eirene":
			return "\"Athena watches this fountain. Offer her a circle of colour — Leukos, Kyaneos, Chryseos — stone by stone.\""
		_:
			return "\"Child, the square once glittered — every feast a wheel of colour under our feet. Will you set the tesserae anew?\""


func _start_quote() -> String:
	match speaker_name:
		"Thalia":
			return "\"Good. The pebbles are waiting by the fountain — shall we begin?\""
		"Eirene":
			return "\"Blessed be your hands. Do you want to start now?\""
		_:
			return "\"The pebbles wait. Athena's court is watching. Do you want to start now?\""


func _paint_quote() -> String:
	match speaker_name:
		"Thalia":
			return "\"Make it vivid — Phoinix against Leukos, like festival ribbons!\""
		"Eirene":
			return "\"Quiet work. Let Glaukos and Chloros ring the fountain like a hymn.\""
		_:
			return "\"Steady hand. Mortar between every stone — that is how the old craftsmen worked.\""


func _clear_actions() -> void:
	for c in _action_row.get_children():
		c.queue_free()


func _add_btn(text: String, primary: bool, cb: Callable) -> void:
	var b := Kit.make_button(text, primary)
	b.pressed.connect(cb)
	_action_row.add_child(b)


func _on_accept() -> void:
	if GameState.accept_mosaic_quest():
		AudioManager.play_sfx("ui_click")
		_mode = Mode.START
		_refresh()


func _on_begin_paint() -> void:
	_mode = Mode.PAINT
	_refresh()


func _on_clear() -> void:
	MosaicArt.clear_circle(_draft)
	_status.text = "Tesserae set: 0   (seal needs at least 24)"
	_board.queue_redraw()


func _on_seal() -> void:
	GameState.mosaic_tiles = _draft
	var res: Dictionary = GameState.seal_mosaic_artwork()
	if not bool(res.get("ok", false)):
		if String(res.get("reason", "")) == "too_sparse":
			_result.text = "Set at least 24 tesserae before sealing."
			_result.add_theme_color_override("font_color", Kit.INK_TITLE)
		return
	AudioManager.play_sfx("quest_complete")
	if bool(res.get("first_reward", false)):
		_result.text = "Sealed! +%d gold, +%d glory — the square remembers your hand." % [
			int(res.get("gold", 0)), int(res.get("xp", 0)),
		]
	else:
		_result.text = "Sealed anew — your square shines with the fresh pattern."
	_result.add_theme_color_override("font_color", Kit.INK_GOOD)
	_status.text = "Tesserae set: %d — sealed" % MosaicArt.painted_count(_draft)
	# Refresh plaza floor while the panel is still open.
	var worlds := get_tree().get_nodes_in_group("game_world")
	if worlds.size() > 0 and worlds[0].has_method("apply_player_mosaic"):
		worlds[0].call("apply_player_mosaic")


func _build_painter() -> void:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	_paint_root.add_child(left)

	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.18, 0.14, 0.55)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.48, 0.36, 0.18, 0.9)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
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
	_paint_root.add_child(right)
	right.add_child(Kit.make_label("Tessera colours", 20, Kit.INK_TITLE))
	right.add_child(Kit.make_label("Named as the Greeks spoke them", 14, Kit.INK_SOFT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(360, 420)
	right.add_child(scroll)
	_palette_box = VBoxContainer.new()
	_palette_box.add_theme_constant_override("separation", 4)
	_palette_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_palette_box)

	_swatch_buttons.clear()
	for i in MosaicArt.PALETTE.size():
		var entry: Dictionary = MosaicArt.PALETTE[i]
		var idx: = i + 1
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(340, 40)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text = "  %s — %s" % [entry["name"], entry["gloss"]]
		row.add_theme_font_override("font", Kit.font())
		row.add_theme_font_size_override("font_size", 14)
		row.add_theme_color_override("font_color", Kit.INK)
		var style := StyleBoxFlat.new()
		style.bg_color = entry["color"]
		style.set_border_width_all(2)
		style.border_color = Color(0.2, 0.15, 0.1, 0.55)
		style.set_corner_radius_all(4)
		style.content_margin_left = 8
		for st in ["normal", "hover", "pressed", "focus"]:
			row.add_theme_stylebox_override(st, style)
		# Dark text on light stones, light text on dark dyes.
		var lum: = float(entry["color"].r * 0.3 + entry["color"].g * 0.59 + entry["color"].b * 0.11)
		var ink: = Kit.INK if lum > 0.45 else Color(0.96, 0.93, 0.86)
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			row.add_theme_color_override(st, ink)
		row.pressed.connect(_select_color.bind(idx))
		_palette_box.add_child(row)
		_swatch_buttons.append(row)


func _tool_btn(text: String, cb: Callable) -> Button:
	var b := Kit.make_button(text, false)
	b.custom_minimum_size = Vector2(120, 48)
	b.pressed.connect(cb)
	return b


func _select_color(idx: int) -> void:
	_selected = idx
	_sync_swatches()


func _sync_swatches() -> void:
	for i in _swatch_buttons.size():
		var btn: Button = _swatch_buttons[i]
		var active: = (_selected == i + 1)
		btn.modulate = Color(1.15, 1.1, 0.95) if active else Color.WHITE


func _draw_board() -> void:
	var cx: = BOARD_PX * 0.5
	var cy: = BOARD_PX * 0.5
	var radius: = BOARD_PX * 0.5 - 2.0
	_board.draw_circle(Vector2(cx, cy), radius + 3.0, Color(0.35, 0.28, 0.18, 0.9))
	_board.draw_circle(Vector2(cx, cy), radius, Color(0.70, 0.62, 0.50))
	for y in MosaicArt.RES:
		for x in MosaicArt.RES:
			if not MosaicArt.in_circle(x, y):
				continue
			var idx: = int(_draft[MosaicArt.index_of(x, y)])
			var col: = MosaicArt.color_at(idx) if idx != MosaicArt.EMPTY else MosaicArt.UNDERLAY
			var r := Rect2(x * CELL_DRAW + 0.5, y * CELL_DRAW + 0.5, CELL_DRAW - 1.0, CELL_DRAW - 1.0)
			_board.draw_rect(r, col, true)
	# Soft rim
	_board.draw_arc(Vector2(cx, cy), radius - 1.0, 0.0, TAU, 64, Color(0.42, 0.32, 0.16, 0.85), 3.0, true)


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
	var x: = int(local.x / CELL_DRAW)
	var y: = int(local.y / CELL_DRAW)
	if x < 0 or y < 0 or x >= MosaicArt.RES or y >= MosaicArt.RES:
		return
	if not MosaicArt.in_circle(x, y):
		return
	MosaicArt.paint_brush(_draft, x, y, _selected, _brush)
	GameState.mosaic_tiles = _draft
	_status.text = "Tesserae set: %d   (seal needs at least 24)" % MosaicArt.painted_count(_draft)
	_board.queue_redraw()
