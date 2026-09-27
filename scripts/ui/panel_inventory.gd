extends Control
## Panoply & Pouch — Metin2-style equipment window.
## Left: compact paperdoll with helm / weapon / armor / shield / boots /
## necklace / earring / bracelet. Right: smaller bag grid with item icons.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const CELL := 36
## Classic Metin2-ish slot set around the silhouette.
const SLOT_KEYS := [
	"helmet", "necklace", "earring", "bracelet",
	"weapon", "armor", "shield", "boots",
]
const SLOT_LABELS := {
	"helmet": "Helm",
	"necklace": "Neck",
	"earring": "Ear",
	"bracelet": "Wrist",
	"weapon": "Weapon",
	"armor": "Armor",
	"shield": "Shield",
	"boots": "Boots",
}

var hud: CanvasLayer
var initial_tab: String = "gear"

var _tabs: HBoxContainer
var _body: Control
var _detail: Label
var _equip_btns: Dictionary = {}
var _equip_icons: Dictionary = {}
var _bag_cells: Array = []
var _selected_bag: int = -1
var _selected_slot: String = ""
var _btn_equip: Button
var _btn_unequip: Button
var _btn_sell: Button
var _stat_labels: Dictionary = {}
## Manual Metin2-style drag (more reliable than Control.set_drag_forwarding).
var _drag_armed: bool = false
var _dragging: bool = false
var _drag_press_pos: Vector2 = Vector2.ZERO
var _drag_data: Dictionary = {}
var _drag_preview: Control = null
const DRAG_SLOP := 8.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()
	if not GameState.inventory_changed.is_connected(_on_inv):
		GameState.inventory_changed.connect(_on_inv)
	if not GameState.stats_changed.is_connected(_on_inv):
		GameState.stats_changed.connect(_on_inv)
	_show(initial_tab)


func _exit_tree() -> void:
	if GameState.inventory_changed.is_connected(_on_inv):
		GameState.inventory_changed.disconnect(_on_inv)
	if GameState.stats_changed.is_connected(_on_inv):
		GameState.stats_changed.disconnect(_on_inv)


func _build_shell() -> void:
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	## panel_scroll content_margin is ~118×2 / 136+128. Usable cream must fit
	## paperdoll (220) + gap + 6×36 bag (226) without spilling past the gold frame.
	panel.custom_minimum_size = Vector2(880, 760)
	panel.clip_contents = true
	center.add_child(panel)

	## Stylebox already insets past the ornate border — keep only a light gap.
	var margin := Kit.make_margin(8)
	margin.clip_contents = true
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.clip_contents = true
	margin.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	top.add_child(Kit.make_icon("icon_laurel", 26))
	var title := Kit.make_label("Panoply & Pouch", 20, Kit.INK_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_btn := Kit.make_button("Close", false)
	close_btn.pressed.connect(_close)
	top.add_child(close_btn)

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	v.add_child(_tabs)
	_add_tab("gear", "Panoply")
	_add_tab("clan", "Clan")

	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 360)
	_body.clip_contents = true
	v.add_child(_body)


func _add_tab(id: String, text: String) -> void:
	var b := Kit.make_button(text, id == "gear")
	b.set_meta("tab_id", id)
	b.pressed.connect(func() -> void: _show(id))
	_tabs.add_child(b)


func _show(which: String) -> void:
	if which == "inventory":
		which = "gear"
	initial_tab = which
	for c in _body.get_children():
		c.queue_free()
	_bag_cells.clear()
	_equip_btns.clear()
	_equip_icons.clear()
	_stat_labels.clear()
	_selected_bag = -1
	_selected_slot = ""
	_detail = null
	await get_tree().process_frame
	if which == "clan":
		_build_clan()
	else:
		_build_panoply()
	_paint_tabs()


func _paint_tabs() -> void:
	for c in _tabs.get_children():
		if c is Button:
			var on: bool = str(c.get_meta("tab_id", "")) == initial_tab
			c.modulate = Color(1.12, 1.06, 0.9) if on else Color.WHITE


