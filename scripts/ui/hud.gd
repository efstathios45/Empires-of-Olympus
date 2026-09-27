extends CanvasLayer
## HUD — health/mana/gold, quest tracker, hotbar, boss bar, prompts, overlays,
## the world map, and the panel host (dialogue, smithy, inventory, pause).
## Player reads `ui_open` to freeze combat input while a panel is up.
##
## Readability rules (see ui_kit.gd): widgets that float over the bright 3D
## world sit on Kit.make_dark_panel() and use Kit.make_hud_label(); anything
## on the cream marble panel uses DARK ink (Kit.INK / INK_TITLE / …).

const Kit = preload("res://scripts/ui/ui_kit.gd")
const DialoguePanel = preload("res://scripts/ui/panel_dialogue.gd")
const SmithPanel = preload("res://scripts/ui/panel_smith.gd")
const InventoryPanel = preload("res://scripts/ui/panel_inventory.gd")
const PausePanel = preload("res://scripts/ui/panel_pause.gd")
const ChatOverlay = preload("res://scripts/ui/chat_overlay.gd")

# HUD text tints (light — always on a dark slate panel).
const HUD_GOLD := Color(1.0, 0.88, 0.55)
const HUD_CREAM := Color(0.97, 0.94, 0.86)
const HUD_GREEN := Color(0.62, 0.95, 0.62)

# ── World map ────────────────────────────────────────────────────────────
## The playable world spans -150..+150 on both x and z (300 units square).
const MAP_WORLD_SPAN := 300.0
const MAP_FIELD_PX := 460.0

## Region discs, drawn to scale. Names are placed by _build_map_field() at
## hand-tuned pixels so no two labels ever collide on the field.
const MAP_REGIONS := [
	{"name": "Sanctuary", "pos": Vector2(0.0, 0.0), "r": 30.0,
		"col": Color(0.90, 0.82, 0.52, 0.9), "icon": "icon_laurel"},
	{"name": "Wolf & Boar Hunting Grounds", "pos": Vector2(0.0, -80.0), "r": 17.0,
		"col": Color(0.52, 0.44, 0.22, 0.85), "icon": "icon_sword"},
	{"name": "Satyr & Harpy Slopes", "pos": Vector2(80.0, -20.0), "r": 17.0,
		"col": Color(0.36, 0.50, 0.26, 0.85), "icon": "icon_sword"},
	{"name": "Centaur & Gorgon Wilds", "pos": Vector2(-80.0, 20.0), "r": 17.0,
		"col": Color(0.30, 0.38, 0.54, 0.85), "icon": "icon_sword"},
	{"name": "Minotaur's Arena", "pos": Vector2(0.0, 105.0), "r": 26.0,
		"col": Color(0.62, 0.18, 0.16, 0.88), "icon": "icon_skull"},
]

const MAP_STONES := [Vector2(40.0, -70.0), Vector2(-70.0, -25.0), Vector2(35.0, 55.0)]

var ui_open: bool = false

var _player: Node3D
var _world: Node3D
var _chat: Control = null

var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _xp_bar: ProgressBar
var _hp_text: Label
var _mp_text: Label
var _level_text: Label
var _gold_text: Label
var _quest_title: Label
var _quest_lines: Label
var _quest_hint: Label
var _prompt: Label
var _potion1_text: Label
var _potion2_text: Label
var _skill_cd_text: Label
var _boss_box: Control
var _boss_bar: ProgressBar
var _vignette: ColorRect
var _announce: Label
var _death_overlay: Control
var _victory_overlay: Control
var _victory_stats: Label
var _open_panel: Control = null
var _map_field: Control = null
var _map_marker: Control = null
var _map_where: Label = null
var _skill_cd_left: float = 0.0
var _track_timer: float = 0.0
var _boss_timer: float = 0.0
var _victory_shown: bool = false
var _last_hp: float = -1.0

func setup(p: Node3D, w: Node3D) -> void:
	_player = p
	_world = w
	_build()
	_connect_signals()

