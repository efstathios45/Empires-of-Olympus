extends Control
## Inventory & clan — your legend at a glance: stats, gear, materials, banner.
## Marble panel, so every line is dark ink and long lines wrap inside a scroll
## box that can never spill past the gold frame.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const CLANS := {
	"Bronze Talons": "Strike first, strike in bronze. Raiders of the east wind.",
	"Sons of Ares": "War is prayer. The crimson phalanx of the south.",
	"The Laurel Order": "Wisdom wields the spear. Keepers of the sacred games.",
}

const TEXT_W := 560

var hud: CanvasLayer
var initial_tab: String = "gear"

var _content: VBoxContainer
var _gear_btn: Button
var _clan_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(780, 640)
	center.add_child(panel)

	var margin := Kit.make_margin(34)
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
	_gear_btn = Kit.make_button("Gear & Spoils", true)
	_gear_btn.custom_minimum_size = Vector2(260, 62)
	_gear_btn.pressed.connect(func() -> void: _show("gear"))
	tabs.add_child(_gear_btn)
	_clan_btn = Kit.make_button("Clan Banner", false)
	_clan_btn.custom_minimum_size = Vector2(260, 62)
	_clan_btn.pressed.connect(func() -> void: _show("clan"))
	tabs.add_child(_clan_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(TEXT_W + 40, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 5)
	scroll.add_child(_content)

	var close_btn := Kit.make_button("Close", true)
	close_btn.custom_minimum_size = Vector2(260, 62)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void: hud.close_panel_from_click())
	v.add_child(close_btn)

	_show(initial_tab)

func _show(tab: String) -> void:
	initial_tab = tab
	for c in _content.get_children():
		c.queue_free()
	if tab == "clan":
		_build_clan()
	else:
		_build_gear()

# ── Gear & spoils ────────────────────────────────────────────────────────

func _build_gear() -> void:
	var cd: Dictionary = GameState.class_data()
	var ed: Dictionary = GameState.empire_data()
	_add_line("Level %d %s of %s" % [GameState.level, cd["name"], ed["name"]], 21, Kit.INK_TITLE)
	_add_line(String(ed["bonus_desc"]), 16, Kit.INK_SOFT)
	_add_line("Glory: %d / %d to the next level" % [GameState.xp, GameState.xp_needed()], 17)
	_add_line("Weapon: %s +%d   •   Damage %d" % [
		cd["weapon_name"], GameState.weapon_refine, int(GameState.attack_damage())], 17)
	_add_line("Skill: %s" % cd["skill_name"], 17)
	_add_line("Health %d   •   Spirit %d" % [GameState.max_hp(), GameState.max_mp()], 17)
	_content.add_child(Kit.spacer(8))

	_add_line("Potions", 20, Kit.INK_TITLE)
	_add_line("Health ×%d   •   Mana ×%d   (keys 1 and 2)" % [
		GameState.health_potions, GameState.mana_potions], 17)
	_content.add_child(Kit.spacer(8))

	_add_line("Refining Scrolls", 20, Kit.INK_TITLE)
	for scroll_id in GameState.SCROLLS:
		var s: Dictionary = GameState.SCROLLS[scroll_id]
		_add_line("%s ×%d" % [s["name"], GameState.scrolls.get(scroll_id, 0)], 16)
	_content.add_child(Kit.spacer(8))

	_add_line("Monster Materials", 20, Kit.INK_TITLE)
	if GameState.materials.is_empty():
		_add_line("None yet — hunt the wilds.", 16, Kit.INK_SOFT)
	else:
		for mat in GameState.materials:
			_add_line("%s ×%d" % [mat, GameState.materials[mat]], 16)

func _add_line(text: String, size: int, color: Color = Kit.INK) -> void:
	var l := Kit.make_label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(TEXT_W, 0)
	_content.add_child(l)

# ── Clan ─────────────────────────────────────────────────────────────────

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
			desc.custom_minimum_size = Vector2(TEXT_W, 0)
			row.add_child(desc)
			var btn := Kit.make_button("Swear Oath  (+150 gold)", false)
			btn.custom_minimum_size = Vector2(300, 60)
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