func _build_panoply() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 16)
	row.clip_contents = true
	_body.add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(230, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_theme_constant_override("separation", 4)
	row.add_child(left)

	left.add_child(Kit.make_label("Worn Panoply", 15, Kit.INK_GOLD))
	var emp := GameState.empire_data()
	var cls := GameState.class_data()
	left.add_child(Kit.make_label("%s · %s" % [emp.get("name", "?"), cls.get("name", "?")], 11, Kit.INK_SOFT))

	## Metin2 paperdoll: slots around a simple silhouette.
	var doll := CenterContainer.new()
	left.add_child(doll)
	var doll_box := Control.new()
	doll_box.custom_minimum_size = Vector2(220, 200)
	doll.add_child(doll_box)

	var body := ColorRect.new()
	body.color = Color(0.62, 0.52, 0.38, 0.55)
	body.position = Vector2(86, 48)
	body.size = Vector2(48, 100)
	doll_box.add_child(body)
	var head := ColorRect.new()
	head.color = Color(0.72, 0.58, 0.42, 0.7)
	head.position = Vector2(94, 22)
	head.size = Vector2(32, 28)
	doll_box.add_child(head)

	## Slot layout (Metin2-ish): jewelry left, body center-right, boots bottom.
	var slot_pos := {
		"helmet": Vector2(86, 0),
		"necklace": Vector2(8, 28),
		"earring": Vector2(8, 72),
		"bracelet": Vector2(8, 116),
		"weapon": Vector2(8, 160),
		"armor": Vector2(158, 72),
		"shield": Vector2(158, 116),
		"boots": Vector2(86, 156),
	}
	for key in SLOT_KEYS:
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(52, 40)
		slot_btn.position = slot_pos[key]
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.clip_text = true
		slot_btn.add_theme_font_override("font", Kit.font())
		slot_btn.add_theme_font_size_override("font_size", 9)
		slot_btn.add_theme_color_override("font_color", Kit.INK)
		slot_btn.tooltip_text = SLOT_LABELS[key]
		slot_btn.pressed.connect(_select_equip_slot.bind(key))
		slot_btn.gui_input.connect(_on_slot_gui_input.bind(key))
		doll_box.add_child(slot_btn)
		_equip_btns[key] = slot_btn
		var ico := TextureRect.new()
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.custom_minimum_size = Vector2(22, 22)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ico.position = Vector2(2, 2)
		slot_btn.add_child(ico)
		_equip_icons[key] = ico

	left.add_child(Kit.spacer(4))
	for key in ["atk", "def", "hp", "gold"]:
		var lab := Kit.make_label("", 11, Kit.INK)
		left.add_child(lab)
		_stat_labels[key] = lab

	_btn_unequip = Kit.make_button("Unequip", false)
	_btn_unequip.pressed.connect(_do_unequip)
	left.add_child(_btn_unequip)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	right.clip_contents = true
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)

	right.add_child(Kit.make_label("Traveler's Pouch", 15, Kit.INK_GOLD))
	right.add_child(Kit.make_label("Drag onto slots · or Select → Equip", 11, Kit.INK_SOFT))

	## Keep the 6×6 grid inside the cream field (never past the gold frame).
	var grid_wrap := CenterContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_wrap.clip_contents = true
	right.add_child(grid_wrap)
	var grid := GridContainer.new()
	grid.columns = GameState.BAG_W
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid.custom_minimum_size = Vector2(
		GameState.BAG_W * CELL + (GameState.BAG_W - 1) * 2,
		GameState.BAG_H * CELL + (GameState.BAG_H - 1) * 2)
	grid_wrap.add_child(grid)

	for _i in range(GameState.BAG_W * GameState.BAG_H):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(CELL, CELL)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.88, 0.76, 0.95)
		sb.border_color = Color(0.55, 0.42, 0.22, 0.85)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		sb.content_margin_left = 1
		sb.content_margin_right = 1
		sb.content_margin_top = 1
		sb.content_margin_bottom = 1
		cell.add_theme_stylebox_override("panel", sb)

		## Ignore mouse on children so the cell receives drag / clicks.
		var stack := Control.new()
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(stack)

		var ico := TextureRect.new()
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(ico)

		var lab := Label.new()
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lab.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lab.add_theme_font_override("font", Kit.font())
		lab.add_theme_font_size_override("font_size", 9)
		lab.add_theme_color_override("font_color", Kit.INK)
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(lab)

		var idx: int = _bag_cells.size()
		cell.gui_input.connect(_on_bag_cell_input.bind(idx))
		grid.add_child(cell)
		_bag_cells.append({"panel": cell, "label": lab, "icon": ico, "entry": -1})

	_detail = Kit.make_label("Select an item.", 12, Kit.INK_SOFT)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(226, 0)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_detail)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	right.add_child(actions)
	_btn_equip = Kit.make_button("Equip", true)
	_btn_equip.pressed.connect(_do_equip)
	actions.add_child(_btn_equip)
	_btn_sell = Kit.make_button("Sell", false)
	_btn_sell.pressed.connect(_do_sell)
	actions.add_child(_btn_sell)

	_refresh_panoply()


