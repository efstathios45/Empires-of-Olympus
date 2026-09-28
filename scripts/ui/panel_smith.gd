extends Control
## Brontes' forge — weapon refinement (the great gamble) plus potions & scrolls.
## Marble panel: dark ink throughout, the wares list in its own scroll box, and
## buttons kept at their native chunky size instead of stretched across a row.

const Kit = preload("res://scripts/ui/ui_kit.gd")

## panel_scroll content_margin ~118×2 + inner margin 20×2 → keep text inside cream.
const CONTENT_W := 560
const BAD := Color(0.55, 0.08, 0.06)
const WARN := Color(0.60, 0.33, 0.04)

var hud: CanvasLayer

var _weapon_label: Label
var _damage_label: Label
var _rate_label: Label
var _cost_label: Label
var _result_label: Label
var _gold_label: Label
var _scroll_buttons: Dictionary = {}
var _shop_rows: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(864, 640)
	center.add_child(panel)

	var margin := Kit.make_margin(20)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	margin.add_child(v)

	_build_header(v)
	_build_refinery(v)
	_build_wares(v)

	v.add_child(Kit.spacer(4))
	var close_btn := Kit.make_button("Leave", true)
	close_btn.pressed.connect(func() -> void: hud.close_panel_from_click())
	v.add_child(close_btn)

	GameState.gold_changed.connect(func(_g: int) -> void: _refresh())
	GameState.weapon_refined.connect(func(_l: int) -> void: _refresh())
	GameState.potions_changed.connect(func() -> void: _refresh())
	_refresh()

# ── Layout ───────────────────────────────────────────────────────────────

