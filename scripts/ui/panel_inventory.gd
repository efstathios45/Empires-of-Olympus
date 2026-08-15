extends Control
## Inventory — Diablo/PoE-style grid bag (I). Weapons take 1×2 cells; potions,
## helmets, shields, materials and scrolls take 1×1. Full bag blocks pickups.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const CLANS := {
	"Bronze Talons": "Strike first, strike in bronze. Raiders of the east wind.",
	"Sons of Ares": "War is prayer. The crimson phalanx of the south.",
	"The Laurel Order": "Wisdom wields the spear. Keepers of the sacred games.",
}

const CELL := 64
const GAP := 4

var hud: CanvasLayer
var initial_tab: String = "gear"

var _content: VBoxContainer
var _gear_btn: Button
var _clan_btn: Button
var _selected: int = -1
var _detail: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(860, 700)
	center.add_child(panel)

	var margin := Kit.make_margin(28)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	v.add_child(Kit.make_label("Champion of %s" % GameState.empire_data()["name"],
		28, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 18)
	v.add_child(tabs)
	_gear_btn = Kit.make_button("Bag & Spoils", true)
	_gear_btn.custom_minimum_size = Vector2(280, 58)
	_gear_btn.pressed.connect(func() -> void: _show("gear"))
	tabs.add_child(_gear_btn)
	_clan_btn = Kit.make_button("Clan Banner", false)
	_clan_btn.custom_minimum_size = Vector2(280, 58)
	_clan_btn.pressed.connect(func() -> void: _show("clan"))
	tabs.add_child(_clan_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	scroll.add_child(_content)

	var close_btn := Kit.make_button("Close", true)
	close_btn.custom_minimum_size = Vector2(260, 58)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void: hud.close_panel_from_click())
	v.add_child(close_btn)

	GameState.inventory_changed.connect(_on_inv_changed)
	_show(initial_tab)


func _exit_tree() -> void:
	if GameState.inventory_changed.is_connected(_on_inv_changed):
		GameState.inventory_changed.disconnect(_on_inv_changed)


func _on_inv_changed() -> void:
	if initial_tab == "gear" and is_inside_tree():
		_show("gear")


func _show(tab: String) -> void:
	initial_tab = tab
	_selected = -1
	for c in _content.get_children():
		c.queue_free()
	if tab == "clan":
		_build_clan()
	else:
		_build_gear()


func _build_gear() -> void:
	var cd: Dictionary = GameState.class_data()
	var ed: Dictionary = GameState.empire_data()
	_add_line("Level %d %s of %s" % [GameState.level, cd["name"], ed["name"]], 20, Kit.INK_TITLE)
	_add_line("Weapon: %s +%d   •   Damage %d   •   Gold %d" % [
		cd["weapon_name"], GameState.weapon_refine, int(GameState.attack_damage()), GameState.gold], 16)
	_add_line("Weapons fill 2 cells · potions / helms / shields / mats fill 1. Full bag blocks loot.",
		14, Kit.INK_SOFT)
	_content.add_child(Kit.spacer(4))

	var grid_wrap := CenterContainer.new()
	_content.add_child(grid_wrap)
	var grid := _build_grid()
	grid_wrap.add_child(grid)

	_detail = Kit.make_label("Click a cell to inspect. Sell spoils to Kyros in the agora.", 15, Kit.INK_SOFT)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(720, 0)
	_content.add_child(_detail)

	_content.add_child(Kit.spacer(6))
	_add_line("Hotkeys: 1 Health potion · 2 Mana potion · I close", 14, Kit.INK_SOFT)


func _build_grid() -> Control:
	var root := Control.new()
	var gw: int = GameState.BAG_W * CELL + (GameState.BAG_W + 1) * GAP
	var gh: int = GameState.BAG_H * CELL + (GameState.BAG_H + 1) * GAP
	root.custom_minimum_size = Vector2(gw, gh)

	# Empty cell backgrounds.
	for y in GameState.BAG_H:
		for x in GameState.BAG_W:
			var cell := ColorRect.new()
			cell.color = Color(0.78, 0.72, 0.62, 0.55)
			cell.position = Vector2(GAP + x * (CELL + GAP), GAP + y * (CELL + GAP))
			cell.size = Vector2(CELL, CELL)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(cell)

	# Occupied items (drawn once at their origin).
	for i in GameState.bag.size():
		var e: Dictionary = GameState.bag[i]
		var id: String = String(e.get("id", ""))
		var def: Dictionary = GameState.item_def(id)
		var cells: Vector2i = GameState.item_cells(id)
		var ox: int = int(e.get("x", 0))
		var oy: int = int(e.get("y", 0))
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(GAP + ox * (CELL + GAP), GAP + oy * (CELL + GAP))
		btn.size = Vector2(cells.x * CELL + (cells.x - 1) * GAP,
			cells.y * CELL + (cells.y - 1) * GAP)
		var tint: Color = def.get("color", Color(0.65, 0.55, 0.35))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(tint.r, tint.g, tint.b, 0.92)
		sb.border_color = Color(0.25, 0.18, 0.1, 0.9)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		for st in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(st, sb)
		var count: int = int(e.get("count", 1))
		var label := String(def.get("name", id))
		if count > 1:
			label = "%s ×%d" % [label, count]
		btn.text = label
		btn.clip_text = true
		btn.add_theme_font_override("font", Kit.font())
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.04))
		btn.pressed.connect(_on_select.bind(i))
		root.add_child(btn)
	return root