func _set_slot_icon(key: String, item_id: String) -> void:
	var ico: TextureRect = _equip_icons.get(key)
	if ico == null:
		return
	if item_id == "":
		ico.texture = null
		return
	var path: String = GameState.item_icon_path(item_id)
	if path != "" and ResourceLoader.exists(path):
		ico.texture = load(path)
	else:
		ico.texture = null


func _refresh_panoply() -> void:
	if _detail == null:
		return
	for key in SLOT_KEYS:
		var btn: Button = _equip_btns.get(key)
		if btn == null:
			continue
		var id := String(GameState.equipped.get(key, ""))
		btn.text = "  %s" % SLOT_LABELS[key] if id == "" else ""
		_set_slot_icon(key, id)
		btn.tooltip_text = "%s: %s" % [SLOT_LABELS[key], GameState.equipped_name(key)]
		btn.modulate = Color(1.15, 1.08, 0.85) if key == _selected_slot else Color.WHITE

	if _stat_labels.has("atk"):
		_stat_labels["atk"].text = "ATK  %d" % int(GameState.attack_damage())
	if _stat_labels.has("def"):
		_stat_labels["def"].text = "DEF  ×%.2f" % GameState.damage_taken_mult()
	if _stat_labels.has("hp"):
		_stat_labels["hp"].text = "HP  %d" % GameState.max_hp()
	if _stat_labels.has("gold"):
		_stat_labels["gold"].text = "Gold  %d δ" % GameState.gold

	for i in range(_bag_cells.size()):
		_bag_cells[i]["entry"] = -1
		(_bag_cells[i]["label"] as Label).text = ""
		(_bag_cells[i]["icon"] as TextureRect).texture = null
		(_bag_cells[i]["panel"] as PanelContainer).modulate = Color.WHITE

	for ei in range(GameState.bag.size()):
		var e: Dictionary = GameState.bag[ei]
		var id := str(e.get("id", ""))
		var def: Dictionary = GameState.item_def(id)
		var cells: Vector2i = GameState.item_cells(id)
		var ox := int(e.get("x", 0))
		var oy := int(e.get("y", 0))
		var count := int(e.get("count", 1))
		var kind := str(def.get("kind", ""))
		var path: String = GameState.item_icon_path(id)
		var tex: Texture2D = load(path) if path != "" and ResourceLoader.exists(path) else null
		for dy in cells.y:
			for dx in cells.x:
				var cx := ox + dx
				var cy := oy + dy
				var idx := cy * GameState.BAG_W + cx
				if idx < 0 or idx >= _bag_cells.size():
					continue
				_bag_cells[idx]["entry"] = ei
				var lab2: Label = _bag_cells[idx]["label"]
				var ico2: TextureRect = _bag_cells[idx]["icon"]
				if dx == 0 and dy == 0:
					ico2.texture = tex
					lab2.text = "" if count <= 1 else "×%d" % count
				else:
					ico2.texture = null
					lab2.text = "·"
				(_bag_cells[idx]["panel"] as PanelContainer).modulate = _tint_for_kind(kind)

	if _selected_bag >= 0 and _selected_bag < GameState.bag.size():
		_update_detail_bag(_selected_bag)
		_highlight_selection()
	elif _selected_slot != "":
		_update_detail_slot(_selected_slot)
	else:
		_detail.text = "Select an item in the pouch."


