extends Control
## Panoply & Pouch — paperdoll panoply + traveler's bag grid.
## Left: helm / thorax / weapon / aspis. Right: 6×6 pouch.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const CELL := 48
const SLOT_KEYS := ["helmet", "armor", "weapon", "shield"]
const SLOT_LABELS := {
	"helmet": "Helm",
	"armor": "Thorax",
	"weapon": "Weapon",
	"shield": "Aspis",
}

var hud: CanvasLayer
var initial_tab: String = "gear"

var _tabs: HBoxContainer
var _body: Control
var _detail: Label
var _equip_btns: Dictionary = {}
var _bag_cells: Array = []
var _selected_bag: int = -1
var _selected_slot: String = ""
var _btn_equip: Button
var _btn_unequip: Button
var _btn_sell: Button
var _stat_labels: Dictionary = {}


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
	panel.custom_minimum_size = Vector2(860, 640)
	center.add_child(panel)

	var margin := Kit.make_margin(28)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	top.add_child(Kit.make_icon("icon_laurel", 34))
	var title := Kit.make_label("Panoply & Pouch", 28, Kit.INK_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_btn := Kit.make_button("Close", false)
	close_btn.custom_minimum_size = Vector2(140, 48)
	close_btn.pressed.connect(_close)
	top.add_child(close_btn)

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	v.add_child(_tabs)
	_add_tab("gear", "Panoply")
	_add_tab("clan", "Clan")

	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 480)
	v.add_child(_body)


func _add_tab(id: String, text: String) -> void:
	var b := Kit.make_button(text, id == "gear")
	b.custom_minimum_size = Vector2(160, 48)
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
	row.add_theme_constant_override("separation", 20)
	_body.add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)

	left.add_child(Kit.make_label("Worn Panoply", 20, Kit.INK_GOLD))
	var emp := GameState.empire_data()
	var cls := GameState.class_data()
	left.add_child(Kit.make_label("%s · %s" % [emp.get("name", "?"), cls.get("name", "?")], 14, Kit.INK_SOFT))

	for key in SLOT_KEYS:
		var slot_row := HBoxContainer.new()
		slot_row.add_theme_constant_override("separation", 8)
		left.add_child(slot_row)
		var tag := Kit.make_label(SLOT_LABELS[key], 13, Kit.INK_SOFT)
		tag.custom_minimum_size = Vector2(70, 0)
		slot_row.add_child(tag)
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(180, 40)
		slot_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.add_theme_font_override("font", Kit.font())
		slot_btn.add_theme_font_size_override("font_size", 14)
		slot_btn.add_theme_color_override("font_color", Kit.INK)
		slot_btn.pressed.connect(_select_equip_slot.bind(key))
		slot_row.add_child(slot_btn)
		_equip_btns[key] = slot_btn

	left.add_child(Kit.spacer(8))
	left.add_child(Kit.make_label("Battle Stats", 18, Kit.INK_GOLD))
	for key in ["atk", "def", "hp", "gold", "temper"]:
		var lab := Kit.make_label("", 14, Kit.INK)
		left.add_child(lab)
		_stat_labels[key] = lab

	left.add_child(Kit.spacer(6))
	_btn_unequip = Kit.make_button("Unequip Slot", false)
	_btn_unequip.custom_minimum_size = Vector2(200, 48)
	_btn_unequip.pressed.connect(_do_unequip)
	left.add_child(_btn_unequip)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)

	right.add_child(Kit.make_label("Traveler's Pouch", 20, Kit.INK_GOLD))
	right.add_child(Kit.make_label("Select a piece, then Equip or Sell.", 13, Kit.INK_SOFT))

	var grid_wrap := CenterContainer.new()
	right.add_child(grid_wrap)
	var grid := GridContainer.new()
	grid.columns = GameState.BAG_W
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
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
		var lab := Label.new()
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_override("font", Kit.font())
		lab.add_theme_font_size_override("font_size", 10)
		lab.add_theme_color_override("font_color", Kit.INK)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cell.add_child(lab)
		var idx: int = _bag_cells.size()
		cell.gui_input.connect(_on_bag_cell_input.bind(idx))
		grid.add_child(cell)
		_bag_cells.append({"panel": cell, "label": lab, "entry": -1})

	_detail = Kit.make_label("Select an item in the pouch.", 14, Kit.INK_SOFT)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(420, 0)
	right.add_child(_detail)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	right.add_child(actions)
	_btn_equip = Kit.make_button("Equip", true)
	_btn_equip.custom_minimum_size = Vector2(150, 52)
	_btn_equip.pressed.connect(_do_equip)
	actions.add_child(_btn_equip)
	_btn_sell = Kit.make_button("Sell", false)
	_btn_sell.custom_minimum_size = Vector2(150, 52)
	_btn_sell.pressed.connect(_do_sell)
	actions.add_child(_btn_sell)

	_refresh_panoply()


