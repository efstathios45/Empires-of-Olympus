extends Control
## Panoply & Pouch — Metin2-style equipment window.
## Larger icons, readable labels, hover tooltips with bonuses.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const CELL := 52
const SLOT_W := 72
const SLOT_H := 64
const ICON_SLOT := 40
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
var _equip_name_labs: Dictionary = {}
var _bag_cells: Array = []
var _selected_bag: int = -1
var _selected_slot: String = ""
var _stat_labels: Dictionary = {}
var _hover_tip: PanelContainer
var _hover_tip_label: Label
var _ctx_menu: PanelContainer = null
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
	## Tall enough for paperdoll + pouch without clipping labels.
	panel.custom_minimum_size = Vector2(1080, 900)
	panel.clip_contents = false
	center.add_child(panel)

	## Stylebox already insets past the ornate border — keep only a light gap.
	var margin := Kit.make_margin(14)
	margin.clip_contents = false
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.clip_contents = false
	margin.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(Kit.make_icon("icon_laurel", 30))
	var title := Kit.make_label("Panoply & Pouch", 24, Kit.INK_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_btn := Kit.make_button("Close", false)
	close_btn.pressed.connect(_close)
	top.add_child(close_btn)

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	v.add_child(_tabs)
	_add_tab("gear", "Panoply")
	_add_tab("clan", "Clan")

	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 560)
	_body.clip_contents = false
	v.add_child(_body)

	_build_hover_tip()


func _add_tab(id: String, text: String) -> void:
	var b := Kit.make_button(text, id == "gear")
	b.set_meta("tab_id", id)
	b.pressed.connect(func() -> void: _show(id))
	_tabs.add_child(b)


func _make_ctx_button(text: String) -> Button:
	## Flat list row for the right-click item menu (no baked "BACK" plaque art).
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 36)
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", Kit.font())
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	b.add_theme_color_override("font_hover_color", Kit.INK_GOLD)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var sb_h := sb.duplicate()
	sb_h.bg_color = Color(0.78, 0.62, 0.28, 0.28)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_stylebox_override("pressed", sb_h)
	return b