func _tint_for_kind(kind: String) -> Color:
	match kind:
		"weapon":
			return Color(1.08, 1.02, 0.9)
		"shield":
			return Color(0.95, 1.02, 1.08)
		"helmet", "armor", "boots":
			return Color(1.05, 1.0, 0.95)
		"necklace", "earring", "bracelet":
			return Color(1.06, 1.04, 0.98)
		"consumable":
			return Color(1.0, 1.08, 0.95)
		"scroll", "material":
			return Color(1.05, 1.0, 1.1)
		_:
			return Color(1, 1, 1)


func _on_bag_cell_input(event: InputEvent, cell_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var ei: int = int(_bag_cells[cell_idx]["entry"])
			if ei < 0:
				return
			_selected_bag = ei
			_selected_slot = ""
			_refresh_panoply()
			_arm_bag_drag(ei, event.global_position)
		else:
			_finish_drag(event.global_position)


func _on_slot_gui_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var id := str(GameState.equipped.get(key, ""))
			if id == "":
				return
			_selected_slot = key
			_selected_bag = -1
			_arm_slot_drag(key, id, event.global_position)
		else:
			_finish_drag(event.global_position)


func _arm_bag_drag(entry_index: int, press_pos: Vector2) -> void:
	if entry_index < 0 or entry_index >= GameState.bag.size():
		return
	var e: Dictionary = GameState.bag[entry_index]
	var id := str(e.get("id", ""))
	var slot := GameState.slot_for_kind(str(GameState.item_def(id).get("kind", "")))
	if slot == "":
		return
	_drag_armed = true
	_dragging = false
	_drag_press_pos = press_pos
	_drag_data = {"from": "bag", "index": entry_index, "item_id": id, "slot": slot}
	set_process(true)
	set_process_input(true)


func _arm_slot_drag(key: String, item_id: String, press_pos: Vector2) -> void:
	_drag_armed = true
	_dragging = false
	_drag_press_pos = press_pos
	_drag_data = {"from": "slot", "slot": key, "item_id": item_id}
	set_process(true)
	set_process_input(true)


func _process(_delta: float) -> void:
	if not _drag_armed and not _dragging:
		set_process(false)
		return
	var gp := get_global_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_drag(gp)
		return
	if not _dragging and _drag_armed and gp.distance_to(_drag_press_pos) >= DRAG_SLOP:
		_begin_drag_visual()
	if _dragging:
		_move_drag_preview(gp)
		_paint_drop_hints_at(gp)


func _input(event: InputEvent) -> void:
	if not _drag_armed and not _dragging:
		return
	if event is InputEventMouseMotion:
		var gp: Vector2 = event.global_position
		if not _dragging and _drag_armed and gp.distance_to(_drag_press_pos) >= DRAG_SLOP:
			_begin_drag_visual()
		if _dragging:
			_move_drag_preview(gp)
			_paint_drop_hints_at(gp)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.global_position)


func _begin_drag_visual() -> void:
	_dragging = true
	_drag_armed = false
	var id := str(_drag_data.get("item_id", ""))
	_drag_preview = _make_drag_preview(id)
	_drag_preview.z_index = 100
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drag_preview)
	_move_drag_preview(get_global_mouse_position())
	if str(_drag_data.get("from", "")) == "bag":
		_paint_drop_hints(str(_drag_data.get("slot", "")))


func _move_drag_preview(global_pos: Vector2) -> void:
	if _drag_preview == null:
		return
	_drag_preview.global_position = global_pos - Vector2(18, 18)


func _make_drag_preview(item_id: String) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(40, 40)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.12, 0.08, 0.55)
	sb.set_corner_radius_all(4)
	wrap.add_theme_stylebox_override("panel", sb)
	var ico := TextureRect.new()
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.custom_minimum_size = Vector2(32, 32)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path: String = GameState.item_icon_path(item_id)
	if path != "" and ResourceLoader.exists(path):
		ico.texture = load(path)
	wrap.add_child(ico)
	return wrap