func _refresh_panoply() -> void:
	if _detail == null:
		return
	for key in SLOT_KEYS:
		var btn: Button = _equip_btns.get(key)
		if btn == null:
			continue
		btn.text = "  %s" % GameState.equipped_name(key)
		btn.modulate = Color(1.15, 1.08, 0.85) if key == _selected_slot else Color.WHITE

	if _stat_labels.has("atk"):
		_stat_labels["atk"].text = "Strike force  %d" % int(GameState.attack_damage())
	if _stat_labels.has("def"):
		_stat_labels["def"].text = "Ward  ×%.2f dmg taken" % GameState.damage_taken_mult()
	if _stat_labels.has("hp"):
		_stat_labels["hp"].text = "Vitality  %d" % GameState.max_hp()
	if _stat_labels.has("gold"):
		_stat_labels["gold"].text = "Drachmae  %d" % GameState.gold
	if _stat_labels.has("temper"):
		_stat_labels["temper"].text = "Weapon temper  +%d" % GameState.weapon_refine

	for i in range(_bag_cells.size()):
		_bag_cells[i]["entry"] = -1
		(_bag_cells[i]["label"] as Label).text = ""
		(_bag_cells[i]["panel"] as PanelContainer).modulate = Color.WHITE

	for ei in range(GameState.bag.size()):
		var e: Dictionary = GameState.bag[ei]
		var id := str(e.get("id", ""))
		var def: Dictionary = GameState.item_def(id)
		var cells: Vector2i = GameState.item_cells(id)
		var ox := int(e.get("x", 0))
		var oy := int(e.get("y", 0))
		var short := _short_name(str(def.get("name", id)))
		var count := int(e.get("count", 1))
		var label_text := short if count <= 1 else "%s ×%d" % [short, count]
		var kind := str(def.get("kind", ""))
		for dy in cells.y:
			for dx in cells.x:
				var cx := ox + dx
				var cy := oy + dy
				var idx := cy * GameState.BAG_W + cx
				if idx < 0 or idx >= _bag_cells.size():
					continue
				_bag_cells[idx]["entry"] = ei
				var lab2: Label = _bag_cells[idx]["label"]
				lab2.text = label_text if dx == 0 and dy == 0 else "·"
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
		"helmet", "armor":
			return Color(1.05, 1.0, 0.95)
		"consumable":
			return Color(1.0, 1.08, 0.95)
		"scroll", "material":
			return Color(1.05, 1.0, 1.1)
		_:
			return Color(1, 1, 1)


func _short_name(full: String) -> String:
	var parts := full.split(" ")
	if parts.size() <= 2:
		return full
	return "%s %s" % [parts[0], parts[parts.size() - 1]]


func _on_bag_cell_input(event: InputEvent, cell_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ei: int = int(_bag_cells[cell_idx]["entry"])
		if ei < 0:
			return
		_selected_bag = ei
		_selected_slot = ""
		_refresh_panoply()


func _select_equip_slot(key: String) -> void:
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
		lines += "\nWear on: %s" % SLOT_LABELS.get(slot, slot)
	_detail.text = lines


func _update_detail_slot(key: String) -> void:
	if _detail == null:
		return
	var id := str(GameState.equipped.get(key, ""))
	if id == "":
		_detail.text = "%s slot is empty." % SLOT_LABELS.get(key, key)
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
	box.add_theme_constant_override("separation", 10)
	_body.add_child(box)
	box.add_child(Kit.make_label("Your Clan", 22, Kit.INK_GOLD))
	if GameState.clan_name == "":
		box.add_child(Kit.make_label(
			"You walk alone. Found a brotherhood from the world map when the gods will it.",
			15, Kit.INK_SOFT))
	else:
		box.add_child(Kit.make_label(GameState.clan_name, 20, Kit.INK_TITLE))
		if GameState.clan_rank != "":
			box.add_child(Kit.make_label("Rank: %s" % GameState.clan_rank, 15, Kit.INK))
		box.add_child(Kit.make_label(
			"Omphaloi shattered: %d" % GameState.omphaloi_destroyed, 15, Kit.INK_SOFT))


func _close() -> void:
	if hud and hud.has_method("close_panel_from_click"):
		hud.close_panel_from_click()
	else:
		queue_free()