func _on_select(index: int) -> void:
	_selected = index
	if index < 0 or index >= GameState.bag.size():
		return
	var e: Dictionary = GameState.bag[index]
	var id: String = String(e.get("id", ""))
	var def: Dictionary = GameState.item_def(id)
	var cells: Vector2i = GameState.item_cells(id)
	_detail.text = "%s  ·  %dx%d  ·  sells for %d gold each\n%s" % [
		String(def.get("name", id)), cells.x, cells.y,
		GameState.item_sell_price(id), String(def.get("desc", ""))]


func _add_line(text: String, size: int, color: Color = Kit.INK) -> void:
	var l := Kit.make_label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(760, 0)
	_content.add_child(l)


func _build_clan() -> void:
	if GameState.clan_name == "":
		_add_line("You fight alone. Swear an oath to a banner:", 18, Kit.INK)
		_content.add_child(Kit.spacer(6))
		for clan in CLANS:
			var row := VBoxContainer.new()
			row.add_theme_constant_override("separation", 3)
			_content.add_child(row)
			row.add_child(Kit.make_label(String(clan), 19, Kit.INK_TITLE))
			var desc := Kit.make_label(String(CLANS[clan]), 15, Kit.INK_SOFT)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.custom_minimum_size = Vector2(720, 0)
			row.add_child(desc)
			var btn := Kit.make_button("Swear Oath  (+150 gold)", false)
			btn.custom_minimum_size = Vector2(300, 56)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			btn.add_theme_font_size_override("font_size", 18)
			btn.pressed.connect(_on_join.bind(clan))
			row.add_child(btn)
			_content.add_child(Kit.spacer(8))
	else:
		_add_line(GameState.clan_name, 26, Kit.INK_TITLE)
		_add_line(String(CLANS.get(GameState.clan_name, "")), 16, Kit.INK_SOFT)
		_content.add_child(Kit.spacer(8))
		var renown: int = GameState.level * 10 + GameState.weapon_refine * 25 \
			+ GameState.oracle_stones_destroyed * 15
		_add_line("Rank: %s" % GameState.clan_rank, 18)
		_add_line("Renown: %d" % renown, 18, Kit.INK_GOLD)
		var next_rank := "Myrmidon" if GameState.clan_rank == "Hoplite" else "Champion of the Banner"
		var need := 120 if GameState.clan_rank == "Hoplite" else 320
		_add_line("Next rank — %s at %d renown" % [next_rank, need], 16, Kit.INK_SOFT)
		if renown >= need:
			GameState.clan_rank = next_rank
			GameState.clan_changed.emit()


func _on_join(clan: String) -> void:
	GameState.clan_name = clan
	GameState.clan_rank = "Hoplite"
	GameState.add_gold(150)
	GameState.clan_changed.emit()
	AudioManager.play_sfx("ui_confirm")
	_show("clan")