func _finish_drag(global_pos: Vector2) -> void:
	var was_dragging := _dragging
	var was_armed := _drag_armed
	var press_pos := _drag_press_pos
	var data := _drag_data.duplicate()
	_clear_drag_state()
	if data.is_empty() or not (was_dragging or was_armed):
		return
	## Pure click (no travel) = selection only.
	if not was_dragging and global_pos.distance_to(press_pos) < DRAG_SLOP:
		return
	var from := str(data.get("from", ""))
	if from == "bag":
		var slot_key := _slot_key_at(global_pos)
		if slot_key == "":
			if _detail:
				_detail.text = "Drop gear on its panoply slot (e.g. Boots)."
			return
		var index := int(data.get("index", -1))
		if GameState.equip_from_bag_to_slot(index, slot_key):
			AudioManager.play_sfx("ui_confirm")
			_selected_bag = -1
			_selected_slot = slot_key
			_refresh_panoply()
		else:
			AudioManager.play_sfx("ui_click")
			if _detail:
				_detail.text = "That piece does not fit the %s slot." % SLOT_LABELS.get(slot_key, slot_key)
	elif from == "slot":
		if _bag_rect_contains(global_pos):
			var key := str(data.get("slot", ""))
			if GameState.unequip_slot(key):
				AudioManager.play_sfx("ui_confirm")
				_selected_slot = ""
				_selected_bag = -1
				_refresh_panoply()
			else:
				AudioManager.play_sfx("ui_click")
				if _detail:
					_detail.text = "Cannot unequip — pouch may be full."


func _clear_drag_state() -> void:
	_drag_armed = false
	_dragging = false
	_drag_data = {}
	set_process(false)
	if _drag_preview != null and is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
	_drag_preview = null
	_clear_drop_hints()


func _slot_key_at(global_pos: Vector2) -> String:
	for key in SLOT_KEYS:
		var btn: Control = _equip_btns.get(key)
		if btn != null and btn.get_global_rect().has_point(global_pos):
			return key
	return ""


func _bag_rect_contains(global_pos: Vector2) -> bool:
	for cell in _bag_cells:
		var panel: Control = cell["panel"]
		if panel != null and panel.get_global_rect().has_point(global_pos):
			return true
	return false


func _paint_drop_hints(want_slot: String) -> void:
	for key in SLOT_KEYS:
		var btn: Button = _equip_btns.get(key)
		if btn == null:
			continue
		if key == want_slot:
			btn.modulate = Color(1.35, 1.2, 0.7)
		else:
			btn.modulate = Color(0.75, 0.75, 0.75, 0.85)


func _paint_drop_hints_at(global_pos: Vector2) -> void:
	if str(_drag_data.get("from", "")) != "bag":
		return
	var want := str(_drag_data.get("slot", ""))
	var over := _slot_key_at(global_pos)
	for key in SLOT_KEYS:
		var btn: Button = _equip_btns.get(key)
		if btn == null:
			continue
		if key == want and key == over:
			btn.modulate = Color(1.5, 1.35, 0.75)
		elif key == want:
			btn.modulate = Color(1.35, 1.2, 0.7)
		else:
			btn.modulate = Color(0.75, 0.75, 0.75, 0.85)


func _clear_drop_hints() -> void:
	for key in SLOT_KEYS:
		var btn: Button = _equip_btns.get(key)
		if btn == null:
			continue
		btn.modulate = Color(1.15, 1.08, 0.85) if key == _selected_slot else Color.WHITE