func _build() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/ui/theme.tres"):
		root.theme = load("res://assets/ui/theme.tres")
	add_child(root)

	# Damage vignette goes in FIRST so it tints the world, not the readouts.
	_vignette = ColorRect.new()
	_vignette.color = Color(0.75, 0.05, 0.05, 1.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	root.add_child(_vignette)

	_chat = ChatOverlay.new()
	_chat.name = "Chat"
	root.add_child(_chat)
	_chat.chat_opened.connect(_on_chat_opened)
	_chat.chat_closed.connect(_on_chat_closed)

	_build_vitals(root)
	_build_tracker(root)
	_build_hotbar(root)
	_build_boss_bar(root)
	_build_map_hint(root)

	# ── Interact prompt (drawn straight over the world: outlined light text) ──
	_prompt = Kit.make_hud_label("", 21, HUD_CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-320, -150)
	_prompt.custom_minimum_size = Vector2(640, 32)
	_prompt.size = Vector2(640, 32)
	root.add_child(_prompt)

	# ── XP bar (hugging the bottom edge, fully on screen) ──
	_xp_bar = Kit.make_bar(Color(0.85, 0.7, 0.25), 10)
	_xp_bar.custom_minimum_size = Vector2(10, 10)
	root.add_child(_xp_bar)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_xp_bar.offset_top = -14.0
	_xp_bar.offset_bottom = -4.0

	# ── Centre announcements (over the world) ──
	_announce = Kit.make_hud_label("", 36, HUD_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_announce.set_anchors_preset(Control.PRESET_CENTER)
	_announce.position = Vector2(-420, -180)
	_announce.custom_minimum_size = Vector2(840, 60)
	_announce.size = Vector2(840, 60)
	_announce.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_announce.modulate.a = 0.0
	root.add_child(_announce)

	_build_death_overlay(root)
	_build_victory_overlay(root)
	_refresh_all()

# ── HUD widgets ──────────────────────────────────────────────────────────

func _build_vitals(root: Control) -> void:
	var box := Kit.make_dark_panel(0.66)
	box.position = Vector2(24, 18)
	box.custom_minimum_size = Vector2(336, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	var vitals := VBoxContainer.new()
	vitals.add_theme_constant_override("separation", 6)
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(vitals)

	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_child(level_row)
	level_row.add_child(Kit.make_icon("icon_laurel", 28))
	_level_text = Kit.make_hud_label("Level 1", 19, HUD_GOLD)
	level_row.add_child(_level_text)
	var gold_spacer := Control.new()
	gold_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gold_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_child(gold_spacer)
	level_row.add_child(Kit.make_icon("icon_gold", 24))
	_gold_text = Kit.make_hud_label("0", 19, Color(1.0, 0.84, 0.38))
	level_row.add_child(_gold_text)

	_hp_bar = Kit.make_bar(Color(0.78, 0.18, 0.16), 22)
	_hp_bar.custom_minimum_size = Vector2(196, 22)
	_hp_text = Kit.make_hud_label("", 15, HUD_CREAM)
	vitals.add_child(_make_bar_row("icon_health", _hp_bar, _hp_text))

	_mp_bar = Kit.make_bar(Color(0.2, 0.42, 0.85), 22)
	_mp_bar.custom_minimum_size = Vector2(196, 22)
	_mp_text = Kit.make_hud_label("", 15, HUD_CREAM)
	vitals.add_child(_make_bar_row("icon_mana", _mp_bar, _mp_text))

func _make_bar_row(icon_name: String, bar: ProgressBar, text: Label) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(Kit.make_icon(icon_name, 24))
	row.add_child(bar)
	row.add_child(text)
	return row

func _build_tracker(root: Control) -> void:
	var tracker := Kit.make_dark_panel(0.66)
	tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tracker.position = Vector2(-372, 18)
	tracker.custom_minimum_size = Vector2(348, 0)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tracker)

	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 5)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_child(tv)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(head)
	head.add_child(Kit.make_icon("icon_quest", 24))
	_quest_title = Kit.make_hud_label("", 19, HUD_GOLD)
	_quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_title.custom_minimum_size = Vector2(280, 0)
	head.add_child(_quest_title)

	_quest_lines = Kit.make_hud_label("", 16, HUD_CREAM)
	_quest_lines.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_lines.custom_minimum_size = Vector2(316, 0)
	tv.add_child(_quest_lines)

	_quest_hint = Kit.make_hud_label("", 15, HUD_GREEN)
	_quest_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_hint.custom_minimum_size = Vector2(316, 0)
	tv.add_child(_quest_hint)

func _build_hotbar(root: Control) -> void:
	var hotbar := HBoxContainer.new()
	hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.position = Vector2(-152, -114)
	hotbar.add_theme_constant_override("separation", 12)
	hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hotbar)

	var slot1 := _make_slot("icon_potion", "1")
	_potion1_text = slot1.get_meta("count_label")
	hotbar.add_child(slot1)
	var slot2 := _make_slot("icon_mana", "2")
	_potion2_text = slot2.get_meta("count_label")
	hotbar.add_child(slot2)
	var skill_icon := "icon_sword"
	if GameState.player_class == "toxotes":
		skill_icon = "icon_laurel"
	elif GameState.player_class == "magos":
		skill_icon = "icon_gem"
	var slot3 := _make_slot(skill_icon, "Q")
	_skill_cd_text = slot3.get_meta("count_label")
	hotbar.add_child(slot3)