func _build_hover_tip() -> void:
	_hover_tip = PanelContainer.new()
	_hover_tip.visible = false
	_hover_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_tip.z_index = 80
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.06, 0.94)
	sb.border_color = Color(0.78, 0.62, 0.28, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_hover_tip.add_theme_stylebox_override("panel", sb)
	_hover_tip_label = Label.new()
	_hover_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_tip_label.custom_minimum_size = Vector2(260, 0)
	_hover_tip_label.add_theme_font_override("font", Kit.font())
	_hover_tip_label.add_theme_font_size_override("font_size", 15)
	_hover_tip_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	_hover_tip.add_child(_hover_tip_label)
	add_child(_hover_tip)


func _show_item_tip(item_id: String, at_global: Vector2) -> void:
	if item_id == "" or _hover_tip == null:
		_hide_item_tip()
		return
	_hover_tip_label.text = GameState.item_tooltip_text(item_id)
	_hover_tip.visible = true
	_hover_tip.reset_size()
	var pos := at_global + Vector2(18, 18)
	var vp := get_viewport_rect().size
	var tip_size := _hover_tip.get_combined_minimum_size()
	if tip_size == Vector2.ZERO:
		tip_size = Vector2(280, 120)
	pos.x = minf(pos.x, vp.x - tip_size.x - 12)
	pos.y = minf(pos.y, vp.y - tip_size.y - 12)
	_hover_tip.global_position = pos


func _hide_item_tip() -> void:
	if _hover_tip:
		_hover_tip.visible = false


func _show(which: String) -> void:
	if which == "inventory":
		which = "gear"
	initial_tab = which
	for c in _body.get_children():
		c.queue_free()
	_bag_cells.clear()
	_equip_btns.clear()
	_equip_icons.clear()
	_equip_name_labs.clear()
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
	_equip_name_labs.clear()
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 18)
	row.clip_contents = true
	_body.add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)

	left.add_child(Kit.make_label("Worn Panoply", 18, Kit.INK_GOLD))
	var emp := GameState.empire_data()
	var cls := GameState.class_data()
	left.add_child(Kit.make_label("%s · %s" % [emp.get("name", "?"), cls.get("name", "?")], 14, Kit.INK_SOFT))

	## Paperdoll: larger slots with icon + short name under each.
	var doll := CenterContainer.new()
	left.add_child(doll)
	var doll_box := Control.new()
	doll_box.custom_minimum_size = Vector2(290, 340)
	doll.add_child(doll_box)

	var body := ColorRect.new()
	body.color = Color(0.62, 0.52, 0.38, 0.55)
	body.position = Vector2(118, 70)
	body.size = Vector2(54, 120)
	doll_box.add_child(body)
	var head := ColorRect.new()
	head.color = Color(0.72, 0.58, 0.42, 0.7)
	head.position = Vector2(128, 36)
	head.size = Vector2(34, 32)
	doll_box.add_child(head)

	var slot_pos := {
		"helmet": Vector2(109, 0),
		"necklace": Vector2(8, 40),
		"earring": Vector2(8, 112),
		"bracelet": Vector2(8, 184),
		"weapon": Vector2(8, 256),
		"armor": Vector2(210, 112),
		"shield": Vector2(210, 184),
		"boots": Vector2(109, 236),
	}
	for key in SLOT_KEYS:
		var wrap := VBoxContainer.new()
		wrap.position = slot_pos[key]
		wrap.add_theme_constant_override("separation", 2)
		doll_box.add_child(wrap)

		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.clip_text = true
		slot_btn.add_theme_font_override("font", Kit.font())
		slot_btn.add_theme_font_size_override("font_size", 12)
		slot_btn.add_theme_color_override("font_color", Kit.INK)
		slot_btn.pressed.connect(_select_equip_slot.bind(key))
		slot_btn.gui_input.connect(_on_slot_gui_input.bind(key))
		slot_btn.mouse_entered.connect(_on_slot_hover.bind(key))
		slot_btn.mouse_exited.connect(_hide_item_tip)
		wrap.add_child(slot_btn)
		_equip_btns[key] = slot_btn

		var ico := TextureRect.new()
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.custom_minimum_size = Vector2(ICON_SLOT, ICON_SLOT)
		ico.size = Vector2(ICON_SLOT, ICON_SLOT)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ico.position = Vector2((SLOT_W - ICON_SLOT) * 0.5, 6)
		slot_btn.add_child(ico)
		_equip_icons[key] = ico

		var name_lab := Kit.make_label(SLOT_LABELS[key], 12, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		name_lab.custom_minimum_size = Vector2(SLOT_W, 0)
		wrap.add_child(name_lab)
		_equip_name_labs[key] = name_lab

	left.add_child(Kit.spacer(6))
	for key in ["atk", "def", "hp", "gold"]:
		var lab := Kit.make_label("", 15, Kit.INK)
		left.add_child(lab)
		_stat_labels[key] = lab

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	right.clip_contents = false
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)

	right.add_child(Kit.make_label("Traveler's Pouch", 18, Kit.INK_GOLD))
	right.add_child(Kit.make_label("Right-click item: Equip / Sell · Drag to wear", 13, Kit.INK_SOFT))

	var grid_wrap := CenterContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_wrap.clip_contents = true
	right.add_child(grid_wrap)
	var grid := GridContainer.new()
	grid.columns = GameState.BAG_W
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.custom_minimum_size = Vector2(
		GameState.BAG_W * CELL + (GameState.BAG_W - 1) * 4,
		GameState.BAG_H * CELL + (GameState.BAG_H - 1) * 4)
	grid_wrap.add_child(grid)

	for _i in range(GameState.BAG_W * GameState.BAG_H):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(CELL, CELL)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.88, 0.76, 0.95)
		sb.border_color = Color(0.55, 0.42, 0.22, 0.85)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 2
		sb.content_margin_right = 2
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		cell.add_theme_stylebox_override("panel", sb)

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
		lab.add_theme_font_size_override("font_size", 12)
		lab.add_theme_color_override("font_color", Kit.INK)
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(lab)

		var idx: int = _bag_cells.size()
		cell.gui_input.connect(_on_bag_cell_input.bind(idx))
		cell.mouse_entered.connect(_on_bag_hover.bind(idx))
		cell.mouse_exited.connect(_hide_item_tip)
		grid.add_child(cell)
		_bag_cells.append({"panel": cell, "label": lab, "icon": ico, "entry": -1})

	_detail = Kit.make_label("Select or hover an item.", 15, Kit.INK_SOFT)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(300, 0)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_detail)

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
		btn.text = "" if id != "" else SLOT_LABELS[key]
		_set_slot_icon(key, id)
		var nlab: Label = _equip_name_labs.get(key)
		if nlab:
			nlab.text = GameState.item_name(id) if id != "" else SLOT_LABELS[key]
			nlab.add_theme_color_override("font_color", Kit.INK if id != "" else Kit.INK_SOFT)
		btn.tooltip_text = GameState.item_tooltip_text(id) if id != "" else "%s slot (empty)" % SLOT_LABELS[key]
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
	if event is InputEventMouseButton:
		var ei: int = int(_bag_cells[cell_idx]["entry"])
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if ei < 0:
				_hide_ctx_menu()
				return
			_selected_bag = ei
			_selected_slot = ""
			_refresh_panoply()
			_show_bag_ctx(ei, event.global_position)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_hide_ctx_menu()
			if event.pressed:
				if ei < 0:
					return
				_selected_bag = ei
				_selected_slot = ""
				_refresh_panoply()
				_arm_bag_drag(ei, event.global_position)
			else:
				_finish_drag(event.global_position)


func _on_slot_gui_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton:
		var id := str(GameState.equipped.get(key, ""))
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if id == "":
				_hide_ctx_menu()
				return
			_selected_slot = key
			_selected_bag = -1
			_refresh_panoply()
			_show_slot_ctx(key, event.global_position)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_hide_ctx_menu()
			if event.pressed:
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
	if event is InputEventMouseButton and event.pressed and _ctx_menu != null and is_instance_valid(_ctx_menu):
		if not _ctx_menu.get_global_rect().has_point(event.global_position):
			_hide_ctx_menu()
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