func _select_equip_slot(key: String) -> void:
	if _dragging or _drag_armed:
		return
	## Click a matching slot while a pouch item is selected → equip (no drag needed).
	if _selected_bag >= 0 and _selected_bag < GameState.bag.size():
		var id := str(GameState.bag[_selected_bag].get("id", ""))
		var want := GameState.slot_for_kind(str(GameState.item_def(id).get("kind", "")))
		if want == key:
			if GameState.equip_from_bag_to_slot(_selected_bag, key):
				AudioManager.play_sfx("ui_confirm")
				_selected_bag = -1
				_selected_slot = key
				_refresh_panoply()
				return
			AudioManager.play_sfx("ui_click")
			if _detail:
				_detail.text = "That piece does not fit the %s slot." % SLOT_LABELS.get(key, key)
			return
	_selected_slot = key
	_selected_bag = -1
	_refresh_panoply()


func _highlight_selection() -> void:
	if _selected_bag < 0:
		return
	for i in range(_bag_cells.size()):
		if int(_bag_cells[i]["entry"]) == _selected_bag:
			(_bag_cells[i]["panel"] as PanelContainer).modulate = Color(1.25, 1.12, 0.75)


func _update_detail_bag(ei: int) -> void:
	if ei < 0 or ei >= GameState.bag.size() or _detail == null:
		return
	var e: Dictionary = GameState.bag[ei]
	var id := str(e.get("id", ""))
	var def: Dictionary = GameState.item_def(id)
	var kind := str(def.get("kind", "item"))
	var price := GameState.item_sell_price(id)
	var lines := "%s\n%s\nSell: %d δ" % [
		str(def.get("name", id)),
		str(def.get("desc", "")),
		price,
	]
	var slot := GameState.slot_for_kind(kind)
	if slot != "":
		lines += "\nWear: %s" % SLOT_LABELS.get(slot, slot)
	_detail.text = lines


func _update_detail_slot(key: String) -> void:
	if _detail == null:
		return
	var id := str(GameState.equipped.get(key, ""))
	if id == "":
		_detail.text = "%s slot empty." % SLOT_LABELS.get(key, key)
		return
	var def: Dictionary = GameState.item_def(id)
	_detail.text = "%s (worn)\n%s" % [str(def.get("name", id)), str(def.get("desc", ""))]


func _do_equip() -> void:
	if _selected_bag < 0:
		if _detail:
			_detail.text = "Select a pouch item first."
		return
	if GameState.equip_from_bag(_selected_bag):
		AudioManager.play_sfx("ui_confirm")
		_selected_bag = -1
		_refresh_panoply()
	else:
		AudioManager.play_sfx("ui_click")
		if _detail:
			_detail.text = "That piece cannot be worn."


func _do_unequip() -> void:
	if _selected_slot == "":
		if _detail:
			_detail.text = "Select a worn slot first."
		return
	if GameState.unequip_slot(_selected_slot):
		AudioManager.play_sfx("ui_confirm")
		_refresh_panoply()
	else:
		AudioManager.play_sfx("ui_click")
		if _detail:
			_detail.text = "Cannot unequip — pouch may be full."


func _do_sell() -> void:
	if _selected_bag < 0:
		if _detail:
			_detail.text = "Select a pouch item to sell."
		return
	var gained: int = GameState.sell_bag_entry(_selected_bag)
	if gained > 0:
		AudioManager.play_sfx("ui_confirm")
		if _detail:
			_detail.text = "Sold for %d δ." % gained
		_selected_bag = -1
		_refresh_panoply()
	else:
		AudioManager.play_sfx("ui_click")
		if _detail:
			_detail.text = "That item cannot be sold."


func _on_inv() -> void:
	if initial_tab != "clan" and is_instance_valid(_detail):
		_refresh_panoply()


func _build_clan() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 8)
	_body.add_child(box)
	box.add_child(Kit.make_label("Your Clan", 18, Kit.INK_GOLD))
	if GameState.clan_name == "":
		box.add_child(Kit.make_label(
			"You walk alone. Found a brotherhood when the gods will it.",
			13, Kit.INK_SOFT))
	else:
		box.add_child(Kit.make_label(GameState.clan_name, 16, Kit.INK_TITLE))
		if GameState.clan_rank != "":
			box.add_child(Kit.make_label("Rank: %s" % GameState.clan_rank, 13, Kit.INK))


func _close() -> void:
	if hud and hud.has_method("close_panel_from_click"):
		hud.close_panel_from_click()
	else:
		queue_free()