func _make_slot(icon_name: String, key: String) -> PanelContainer:
	var slot := Kit.make_dark_panel(0.7)
	slot.custom_minimum_size = Vector2(92, 92)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(v)
	v.add_child(Kit.make_icon(icon_name, 40))
	var count := Kit.make_hud_label(key, 15, HUD_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(count)
	slot.set_meta("count_label", count)
	return slot

func _build_boss_bar(root: Control) -> void:
	_boss_box = Kit.make_dark_panel(0.72)
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.position = Vector2(-266, 20)
	_boss_box.custom_minimum_size = Vector2(532, 0)
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_box)

	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 12)
	bh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_child(bh)
	bh.add_child(Kit.make_icon("icon_skull", 36))
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bh.add_child(bv)
	bv.add_child(Kit.make_hud_label("The Minotaur", 20, Color(1.0, 0.74, 0.52)))
	_boss_bar = Kit.make_bar(Color(0.62, 0.1, 0.3), 18)
	_boss_bar.custom_minimum_size = Vector2(440, 18)
	bv.add_child(_boss_bar)

## Small always-visible reminder that the world map exists (click or press M).
func _build_map_hint(root: Control) -> void:
	var hint := Kit.make_dark_panel(0.6)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-186, -84)
	hint.custom_minimum_size = Vector2(162, 56)
	hint.mouse_filter = Control.MOUSE_FILTER_STOP
	hint.tooltip_text = "World map (M)"
	root.add_child(hint)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_child(h)
	h.add_child(Kit.make_icon("icon_map", 30))
	h.add_child(Kit.make_hud_label("M  Map", 17, HUD_GOLD))
	hint.gui_input.connect(_on_map_hint_input)

func _on_map_hint_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT and not ui_open:
		toggle_map()

# ── Overlays ─────────────────────────────────────────────────────────────