func _build_header(v: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	head.add_child(Kit.make_icon("icon_anvil", 38))
	head.add_child(Kit.make_label("Brontes the Smith", 30, Kit.INK_TITLE))

	var quote := Kit.make_label(
		"\"Steel remembers every hammer-blow. Dare the flames, champion?\"",
		16, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.custom_minimum_size = Vector2(CONTENT_W, 0)
	v.add_child(quote)
	v.add_child(_divider())

func _build_refinery(v: VBoxContainer) -> void:
	v.add_child(Kit.make_label("Refine Your Weapon", 23, Kit.INK_TITLE))
	var warn := Kit.make_label(
		"Failure past +4 drags the weapon back a level — past +6 it can shatter outright.",
		15, Kit.INK_SOFT)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn.custom_minimum_size = Vector2(CONTENT_W, 0)
	v.add_child(warn)

	_weapon_label = Kit.make_label("", 21, Kit.INK)
	v.add_child(_weapon_label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 26)
	v.add_child(stats)
	_damage_label = Kit.make_label("", 17, Kit.INK)
	_damage_label.custom_minimum_size = Vector2(250, 0)
	stats.add_child(_damage_label)
	_rate_label = Kit.make_label("", 17, Kit.INK)
	_rate_label.custom_minimum_size = Vector2(200, 0)
	stats.add_child(_rate_label)
	_cost_label = Kit.make_label("", 17, Kit.INK_GOLD)
	stats.add_child(_cost_label)
	v.add_child(Kit.spacer(2))

	for scroll_id in ["hephaestus", "titan", "oracle"]:
		v.add_child(_make_scroll_row(scroll_id))

	_result_label = Kit.make_label("", 18, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.custom_minimum_size = Vector2(CONTENT_W, 26)
	v.add_child(_result_label)
	v.add_child(_divider())

func _make_scroll_row(scroll_id: String) -> HBoxContainer:
	var s: Dictionary = GameState.SCROLLS[scroll_id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name_label := Kit.make_label(String(s["name"]), 17, Kit.INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(430, 0)
	text.add_child(name_label)
	var desc := Kit.make_label(String(s["desc"]), 14, Kit.INK_SOFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(430, 0)
	text.add_child(desc)

	var btn := Kit.make_button("Use", false)
	btn.pressed.connect(_on_refine.bind(scroll_id))
	row.add_child(btn)
	_scroll_buttons[scroll_id] = btn
	return row

func _build_wares(v: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	head.add_child(Kit.make_icon("icon_gold", 30))
	head.add_child(Kit.make_label("Wares of the Forge", 23, Kit.INK_TITLE))
	var pad := Control.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(pad)
	_gold_label = Kit.make_label("", 20, Kit.INK_GOLD)
	head.add_child(_gold_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(CONTENT_W, 224)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_shop_rows = VBoxContainer.new()
	_shop_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(_shop_rows)

func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.42, 0.32, 0.14, 0.30)
	d.custom_minimum_size = Vector2(CONTENT_W, 2)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

# ── Refresh ──────────────────────────────────────────────────────────────

func _refresh() -> void:
	var cd: Dictionary = GameState.class_data()
	var lvl: int = GameState.weapon_refine
	_weapon_label.text = "%s  +%d" % [cd["weapon_name"], lvl]
	var dmg := GameState.attack_damage()
	if lvl >= GameState.REFINE_MAX:
		_damage_label.text = "Damage %d — perfection" % int(dmg)
		_rate_label.text = ""
		_cost_label.text = ""
	else:
		var next: float = cd["base_dmg"] * (1.0 + (lvl + 1) * GameState.REFINE_DMG_BONUS)
		_damage_label.text = "Damage %d  →  %d" % [int(dmg), int(next)]
		_rate_label.text = "Success %d%%" % int(GameState.REFINE_BASE_RATES[lvl] * 100.0)
		_cost_label.text = "Fee %d gold" % GameState.REFINE_GOLD_COST[lvl]
	_gold_label.text = "Your gold: %d" % GameState.gold
	for scroll_id in _scroll_buttons:
		var count: int = GameState.scrolls.get(scroll_id, 0)
		var btn: Button = _scroll_buttons[scroll_id]
		## Keep kit plaque label short: "Use ×3"
		btn.text = "Use ×%d" % count
		Kit.standardize_button(btn)
	_rebuild_shop()

func _rebuild_shop() -> void:
	for c in _shop_rows.get_children():
		c.queue_free()
	for item_id in GameState.SHOP_ITEMS:
		var item: Dictionary = GameState.SHOP_ITEMS[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_shop_rows.add_child(row)

		var icon := TextureRect.new()
		var icon_path: String = item["icon"]
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var name_label := Kit.make_label(String(item["name"]), 17, Kit.INK)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.custom_minimum_size = Vector2(400, 0)
		text.add_child(name_label)
		var desc := Kit.make_label(String(item["desc"]), 14, Kit.INK_SOFT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(400, 0)
		text.add_child(desc)

		## Short buy label fits the standard plaque (e.g. "Buy 90").
		var btn := Kit.make_button("Buy %d" % int(item["price"]), false)
		btn.pressed.connect(_on_buy.bind(item_id))
		row.add_child(btn)

# ── Actions ──────────────────────────────────────────────────────────────

func _on_refine(scroll_id: String) -> void:
	var result: Dictionary = GameState.refine_weapon(scroll_id)
	_result_label.text = result["message"]
	if result.get("success"):
		_set_result_color(Kit.INK_GOOD)
	elif result.get("destroyed"):
		_set_result_color(BAD)
	elif result.get("downgraded"):
		_set_result_color(WARN)
	else:
		_set_result_color(Kit.INK)
	_refresh()

func _set_result_color(c: Color) -> void:
	_result_label.add_theme_color_override("font_color", c)

func _on_buy(item_id: String) -> void:
	if GameState.buy_item(item_id):
		AudioManager.play_sfx("gold_pickup", -2.0)
		_result_label.text = "Purchased."
		_set_result_color(Kit.INK_GOOD)
	else:
		AudioManager.play_sfx("ui_click", -2.0, 0.8)
		_result_label.text = "Not enough gold."
		_set_result_color(WARN)
	_refresh()
