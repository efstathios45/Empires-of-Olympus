extends CanvasLayer








const Kit = preload("res://scripts/ui/ui_kit.gd")
const DialoguePanel = preload("res://scripts/ui/panel_dialogue.gd")
const SmithPanel = preload("res://scripts/ui/panel_smith.gd")
const MosaicPanel = preload("res://scripts/ui/panel_mosaic.gd")
const InventoryPanel = preload("res://scripts/ui/panel_inventory.gd")
const PausePanel = preload("res://scripts/ui/panel_pause.gd")
const ShopPanel = preload("res://scripts/ui/panel_shop.gd")
const PlayerMenu = preload("res://scripts/ui/panel_player_menu.gd")
const TradePanel = preload("res://scripts/ui/panel_trade.gd")
const SocialInvite = preload("res://scripts/ui/panel_social_invite.gd")
const WhisperPanel = preload("res://scripts/ui/panel_whisper.gd")
const ChatOverlay = preload("res://scripts/ui/chat_overlay.gd")
const HellasMapData = preload("res://scripts/world/hellas_map_data.gd")


const HUD_GOLD: = Color(1.0, 0.88, 0.55)
const HUD_CREAM: = Color(0.97, 0.94, 0.86)
const HUD_GREEN: = Color(0.62, 0.95, 0.62)
const HUD_WAR: = Color(1.0, 0.55, 0.42)



const MAP_WORLD_SPAN: = HellasMapData.MAP_WORLD_SPAN
const MAP_FIELD_PX: = 520.0



const MAP_STONES: = [
	Vector2(40.0, -70.0), Vector2(-70.0, -25.0), Vector2(35.0, 55.0),
	Vector2(-200.0, 240.0), Vector2(-280.0, 180.0),
	Vector2(200.0, -220.0), Vector2(280.0, -150.0),
	Vector2(0.0, 230.0),
	Vector2(200.0, 60.0), Vector2(240.0, 100.0),
	Vector2(-160.0, -140.0), Vector2(20.0, -280.0),
]

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
var _skill2_cd_text: Label
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
var _party_markers: Dictionary = {}
var _map_where: Label = null
var _skill_cd_left: float = 0.0
var _skill2_cd_left: float = 0.0
var _track_timer: float = 0.0
var _boss_timer: float = 0.0
var _tutorial_timer: float = 1.2
var _victory_shown: bool = false
var _last_hp: float = -1.0
var _whisper: Control = null
var _invite_queue: Array = []
var _invite_showing: Control = null

func setup(p: Node3D, w: Node3D) -> void :
	_player = p
	_world = w
	GameCursor.apply()
	_build()
	_connect_signals()
	if SocialSystem != null:
		if not SocialSystem.trade_opened.is_connected(_on_trade_opened):
			SocialSystem.trade_opened.connect(_on_trade_opened)
		if not SocialSystem.invite_received.is_connected(_on_social_invite):
			SocialSystem.invite_received.connect(_on_social_invite)
		if not SocialSystem.invite_result.is_connected(_on_invite_result):
			SocialSystem.invite_result.connect(_on_invite_result)


func _on_trade_opened(peer_id: int, their_name: String) -> void:
	open_trade(peer_id, their_name)


func _on_social_invite(kind: String, from_peer: int, from_name: String, data: Dictionary) -> void:
	if kind == "whisper_msg":
		open_whisper(from_peer, from_name, String(data.get("text", "")))
		show_announcement("Whisper from %s" % from_name)
		return
	_invite_queue.append({
		"kind": kind, "from_peer": from_peer, "from_name": from_name, "data": data
	})
	_show_next_invite()


func _on_invite_result(kind: String, accepted: bool, peer_name: String) -> void:
	if peer_name == "":
		return
	if accepted:
		show_announcement("%s accepted your %s." % [peer_name, kind])
	else:
		show_announcement("%s declined your %s." % [peer_name, kind])