func _build_death_overlay(root: Control) -> void:
	_death_overlay = CenterContainer.new()
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	root.add_child(_death_overlay)

	var p := Kit.make_panel(false)
	p.custom_minimum_size = Vector2(780, 360)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(p)
	var margin := Kit.make_margin(20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(margin)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v)

	v.add_child(Kit.make_label("You Have Fallen", 40, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	var body := Kit.make_label(
		"The Fates carry you back to the sanctuary.\nA tithe of your gold is lost.",
		19, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(480, 0)
	v.add_child(body)
	v.add_child(Kit.make_label("Rise again, champion.", 17, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

func _build_victory_overlay(root: Control) -> void:
	_victory_overlay = CenterContainer.new()
	_victory_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_overlay.visible = false
	root.add_child(_victory_overlay)
	_victory_overlay.add_child(Kit.make_dimmer())

	var p := Kit.make_panel(false)
	p.custom_minimum_size = Vector2(860, 540)
	_victory_overlay.add_child(p)
	var margin := Kit.make_margin(20)
	p.add_child(margin)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	var crown := Kit.make_icon("icon_laurel", 76)
	crown.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(crown)
	v.add_child(Kit.make_label("Legend of Hellas!", 44, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))

	_victory_stats = Kit.make_label("", 20, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_victory_stats.name = "VictoryStats"
	_victory_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_victory_stats.custom_minimum_size = Vector2(520, 0)
	v.add_child(_victory_stats)

	var flavour := Kit.make_label(
		"The curse is broken. The wilds are yours to wander — the forge still burns, and greater glory awaits.",
		18, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavour.custom_minimum_size = Vector2(520, 0)
	v.add_child(flavour)
	v.add_child(Kit.spacer(6))

	var btn := Kit.make_button("Continue", true)
	btn.pressed.connect(_close_victory)
	v.add_child(btn)

func _close_victory() -> void:
	_victory_overlay.visible = false
	_set_ui_open(false, true)

func show_victory() -> void:
	if _victory_shown:
		return
	_victory_shown = true
	if _victory_stats != null:
		_victory_stats.text = "Level %d %s of %s   •   Weapon +%d   •   %d gold" % [
			GameState.level, GameState.class_data()["name"],
			GameState.empire_data()["name"], GameState.weapon_refine, GameState.gold]
	_victory_overlay.visible = true
	_set_ui_open(true)

# ── Signals ──────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	_player.health_changed.connect(_on_health)
	_player.mana_changed.connect(_on_mana)
	_player.died.connect(func() -> void: _death_overlay.visible = true)
	_player.respawned.connect(func() -> void: _death_overlay.visible = false)
	_player.skill_cooldown_started.connect(func(d: float) -> void: _skill_cd_left = d)
	GameState.gold_changed.connect(func(_g: int) -> void: _refresh_all())
	GameState.xp_changed.connect(func(_x: int, _n: int, _l: int) -> void: _refresh_all())
	GameState.potions_changed.connect(func() -> void: _refresh_all())
	GameState.level_up.connect(_on_level_up)
	GameState.quest_advanced.connect(func(_id: String, _i: int) -> void: _refresh_all())

func _on_level_up(new_level: int) -> void:
	_announce.text = "Level %d — the gods favor you!" % new_level
	_announce.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(_announce, "modulate:a", 0.0, 0.8)

## Floating notice over the world — NPC chatter routes here (see npc.gd), so
## their remarks are readable instead of only floating above their heads.
func show_announcement(text: String) -> void:
	if _announce == null:
		return
	_announce.text = text
	_announce.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(_announce, "modulate:a", 0.0, 0.8)

func _on_health(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = maxf(hp, 0.0)
	_hp_text.text = "%d / %d" % [int(maxf(hp, 0.0)), int(max_hp)]
	if _last_hp >= 0.0 and hp < _last_hp:
		_vignette.modulate.a = 0.4
		var tween := create_tween()
		tween.tween_property(_vignette, "modulate:a", 0.0, 0.6)
	_last_hp = hp

func _on_mana(mp: float, max_mp: float) -> void:
	_mp_bar.max_value = max_mp
	_mp_bar.value = mp
	_mp_text.text = "%d / %d" % [int(mp), int(max_mp)]

func _refresh_all() -> void:
	if _player == null:
		return
	_level_text.text = "Level %d  %s" % [GameState.level, GameState.class_data()["name"]]
	_gold_text.text = "%d δρ" % GameState.gold
	_potion1_text.text = "1  ×%d" % GameState.health_potions
	_potion2_text.text = "2  ×%d" % GameState.mana_potions
	_xp_bar.max_value = GameState.xp_needed()
	_xp_bar.value = GameState.xp
	_on_health(_player.get("hp"), GameState.max_hp())
	_on_mana(_player.get("mp"), GameState.max_mp())
	_refresh_quest()

func _refresh_quest() -> void:
	var q: Dictionary = GameState.current_quest()
	if q.is_empty():
		_quest_title.text = "All Trials Complete"
		_quest_lines.text = "Wander, refine, and grow stronger."
		_quest_hint.text = ""
		return
	_quest_title.text = q["title"]
	_quest_lines.text = GameState.quest_progress_text()
	if GameState.is_quest_objective_done():
		_quest_hint.text = "Return to Priestess Melite"
	else:
		_quest_hint.text = ""

# ── Per-frame ────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _player == null:
		return
	# Skill cooldown sweep.
	if _skill_cd_left > 0.0:
		_skill_cd_left -= delta
		_skill_cd_text.text = "%d" % ceili(_skill_cd_left)
		if _skill_cd_left <= 0.0:
			_skill_cd_text.text = "Q"
	# Interact prompt.
	var target: Node3D = null
	if _world != null and not ui_open and _world.has_method("get_nearest_interactable"):
		target = _world.get_nearest_interactable(_player.global_position)
	if target != null and target.has_method("get_prompt"):
		_prompt.text = "[E]  %s" % target.get_prompt()
	else:
		_prompt.text = ""
	# Tracker + boss polling.
	_track_timer -= delta
	if _track_timer <= 0.0:
		_track_timer = 0.5
		_refresh_quest()
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = 0.3
		_refresh_boss_bar()
	# Live "you are here" marker while the map is open.
	if is_instance_valid(_map_marker):
		_update_map_marker()

func _refresh_boss_bar() -> void:
	var boss: Node3D = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("is_boss") == true and e.get("dead") == false:
			if e.global_position.distance_to(_player.global_position) < 45.0:
				boss = e
			break
	if boss == null:
		_boss_box.visible = false
		return
	_boss_box.visible = true
	_boss_bar.max_value = boss.get("cfg")["hp"]
	_boss_bar.value = maxf(boss.get("hp"), 0.0)

# ── Input & panels ───────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	## Enter opens chat when no full panel is up; while typing, LineEdit owns Enter.
	if event.is_action_pressed("chat"):
		if _chat != null and _chat.get("is_open"):
			return
		if _open_panel != null:
			return
		if _victory_overlay != null and _victory_overlay.visible:
			return
		if _death_overlay != null and _death_overlay.visible:
			return
		if _chat != null and _chat.has_method("open_chat"):
			_chat.call("open_chat")
			get_viewport().set_input_as_handled()
		return
	if _chat != null and _chat.get("is_open"):
		## Block other hotkeys while composing a message.
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			_chat.call("close_chat")
			_set_ui_open(false, true)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not ui_open:
		if _world and _player:
			var target: Node3D = _world.get_nearest_interactable(_player.global_position)
			if target and target.has_method("interact"):
				target.interact()
	elif event.is_action_pressed("map"):
		toggle_map()
	elif event.is_action_pressed("inventory"):
		toggle_inventory("gear")
	elif event.is_action_pressed("clan"):
		toggle_inventory("clan")
	elif event.is_action_pressed("pause"):
		if _open_panel != null:
			_close_panel(false)
		elif _victory_overlay.visible:
			pass
		else:
			toggle_pause()


func _on_chat_opened() -> void:
	## Freeze combat/movement while typing; mouse free for the text field.
	_set_ui_open(true)


func _on_chat_closed() -> void:
	if _open_panel == null and not _victory_overlay.visible:
		_set_ui_open(false, true)

func open_dialogue(_npc: Node3D) -> void:
	_open(DialoguePanel.new())

func open_smith(_npc: Node3D) -> void:
	_open(SmithPanel.new())

func toggle_inventory(tab: String = "gear") -> void:
	if _open_panel is InventoryPanel:
		_close_panel(false)
	else:
		var p := InventoryPanel.new()
		p.initial_tab = tab
		_open(p)

func toggle_pause() -> void:
	if _open_panel is PausePanel:
		_close_panel(true)
	else:
		_open(PausePanel.new())

## The world map rides the same panel host as every other panel, so opening it
## sets `ui_open` and the player script freezes combat/movement.
func toggle_map() -> void:
	if _open_panel != null and _open_panel.has_meta("is_map"):
		_close_panel(false)
	else:
		_clear_map_refs()
		_open(_build_map_panel())

func _open(panel: Control) -> void:
	if _chat != null and _chat.get("is_open") and _chat.has_method("close_chat"):
		_chat.call("close_chat", false)
	if _open_panel != null:
		_open_panel.queue_free()
	if not panel.has_meta("is_map"):
		_clear_map_refs()
	_open_panel = panel
	add_child(panel)
	# Offsets too — plain anchors would leave the panel a zero-size rect.
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.set("hud", self)
	_set_ui_open(true)
	AudioManager.play_sfx("ui_click", -6.0)

func _close_panel(recapture: bool) -> void:
	if _open_panel != null:
		_open_panel.queue_free()
		_open_panel = null
	_clear_map_refs()
	_set_ui_open(false, recapture)

func _clear_map_refs() -> void:
	_map_field = null
	_map_marker = null
	_map_where = null

func _set_ui_open(open: bool, recapture: bool = false) -> void:
	ui_open = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else (
		Input.MOUSE_MODE_CAPTURED if recapture else Input.mouse_mode)

# ── The Map of Hellas ────────────────────────────────────────────────────
# A schematic drawn from plain Controls: parchment field, coloured region
# discs, icon pins, and a live "you are here" marker.

## World (x, z) → pixel inside the map field. -Z is north (top of the map).
func _world_to_map(world_xz: Vector2) -> Vector2:
	var s: float = MAP_FIELD_PX / MAP_WORLD_SPAN
	return (world_xz + Vector2(MAP_WORLD_SPAN * 0.5, MAP_WORLD_SPAN * 0.5)) * s

func _build_map_panel() -> Control:
	var root := Control.new()
	root.name = "MapPanel"
	root.set_meta("is_map", true)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := Kit.make_panel(false)
	center.add_child(panel)
	var margin := Kit.make_margin(20)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	head.add_child(Kit.make_icon("icon_map", 40))
	head.add_child(Kit.make_label("Map of Hellas", 32, Kit.INK_TITLE))

	_map_where = Kit.make_label("", 18, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_map_where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_where.custom_minimum_size = Vector2(MAP_FIELD_PX, 0)
	v.add_child(_map_where)

	var field_center := CenterContainer.new()
	v.add_child(field_center)
	_map_field = _build_map_field()
	field_center.add_child(_map_field)

	v.add_child(_build_map_legend())
	v.add_child(Kit.spacer(4))

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(close_row)
	var close_btn := Kit.make_button("Close", true)
	close_btn.pressed.connect(close_panel_from_click)
	close_row.add_child(close_btn)

	_update_map_marker()
	return root

func _build_map_field() -> Panel:
	var field := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.81, 0.74, 0.56)
	sb.border_color = Color(0.40, 0.30, 0.13)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	field.add_theme_stylebox_override("panel", sb)
	field.custom_minimum_size = Vector2(MAP_FIELD_PX, MAP_FIELD_PX)
	field.size = Vector2(MAP_FIELD_PX, MAP_FIELD_PX)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_add_map_grid(field)

	# Region discs, drawn to scale from their world radii.
	for entry in MAP_REGIONS:
		var r: Dictionary = entry
		var pos: Vector2 = r["pos"]
		var radius: float = r["r"]
		var col: Color = r["col"]
		var dia: float = radius * 2.0 * (MAP_FIELD_PX / MAP_WORLD_SPAN)
		var disc := _map_circle(dia, col, Color(0.28, 0.20, 0.09, 0.85))
		disc.position = _world_to_map(pos) - Vector2(dia, dia) * 0.5
		field.add_child(disc)
		var ic := Kit.make_icon(String(r["icon"]), 26)
		ic.position = _world_to_map(pos) - Vector2(13, 13)
		ic.size = Vector2(26, 26)
		field.add_child(ic)

	# Region names — hand-placed boxes so no two ever collide on the field.
	_add_map_label(field, "Wolf & Boar Hunting Grounds", Vector2(145, 32), Vector2(170, 46))
	_add_map_label(field, "Satyr & Harpy Slopes", Vector2(286, 124), Vector2(170, 46))
	_add_map_label(field, "Sanctuary", Vector2(282, 219), Vector2(140, 26))
	_add_map_label(field, "Centaur & Gorgon Wilds", Vector2(10, 291), Vector2(130, 46))
	_add_map_label(field, "Minotaur's Arena", Vector2(145, 328), Vector2(170, 26))

	# The three cursed Oracle Stones.
	for stone_pos in MAP_STONES:
		var sp: Vector2 = stone_pos
		var gem := Kit.make_icon("icon_gem", 22)
		gem.position = _world_to_map(sp) - Vector2(11, 11)
		gem.size = Vector2(22, 22)
		field.add_child(gem)

	# Compass.
	var north := Kit.make_label("N", 18, Color(0.35, 0.25, 0.10), HORIZONTAL_ALIGNMENT_CENTER)
	north.position = Vector2(MAP_FIELD_PX * 0.5 - 20, 6)
	north.size = Vector2(40, 24)
	field.add_child(north)

	# "You are here" — added last so it draws above every pin.
	_map_marker = _map_circle(20.0, Color(1.0, 0.86, 0.25, 1.0), Color(0.15, 0.10, 0.04))
	field.add_child(_map_marker)
	var pulse := _map_marker.create_tween()
	pulse.set_loops()
	pulse.tween_property(_map_marker, "modulate:a", 0.35, 0.55)
	pulse.tween_property(_map_marker, "modulate:a", 1.0, 0.55)
	return field

func _add_map_grid(field: Panel) -> void:
	var line_col := Color(0.40, 0.30, 0.13, 0.20)
	for i in 3:
		var t: float = MAP_FIELD_PX * (0.25 * float(i + 1))
		var vline := ColorRect.new()
		vline.color = line_col
		vline.position = Vector2(t, 0)
		vline.size = Vector2(1, MAP_FIELD_PX)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field.add_child(vline)
		var hline := ColorRect.new()
		hline.color = line_col
		hline.position = Vector2(0, t)
		hline.size = Vector2(MAP_FIELD_PX, 1)
		hline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field.add_child(hline)

func _map_circle(diameter: float, fill: Color, border: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(diameter * 0.5))
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(diameter, diameter)
	p.size = Vector2(diameter, diameter)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _add_map_label(field: Panel, text: String, at: Vector2, box: Vector2) -> void:
	var l := Kit.make_label(text, 14, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(box.x, 0)
	l.position = at
	l.size = box
	field.add_child(l)

func _build_map_legend() -> HBoxContainer:
	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 18)
	legend.add_child(_map_circle(16.0, Color(1.0, 0.86, 0.25), Color(0.15, 0.10, 0.04)))
	legend.add_child(Kit.make_label("You", 16, Kit.INK))
	legend.add_child(Kit.make_icon("icon_gem", 20))
	legend.add_child(Kit.make_label("Oracle Stone", 16, Kit.INK))
	legend.add_child(Kit.make_icon("icon_skull", 20))
	legend.add_child(Kit.make_label("Boss lair", 16, Kit.INK))
	legend.add_child(Kit.make_label("Esc or M to close", 16, Kit.INK_SOFT))
	return legend

func _update_map_marker() -> void:
	if not is_instance_valid(_map_marker) or _player == null:
		return
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	_map_marker.position = _world_to_map(here) - Vector2(10, 10)
	if is_instance_valid(_map_where):
		_map_where.text = "You stand at %s" % _nearest_region_name(here)

func _nearest_region_name(here: Vector2) -> String:
	var best := "the open wilds"
	var best_d := 999999.0
	for entry in MAP_REGIONS:
		var r: Dictionary = entry
		var pos: Vector2 = r["pos"]
		var d: float = here.distance_to(pos)
		if d < best_d:
			best_d = d
			best = String(r["name"])
	if best_d > 55.0:
		return "the open wilds"
	return best

## Called by panels' Close buttons (a real click, so recapture is safe).
func close_panel_from_click() -> void:
	_close_panel(true)