func _on_bag_hover(cell_idx: int) -> void:
	if cell_idx < 0 or cell_idx >= _bag_cells.size():
		return
	var ei: int = int(_bag_cells[cell_idx]["entry"])
	if ei < 0 or ei >= GameState.bag.size():
		_hide_item_tip()
		return
	var id := str(GameState.bag[ei].get("id", ""))
	_show_item_tip(id, get_global_mouse_position())


func _on_slot_hover(key: String) -> void:
	var id := str(GameState.equipped.get(key, ""))
	if id == "":
		_hide_item_tip()
		return
	_show_item_tip(id, get_global_mouse_position())


func _update_detail_bag(ei: int) -> void:
	if ei < 0 or ei >= GameState.bag.size() or _detail == null:
		return
	var id := str(GameState.bag[ei].get("id", ""))
	_detail.text = GameState.item_tooltip_text(id)


func _update_detail_slot(key: String) -> void:
	if _detail == null:
		return
	var id := str(GameState.equipped.get(key, ""))
	if id == "":
		_detail.text = "%s slot empty — drag matching gear here." % SLOT_LABELS.get(key, key)
		return
	_detail.text = "%s (worn)\n%s" % [SLOT_LABELS.get(key, key), GameState.item_tooltip_text(id)]


func _hide_ctx_menu() -> void:
	if _ctx_menu != null and is_instance_valid(_ctx_menu):
		_ctx_menu.queue_free()
	_ctx_menu = null


func _place_ctx_menu(at_global: Vector2) -> void:
	if _ctx_menu == null:
		return
	_ctx_menu.reset_size()
	var tip_size := _ctx_menu.get_combined_minimum_size()
	if tip_size == Vector2.ZERO:
		tip_size = Vector2(220, 100)
	var vp := get_viewport_rect().size
	var pos := at_global + Vector2(8, 8)
	pos.x = minf(pos.x, vp.x - tip_size.x - 8)
	pos.y = minf(pos.y, vp.y - tip_size.y - 8)
	_ctx_menu.global_position = pos


func _make_ctx_shell() -> VBoxContainer:
	_hide_ctx_menu()
	_ctx_menu = PanelContainer.new()
	_ctx_menu.z_index = 90
	_ctx_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.06, 0.96)
	sb.border_color = Color(0.78, 0.62, 0.28, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_ctx_menu.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	_ctx_menu.add_child(col)
	add_child(_ctx_menu)
	return col


func _show_bag_ctx(entry_index: int, at_global: Vector2) -> void:
	if entry_index < 0 or entry_index >= GameState.bag.size():
		return
	var id := str(GameState.bag[entry_index].get("id", ""))
	var def := GameState.item_def(id)
	var slot := GameState.slot_for_kind(str(def.get("kind", "")))
	var col := _make_ctx_shell()
	var title := Kit.make_label(GameState.item_name(id), 14, Kit.INK_GOLD)
	col.add_child(title)
	if slot != "":
		var eq := _make_ctx_button("Equip")
		eq.pressed.connect(func() -> void:
			_hide_ctx_menu()
			if GameState.equip_from_bag(entry_index):
				AudioManager.play_sfx("ui_confirm")
				_selected_bag = -1
				_selected_slot = slot
				_refresh_panoply()
			else:
				AudioManager.play_sfx("ui_click")
				if _detail:
					_detail.text = "That piece cannot be worn."
		)
		col.add_child(eq)
	var sell_price := GameState.item_sell_price(id)
	if sell_price > 0:
		var sell := _make_ctx_button("Sell (%d δ)" % sell_price)
		sell.pressed.connect(func() -> void:
			_hide_ctx_menu()
			_selected_bag = entry_index
			var gained: int = GameState.sell_bag_entry(entry_index)
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
		)
		col.add_child(sell)
	var cancel := _make_ctx_button("Cancel")
	cancel.pressed.connect(_hide_ctx_menu)
	col.add_child(cancel)
	_place_ctx_menu(at_global)


func _show_slot_ctx(key: String, at_global: Vector2) -> void:
	var id := str(GameState.equipped.get(key, ""))
	if id == "":
		return
	var col := _make_ctx_shell()
	col.add_child(Kit.make_label(GameState.item_name(id), 14, Kit.INK_GOLD))
	var uneq := _make_ctx_button("Unequip")
	uneq.pressed.connect(func() -> void:
		_hide_ctx_menu()
		if GameState.unequip_slot(key):
			AudioManager.play_sfx("ui_confirm")
			_selected_slot = ""
			_refresh_panoply()
		else:
			AudioManager.play_sfx("ui_click")
			if _detail:
				_detail.text = "Cannot unequip — pouch may be full."
	)
	col.add_child(uneq)
	var cancel := _make_ctx_button("Cancel")
	cancel.pressed.connect(_hide_ctx_menu)
	col.add_child(cancel)
	_place_ctx_menu(at_global)


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