func _show_next_invite() -> void:
	if _invite_showing != null and is_instance_valid(_invite_showing):
		return
	if _invite_queue.is_empty():
		return
	var item: Dictionary = _invite_queue.pop_front()
	var dlg: = SocialInvite.new()
	dlg.kind = String(item.get("kind", "friend"))
	dlg.from_peer = int(item.get("from_peer", 0))
	dlg.from_name = String(item.get("from_name", "Champion"))
	dlg.payload = item.get("data", {})
	dlg.answered.connect(func(ok: bool) -> void:
		_invite_showing = null
		SocialSystem.respond_invite(dlg.kind, dlg.from_peer, ok, dlg.payload)
		_show_next_invite()
	)
	_invite_showing = dlg
	add_child(dlg)
	AudioManager.play_sfx("ui_click", -4.0)

func _build() -> void :
	var root: = Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/ui/theme.tres"):
		root.theme = load("res://assets/ui/theme.tres")
	add_child(root)


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


	_prompt = Kit.make_hud_label("", 21, HUD_CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-320, -150)
	_prompt.custom_minimum_size = Vector2(640, 32)
	_prompt.size = Vector2(640, 32)
	root.add_child(_prompt)


	_xp_bar = Kit.make_bar(Color(0.85, 0.7, 0.25), 10)
	_xp_bar.custom_minimum_size = Vector2(10, 10)
	root.add_child(_xp_bar)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_xp_bar.offset_top = -14.0
	_xp_bar.offset_bottom = -4.0


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



func _build_vitals(root: Control) -> void :
	var box: = Kit.make_dark_panel(0.66)
	box.position = Vector2(24, 18)
	box.custom_minimum_size = Vector2(336, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	var vitals: = VBoxContainer.new()
	vitals.add_theme_constant_override("separation", 6)
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(vitals)

	var level_row: = HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_child(level_row)
	level_row.add_child(Kit.make_icon("icon_laurel", 28))
	_level_text = Kit.make_hud_label("Level 1", 19, HUD_GOLD)
	level_row.add_child(_level_text)
	var gold_spacer: = Control.new()
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
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(Kit.make_icon(icon_name, 24))
	row.add_child(bar)
	row.add_child(text)
	return row

func _build_tracker(root: Control) -> void :
	var tracker: = Kit.make_dark_panel(0.66)
	tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tracker.position = Vector2(-372, 18)
	tracker.custom_minimum_size = Vector2(348, 0)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tracker)

	var tv: = VBoxContainer.new()
	tv.add_theme_constant_override("separation", 5)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.add_child(tv)

	var head: = HBoxContainer.new()
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

func _build_hotbar(root: Control) -> void :
	var hotbar: = HBoxContainer.new()
	hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.position = Vector2(-152, -114)
	hotbar.add_theme_constant_override("separation", 12)
	hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hotbar)

	var slot1: = _make_slot("icon_potion", "1")
	_potion1_text = slot1.get_meta("count_label")
	hotbar.add_child(slot1)
	var slot2: = _make_slot("icon_mana", "2")
	_potion2_text = slot2.get_meta("count_label")
	hotbar.add_child(slot2)
	var skill_icon: = "icon_sword"
	if GameState.player_class == "toxotes":
		skill_icon = "icon_laurel"
	elif GameState.player_class == "magos":
		skill_icon = "icon_gem"
	var slot3: = _make_slot(skill_icon, "Q")
	_skill_cd_text = slot3.get_meta("count_label")
	hotbar.add_child(slot3)
	var slot4: = _make_slot("icon_laurel" if GameState.player_class != "magos" else "icon_gem", "R")
	_skill2_cd_text = slot4.get_meta("count_label")
	hotbar.add_child(slot4)

func _make_slot(icon_name: String, key: String) -> PanelContainer:
	var slot: = Kit.make_dark_panel(0.7)
	slot.custom_minimum_size = Vector2(92, 92)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v: = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(v)
	v.add_child(Kit.make_icon(icon_name, 40))
	var count: = Kit.make_hud_label(key, 15, HUD_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(count)
	slot.set_meta("count_label", count)
	return slot

func _build_boss_bar(root: Control) -> void :
	_boss_box = Kit.make_dark_panel(0.72)
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.position = Vector2(-266, 20)
	_boss_box.custom_minimum_size = Vector2(532, 0)
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_box)

	var bh: = HBoxContainer.new()
	bh.add_theme_constant_override("separation", 12)
	bh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_child(bh)
	bh.add_child(Kit.make_icon("icon_skull", 36))
	var bv: = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bh.add_child(bv)
	bv.add_child(Kit.make_hud_label("The Minotaur", 20, Color(1.0, 0.74, 0.52)))
	_boss_bar = Kit.make_bar(Color(0.62, 0.1, 0.3), 18)
	_boss_bar.custom_minimum_size = Vector2(440, 18)
	bv.add_child(_boss_bar)


func _build_map_hint(root: Control) -> void :
	var hint: = Kit.make_dark_panel(0.6)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-186, -84)
	hint.custom_minimum_size = Vector2(162, 56)
	hint.mouse_filter = Control.MOUSE_FILTER_STOP
	hint.tooltip_text = "World map (M)"
	root.add_child(hint)
	var h: = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_child(h)
	h.add_child(Kit.make_icon("icon_map", 30))
	h.add_child(Kit.make_hud_label("M  Map", 17, HUD_GOLD))
	hint.gui_input.connect(_on_map_hint_input)

func _on_map_hint_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed\
	and event.button_index == MOUSE_BUTTON_LEFT and not ui_open:
		toggle_map()



func _build_death_overlay(root: Control) -> void :
	_death_overlay = CenterContainer.new()
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.visible = false
	root.add_child(_death_overlay)

	var p: = Kit.make_panel(false)
	p.custom_minimum_size = Vector2(780, 360)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.add_child(p)
	var margin: = Kit.make_margin(20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(margin)
	var v: = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v)

	v.add_child(Kit.make_label("You Have Fallen", 40, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	var body: = Kit.make_label(
		"The Fates carry you back to the sanctuary.\nA tithe of your gold is lost.", 
		19, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(480, 0)
	v.add_child(body)
	v.add_child(Kit.make_label("Rise again, champion.", 17, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

func _build_victory_overlay(root: Control) -> void :
	_victory_overlay = CenterContainer.new()
	_victory_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_overlay.visible = false
	root.add_child(_victory_overlay)
	_victory_overlay.add_child(Kit.make_dimmer())

	var p: = Kit.make_panel(false)
	p.custom_minimum_size = Vector2(860, 540)
	_victory_overlay.add_child(p)
	var margin: = Kit.make_margin(20)
	p.add_child(margin)
	var v: = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	var crown: = Kit.make_icon("icon_laurel", 76)
	crown.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(crown)
	v.add_child(Kit.make_label("Legend of Hellas!", 44, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))

	_victory_stats = Kit.make_label("", 20, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_victory_stats.name = "VictoryStats"
	_victory_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_victory_stats.custom_minimum_size = Vector2(520, 0)
	v.add_child(_victory_stats)

	var flavour: = Kit.make_label(
		"The curse is broken. The wilds are yours to wander — the forge still burns, and greater glory awaits.", 
		18, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavour.custom_minimum_size = Vector2(520, 0)
	v.add_child(flavour)
	v.add_child(Kit.spacer(6))

	var btn: = Kit.make_button("Continue", true)
	btn.pressed.connect(_close_victory)
	v.add_child(btn)

func _close_victory() -> void :
	_victory_overlay.visible = false
	_set_ui_open(false, true)

func show_victory() -> void :
	if _victory_shown:
		return
	_victory_shown = true
	if _victory_stats != null:
		_victory_stats.text = "Level %d %s of %s   •   Weapon +%d   •   %d gold" % [
			GameState.level, GameState.class_data()["name"], 
			GameState.empire_data()["name"], GameState.weapon_refine, GameState.gold]
	_victory_overlay.visible = true
	_set_ui_open(true)



func _connect_signals() -> void :
	_player.health_changed.connect(_on_health)
	_player.mana_changed.connect(_on_mana)
	_player.died.connect( func() -> void : _death_overlay.visible = true)
	_player.respawned.connect( func() -> void : _death_overlay.visible = false)
	_player.skill_cooldown_started.connect(func(d: float) -> void: _skill_cd_left = d)
	if _player.has_signal("skill2_cooldown_started"):
		_player.skill2_cooldown_started.connect(func(d: float) -> void: _skill2_cd_left = d)
	GameState.gold_changed.connect( func(_g: int) -> void : _refresh_all())
	GameState.xp_changed.connect( func(_x: int, _n: int, _l: int) -> void : _refresh_all())
	GameState.potions_changed.connect( func() -> void : _refresh_all())
	GameState.level_up.connect(_on_level_up)
	GameState.quest_advanced.connect( func(_id: String, _i: int) -> void : _refresh_all())

func _on_level_up(new_level: int) -> void :
	_announce.text = "Level %d — the gods favor you!" % new_level
	_announce.modulate.a = 1.0
	var tween: = create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(_announce, "modulate:a", 0.0, 0.8)



func show_announcement(text: String) -> void :
	if _announce == null:
		return
	_announce.text = text
	_announce.modulate.a = 1.0
	var tween: = create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(_announce, "modulate:a", 0.0, 0.8)

func _on_health(hp: float, max_hp: float) -> void :
	_hp_bar.max_value = max_hp
	_hp_bar.value = maxf(hp, 0.0)
	_hp_text.text = "%d / %d" % [int(maxf(hp, 0.0)), int(max_hp)]
	if _last_hp >= 0.0 and hp < _last_hp:
		_vignette.modulate.a = 0.4
		var tween: = create_tween()
		tween.tween_property(_vignette, "modulate:a", 0.0, 0.6)
	_last_hp = hp

func _on_mana(mp: float, max_mp: float) -> void :
	_mp_bar.max_value = max_mp
	_mp_bar.value = mp
	_mp_text.text = "%d / %d" % [int(mp), int(max_mp)]

func _refresh_all() -> void :
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

func _refresh_quest() -> void :
	var mosaic_line: = GameState.mosaic_progress_text()
	var q: Dictionary = GameState.current_quest()
	if q.is_empty():
		if mosaic_line != "":
			_quest_title.text = String(GameState.MOSAIC_QUEST["title"])
			_quest_lines.text = mosaic_line
			_quest_hint.text = "Speak with the agora women" if GameState.mosaic_quest_stage == "accepted" else ""
			return
		_quest_title.text = "All Trials Complete"
		_quest_lines.text = "Wander, refine, and grow stronger."
		_quest_hint.text = ""
		return
	_quest_title.text = q["title"]
	var body: = GameState.quest_progress_text()
	if mosaic_line != "" and GameState.mosaic_quest_stage != "complete":
		body += "\n\n" + mosaic_line
	_quest_lines.text = body
	if GameState.is_quest_objective_done():
		_quest_hint.text = "Return to Priestess Melite"
	elif GameState.mosaic_quest_stage == "accepted":
		_quest_hint.text = "Agora women — begin the mosaic"
	else:
		_quest_hint.text = ""



func _process(delta: float) -> void :
	if _player == null:
		return

	if _skill_cd_left > 0.0:
		_skill_cd_left -= delta
		_skill_cd_text.text = "%d" % ceili(_skill_cd_left)
		if _skill_cd_left <= 0.0:
			_skill_cd_text.text = "Q"
	if _skill2_cd_left > 0.0 and _skill2_cd_text != null:
		_skill2_cd_left -= delta
		_skill2_cd_text.text = "%d" % ceili(_skill2_cd_left)
		if _skill2_cd_left <= 0.0:
			_skill2_cd_text.text = "R"

	_tutorial_timer -= delta
	if _tutorial_timer <= 0.0:
		_tutorial_timer = 3.5
		_tick_tutorial()

	var target: Node3D = null
	if _world != null and not ui_open and _world.has_method("get_nearest_interactable"):
		target = _world.get_nearest_interactable(_player.global_position)
	if target != null and target.has_method("get_prompt"):
		_prompt.text = "[E]  %s" % target.get_prompt()
	else:
		_prompt.text = ""

	_track_timer -= delta
	if _track_timer <= 0.0:
		_track_timer = 0.5
		_refresh_quest()
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = 0.3
		_refresh_boss_bar()

	if is_instance_valid(_map_marker):
		_update_map_marker()

func _refresh_boss_bar() -> void :
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



func _unhandled_input(event: InputEvent) -> void :
	if not event is InputEventKey or not event.pressed or event.echo:
		return

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


func _on_chat_opened() -> void :

	_set_ui_open(true)


func _on_chat_closed() -> void :
	if _open_panel == null and not _victory_overlay.visible:
		_set_ui_open(false, true)

func open_dialogue(_npc: Node3D) -> void :
	_open(DialoguePanel.new())

func open_smith(_npc: Node3D) -> void :
	_open(SmithPanel.new())


func open_shop(npc: Node3D) -> void :
	var p: = ShopPanel.new()
	if npc != null:
		if "shop_id" in npc:
			p.shop_id = String(npc.shop_id)
		if "display_name" in npc:
			p.speaker_name = String(npc.display_name)
	_open(p)


func open_player_menu(target: Node) -> void:
	if target == null:
		return
	## Close any existing player menu first.
	for c in get_children():
		if c is PlayerMenu or (c.get_script() == PlayerMenu):
			c.queue_free()
	var menu: = PlayerMenu.new()
	menu.hud = self
	menu.target_peer = int(target.get_meta("peer_id", 0))
	menu.target_name = String(target.get("display_name")) if "display_name" in target else "Champion"
	menu.target_account = ""
	menu.action_chosen.connect(_on_player_menu_action)
	add_child(menu)
	_set_ui_open(true)
	GameCursor.apply()


func _on_player_menu_action(action: String, peer_id: int) -> void:
	_set_ui_open(false, true)
	var nm: = "Champion"
	var av = NetSession._avatars.get(peer_id) if NetSession else null
	if av != null and "display_name" in av:
		nm = String(av.display_name)
	match action:
		"friend":
			show_announcement(SocialSystem.send_friend_request(peer_id))
		"whisper":
			open_whisper(peer_id, nm)
			show_announcement("Whisper window opened.")
		"trade":
			show_announcement(SocialSystem.request_trade(peer_id))
		"party":
			show_announcement(PartyShare.invite_peer(peer_id))
		"duel":
			show_announcement(SocialSystem.request_duel(peer_id))


func open_whisper(peer_id: int, peer_name: String, initial_text: String = "") -> void:
	if _whisper != null and is_instance_valid(_whisper):
		if int(_whisper.get("peer_id")) == peer_id:
			if initial_text != "" and _whisper.has_method("_append"):
				_whisper.call("_append", peer_name, initial_text)
			return
		_whisper.queue_free()
	var w: = WhisperPanel.new()
	w.hud = self
	w.peer_id = peer_id
	w.peer_name = peer_name
	_whisper = w
	add_child(w)
	if initial_text != "":
		## Defer so _ready built the log.
		w.call_deferred("_append", peer_name, initial_text)
	_set_ui_open(true)
	GameCursor.apply()


func close_whisper() -> void:
	if _whisper != null and is_instance_valid(_whisper):
		_whisper.queue_free()
	_whisper = null
	_set_ui_open(false, true)


func open_trade(peer_id: int, peer_name: String) -> void:
	var p: = TradePanel.new()
	p.hud = self
	p.peer_id = peer_id
	p.peer_name = peer_name
	_open(p)


func open_mosaic(npc: Node3D) -> void :
	var p: = MosaicPanel.new()
	if npc != null and "display_name" in npc:
		p.speaker_name = String(npc.display_name)
	_open(p)

func toggle_inventory(tab: String = "gear") -> void :
	if _open_panel is InventoryPanel:
		_close_panel(false)
	else:
		var p: = InventoryPanel.new()
		p.initial_tab = tab
		_open(p)

func toggle_pause() -> void :
	if _open_panel is PausePanel:
		_close_panel(true)
	else:
		_open(PausePanel.new())



func toggle_map() -> void :
	if _open_panel != null and _open_panel.has_meta("is_map"):
		_close_panel(false)
	else:
		_clear_map_refs()
		_open(_build_map_panel())

func _open(panel: Control) -> void :
	if _chat != null and _chat.get("is_open") and _chat.has_method("close_chat"):
		_chat.call("close_chat", false)
	if _open_panel != null:
		_open_panel.queue_free()
	if not panel.has_meta("is_map"):
		_clear_map_refs()
	_open_panel = panel
	add_child(panel)

	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.set("hud", self)
	_set_ui_open(true)
	AudioManager.play_sfx("ui_click", -6.0)

func _close_panel(recapture: bool) -> void :
	if _open_panel != null:
		_open_panel.queue_free()
		_open_panel = null
	_clear_map_refs()
	_set_ui_open(false, recapture)

func _clear_map_refs() -> void :
	_map_field = null
	_map_marker = null
	_map_where = null

func _set_ui_open(open: bool, _recapture: bool = false) -> void :
	ui_open = open

	GameCursor.apply()






func _world_to_map(world_xz: Vector2) -> Vector2:
	var s: float = MAP_FIELD_PX / MAP_WORLD_SPAN
	return (world_xz + Vector2(MAP_WORLD_SPAN * 0.5, MAP_WORLD_SPAN * 0.5)) * s

func _build_map_panel() -> Control:
	var root: = Control.new()
	root.name = "MapPanel"
	root.set_meta("is_map", true)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(Kit.make_dimmer())

	var center: = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel: = Kit.make_panel(false)
	center.add_child(panel)
	var margin: = Kit.make_margin(20)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var head: = HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	head.add_child(Kit.make_icon("icon_map", 40))
	head.add_child(Kit.make_label("Map of Hellas", 32, Kit.INK_TITLE))

	var war: = Kit.make_label(
		"Open war — Athens, Sparta & Thebes are hostile. Rival empires are free PvP.",
		16, HUD_WAR, HORIZONTAL_ALIGNMENT_CENTER)
	war.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	war.custom_minimum_size = Vector2(MAP_FIELD_PX, 0)
	v.add_child(war)

	_map_where = Kit.make_label("", 18, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_map_where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_where.custom_minimum_size = Vector2(MAP_FIELD_PX, 0)
	v.add_child(_map_where)

	var field_center: = CenterContainer.new()
	v.add_child(field_center)
	_map_field = _build_map_field()
	field_center.add_child(_map_field)

	v.add_child(_build_map_legend())
	v.add_child(Kit.spacer(4))

	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(close_row)
	var close_btn: = Kit.make_button("Close", true)
	close_btn.pressed.connect(close_panel_from_click)
	close_row.add_child(close_btn)

	_update_map_marker()
	return root

func _map_regions() -> Array:
	return HellasMapData.map_regions()


func _build_map_field() -> Panel:
	var field: = Panel.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.81, 0.74, 0.56)
	sb.border_color = Color(0.4, 0.3, 0.13)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	field.add_theme_stylebox_override("panel", sb)
	field.custom_minimum_size = Vector2(MAP_FIELD_PX, MAP_FIELD_PX)
	field.size = Vector2(MAP_FIELD_PX, MAP_FIELD_PX)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_add_map_grid(field)
	_add_map_war_roads(field)

	## Dens first (under), capitals + arena on top.
	for entry in _map_regions():
		var r: Dictionary = entry
		if String(r.get("kind", "")) == "capital":
			continue
		_paint_map_region(field, r, 22)

	for entry in _map_regions():
		var r: Dictionary = entry
		if String(r.get("kind", "")) != "capital":
			continue
		_paint_map_region(field, r, 30)
		var pos: Vector2 = r["pos"]
		var label_at: = _world_to_map(pos) + Vector2(-48, 18)
		_add_map_label(field, String(r["name"]), label_at, Vector2(96, 22))

	## Den names — short labels near dens so capitals stay readable.
	for entry in _map_regions():
		var r: Dictionary = entry
		if String(r.get("kind", "")) != "den":
			continue
		var nm: = String(r["name"])
		## Prefer the lead word (Lykaon / Centaur / Satyr…) for clutter control.
		var short: = nm.split(" ")[0] if nm.find(" ") > 0 else nm
		var pos2: Vector2 = r["pos"]
		var at: = _world_to_map(pos2) + Vector2(-40, -28)
		_add_map_label(field, short, at, Vector2(80, 20))

	for entry in _map_regions():
		var r: Dictionary = entry
		if String(r.get("kind", "")) != "boss":
			continue
		var bpos: Vector2 = r["pos"]
		_add_map_label(field, String(r["name"]), _world_to_map(bpos) + Vector2(-70, 16), Vector2(140, 22))

	for stone_pos in MAP_STONES:
		var sp: Vector2 = stone_pos
		var gem: = Kit.make_icon("icon_gem", 18)
		gem.position = _world_to_map(sp) - Vector2(9, 9)
		gem.size = Vector2(18, 18)
		field.add_child(gem)

	var north: = Kit.make_label("N", 18, Color(0.35, 0.25, 0.1), HORIZONTAL_ALIGNMENT_CENTER)
	north.position = Vector2(MAP_FIELD_PX * 0.5 - 20, 6)
	north.size = Vector2(40, 24)
	field.add_child(north)

	_map_marker = _map_circle(20.0, Color(1.0, 0.86, 0.25, 1.0), Color(0.15, 0.1, 0.04))
	field.add_child(_map_marker)
	var pulse: = _map_marker.create_tween()
	pulse.set_loops()
	pulse.tween_property(_map_marker, "modulate:a", 0.35, 0.55)
	pulse.tween_property(_map_marker, "modulate:a", 1.0, 0.55)
	return field


func _paint_map_region(field: Panel, r: Dictionary, icon_px: int) -> void :
	var pos: Vector2 = r["pos"]
	var radius: float = float(r["r"])
	var col: Color = r["col"]
	var dia: float = radius * 2.0 * (MAP_FIELD_PX / MAP_WORLD_SPAN)
	var border: = Color(0.28, 0.2, 0.09, 0.85)
	if String(r.get("kind", "")) == "capital":
		border = Color(0.55, 0.12, 0.1, 0.95)
		## Hostile capital ring — thicker crimson rim.
		var rim: = _map_circle(dia + 8.0, Color(0.75, 0.18, 0.12, 0.35), Color(0.7, 0.15, 0.1, 0.8))
		rim.position = _world_to_map(pos) - Vector2(dia + 8.0, dia + 8.0) * 0.5
		field.add_child(rim)
	var disc: = _map_circle(dia, col, border)
	disc.position = _world_to_map(pos) - Vector2(dia, dia) * 0.5
	field.add_child(disc)
	var ic: = Kit.make_icon(String(r["icon"]), icon_px)
	ic.position = _world_to_map(pos) - Vector2(icon_px, icon_px) * 0.5
	ic.size = Vector2(icon_px, icon_px)
	field.add_child(ic)


func _add_map_war_roads(field: Panel) -> void :
	## Thin crimson roads between hostile capitals — open-war marches.
	var caps: Array = HellasMapData.CAPITALS
	var pairs: Array = [[0, 1], [0, 2], [1, 2]]
	for pair in pairs:
		var a: Vector2 = caps[int(pair[0])]["pos"]
		var b: Vector2 = caps[int(pair[1])]["pos"]
		var pa: = _world_to_map(a)
		var pb: = _world_to_map(b)
		var steps: = 28
		for i in steps:
			var t: float = float(i) / float(steps)
			var p: = pa.lerp(pb, t)
			var dash: = ColorRect.new()
			dash.color = Color(0.72, 0.22, 0.16, 0.45)
			dash.position = p - Vector2(1.5, 1.5)
			dash.size = Vector2(3, 3)
			dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			field.add_child(dash)

func _add_map_grid(field: Panel) -> void :
	var line_col: = Color(0.4, 0.3, 0.13, 0.2)
	for i in 3:
		var t: float = MAP_FIELD_PX * (0.25 * float(i + 1))
		var vline: = ColorRect.new()
		vline.color = line_col
		vline.position = Vector2(t, 0)
		vline.size = Vector2(1, MAP_FIELD_PX)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field.add_child(vline)
		var hline: = ColorRect.new()
		hline.color = line_col
		hline.position = Vector2(0, t)
		hline.size = Vector2(MAP_FIELD_PX, 1)
		hline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		field.add_child(hline)

func _map_circle(diameter: float, fill: Color, border: Color) -> Panel:
	var p: = Panel.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(diameter * 0.5))
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(diameter, diameter)
	p.size = Vector2(diameter, diameter)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _add_map_label(field: Panel, text: String, at: Vector2, box: Vector2) -> void :
	var l: = Kit.make_label(text, 14, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(box.x, 0)
	l.position = at
	l.size = box
	field.add_child(l)

func _build_map_legend() -> HBoxContainer:
	var legend: = HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 14)
	legend.add_child(_map_circle(16.0, Color(1.0, 0.86, 0.25), Color(0.15, 0.1, 0.04)))
	legend.add_child(Kit.make_label("You", 15, Kit.INK))
	legend.add_child(_map_circle(16.0, Color(0.25, 0.45, 0.78), Color(0.55, 0.12, 0.1)))
	legend.add_child(Kit.make_label("Capital (hostile)", 15, Kit.INK))
	legend.add_child(Kit.make_icon("icon_sword", 18))
	legend.add_child(Kit.make_label("Beast den", 15, Kit.INK))
	legend.add_child(Kit.make_icon("icon_gem", 18))
	legend.add_child(Kit.make_label("Oracle", 15, Kit.INK))
	legend.add_child(Kit.make_icon("icon_skull", 18))
	legend.add_child(Kit.make_label("Boss", 15, Kit.INK))
	legend.add_child(Kit.make_label("Esc / M", 15, Kit.INK_SOFT))
	return legend

func _update_map_marker() -> void :
	if not is_instance_valid(_map_marker) or _player == null:
		return
	var here: = Vector2(_player.global_position.x, _player.global_position.z)
	_map_marker.position = _world_to_map(here) - Vector2(10, 10)
	if is_instance_valid(_map_where):
		_map_where.text = "You stand at %s" % _nearest_region_name(here)
	_update_party_map_markers()


func _update_party_map_markers() -> void :
	if _map_field == null or not is_instance_valid(_map_field):
		return
	var seen: Dictionary = {}
	for row in PartyShare.member_list():
		var pid: = int(row.get("peer_id", 0))
		if pid == PartyShare.local_peer_id():
			continue
		seen[pid] = true
		var marker: Control = _party_markers.get(pid)
		if marker == null or not is_instance_valid(marker):
			marker = _map_circle(14.0, Color(0.35, 0.75, 1.0, 0.95), Color(0.05, 0.15, 0.25))
			_map_field.add_child(marker)
			_party_markers[pid] = marker
		var pos: = Vector2.ZERO
		var av = NetSession._avatars.get(pid) if NetSession else null
		if av != null and is_instance_valid(av) and av is Node3D:
			pos = Vector2((av as Node3D).global_position.x, (av as Node3D).global_position.z)
		marker.position = _world_to_map(pos) - Vector2(7, 7)
		marker.visible = true
	for pid in _party_markers.keys():
		if not seen.has(pid):
			var m: Control = _party_markers[pid]
			if m != null and is_instance_valid(m):
				m.queue_free()
			_party_markers.erase(pid)


func _tick_tutorial() -> void :
	if GameState.tutorial_step >= 99:
		return
	match GameState.tutorial_step:
		0:
			show_announcement("Welcome, champion — WASD to move, mouse to look. Press E near Melite.")
			GameState.advance_tutorial(1)
		1:
			show_announcement("LMB light attack · RMB heavy · Q skill (animated) · R second skill · F block · C dodge.")
		2:
			show_announcement("Open your bag with I. Buy from plaza merchants or craft mats at Brontes the Smith.")
		3:
			show_announcement("Open war: Athens, Sparta & Thebes are hostile — rival empires are free PvP. Same empire & party are safe. Press M for the map.")
		4:
			show_announcement("Host a world from Pause — friends join your save (peer sync, no conflicts). Party: L.")
		_:
			pass

func _nearest_region_name(here: Vector2) -> String:
	var best: = "the open wilds"
	var best_d: = 999999.0
	for entry in _map_regions():
		var r: Dictionary = entry
		var pos: Vector2 = r["pos"]
		var d: float = here.distance_to(pos)
		if d < best_d:
			best_d = d
			best = String(r["name"])
			if d <= float(r.get("r", 30.0)):
				return best
	if best_d > 70.0:
		return "the open wilds"
	return best


func close_panel_from_click() -> void :
	_close_panel(true)
