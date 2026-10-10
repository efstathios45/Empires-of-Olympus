extends Control







const Kit = preload("res://scripts/ui/ui_kit.gd")
const EmpireMapView = preload("res://scripts/ui/empire_map_view.gd")

const BG: = "res://assets/textures/backgrounds/"
const POSTER: = "res://assets/ui/title_poster.webp"
const WORDMARK: = "res://assets/ui/wordmark_title.png"
const MAP: = BG + "empire_map_hellas.png"





const CARD_W: = 420
const EMPIRE_CARD_H: = 300
const CLASS_CARD_H: = 430
const FRAME_INSET: = 78
const CARD_PAD: = 14
const TEXT_W: = CARD_W - FRAME_INSET * 2 - CARD_PAD * 2

const DIM: = Color(0.86, 0.82, 0.72)


const EMPIRE_LORE: = {
	"sparta": "Born upon the shield, buried beneath it. In Laconia the phalanx moves as one beast of bronze, and it never breaks.", 
	"athens": "Under Athena's olive the academy lamps burn until dawn. A mind honed to an edge cuts deeper than any blade.", 
	"corinth": "Two seas, one isthmus — and a foothold in walled Thebes. Corinth buys what she cannot outrun.", 
}


const EMPIRE_REGION: = {
	"sparta": "Crimson highlands — south-west", 
	"athens": "Blue coasts and isles — east", 
	"corinth": "Golden isthmus — the centre", 
}

const CLASS_LORE: = {
	"hoplite": "Drilled until the shield became an arm and the arm became bronze. Where you plant your feet the line holds; where you thrust, the line advances.", 
	"toxotes": "You learned the Cretan bow on goat-paths and cliff winds, loosing at shadows until the shadows fell. Nothing reaches you; you reach everything.", 
	"magos": "The oracles at Dodona found the storm already living in your hands. You read the thunderhead, and you answer it in kind.", 
}

var _step: int = 1
var _empire: String = "sparta"
var _class: String = "hoplite"
var _empire_cards: Dictionary = {}
var _class_cards: Dictionary = {}
var _continue_btn: Button
var _backdrop: TextureRect
var _shade: ColorRect
var _content: Control
var _overlay: Control
var _bg_tween: Tween
var _map_view: Control
var _user_edit: LineEdit
var _pass_edit: LineEdit
var _name_edit: LineEdit
var _auth_status: Label
var _load_from_save: bool = false


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://assets/ui/theme.tres"):
		theme = load("res://assets/ui/theme.tres")
	AudioManager.play_music("menu")

	_backdrop = TextureRect.new()
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.015, 0.03, 0.35)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if not AccountSystem.sync_finished.is_connected(_on_sync_finished):
		AccountSystem.sync_finished.connect(_on_sync_finished)

	_show_step(1)


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		if _overlay != null:
			_close_overlay()
		elif _step > 1:
			_show_step(_step - 1)




func _set_backdrop(path: String, shade_alpha: float) -> void :
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_backdrop.texture = tex
	_shade.color = Color(0.02, 0.015, 0.03, shade_alpha)
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	_backdrop.modulate = Color(1, 1, 1, 0.3)
	_bg_tween = _backdrop.create_tween()
	_bg_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.35)



func _page(sep: int = 8) -> VBoxContainer:
	var m: = Kit.make_margin(20)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	return v


func _show_step(step: int) -> void :
	_step = step
	_continue_btn = null
	_empire_cards.clear()
	_class_cards.clear()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match step:
		2:
			_build_empire_step()
		3:
			_build_class_step()
		_:
			_build_title_step()




func _image(path: String, size: Vector2, cover: bool) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var t: = TextureRect.new()
	var tex: Texture2D = load(path)
	t.texture = tex
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.clip_contents = cover
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _centered(c: Control) -> CenterContainer:
	var cc: = CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


func _row(sep: int = 20) -> HBoxContainer:
	var h: = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h



func _wrapped(text: String, size: int, color: Color, width: int) -> Label:
	var l: = Kit.make_label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(maxi(width, 120), 0)

	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.clip_text = false
	return l



func _icon_line(icon: String, text: String, color: Color, width: int) -> HBoxContainer:
	var h: = _row(8)
	h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	h.custom_minimum_size = Vector2(maxi(width, 120), 0)
	var ico: = Kit.make_icon(icon, 22)
	if ico != null and ico.texture != null:
		h.add_child(ico)
	var l: = Kit.make_label(text, 12, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(maxi(width - 40, 100), 0)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	return h


func _card_body(card: PanelContainer) -> VBoxContainer:

	card.clip_contents = true
	var m: = Kit.make_margin(CARD_PAD)
	m.clip_contents = true
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(m)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	return v



func _equalize_heights(cards: Dictionary) -> void :
	var tallest: float = 0.0
	for key in cards:
		var c: Control = cards[key]
		tallest = maxf(tallest, c.get_combined_minimum_size().y)
	for key in cards:
		var c2: Control = cards[key]
		c2.custom_minimum_size.y = tallest


func _card_button(text: String) -> Button:

	return Kit.make_button(text, false)



func _colour_band(c: Color) -> ColorRect:
	var r: = ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(0, 5)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _title_line(text: String) -> Label:
	return Kit.make_hud_label(text, 34, Color(1.0, 0.93, 0.76), HORIZONTAL_ALIGNMENT_CENTER)


func _sub_line(text: String) -> Label:
	return Kit.make_hud_label(text, 15, DIM, HORIZONTAL_ALIGNMENT_CENTER)




func _build_title_step() -> void :
	_set_backdrop(POSTER, 0.35)
	_load_from_save = false
	var page: = _page(8)

	var top: = Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.size_flags_stretch_ratio = 0.35
	page.add_child(top)

	var mark: = _image(WORDMARK, Vector2(560, 170), false)
	if mark != null:
		page.add_child(_centered(mark))
	else:
		page.add_child(_title_line("Empires of Olympus"))

	page.add_child(Kit.make_hud_label(
		"Three empires. Three paths. One legend cut in bronze.", 
		20, Color(1.0, 0.94, 0.8), HORIZONTAL_ALIGNMENT_CENTER))

	var video_btn: = Kit.make_button("Settings", false)
	video_btn.pressed.connect(_open_settings)
	page.add_child(_centered(video_btn))

	if AccountSystem.is_logged_in():
		_build_logged_in_actions(page)
	else:
		_build_auth_form(page)

	page.add_child(Kit.spacer(8))
	page.add_child(_sub_line(
		"WASD move  ·  RMB look  ·  Click to strike  ·  Q god-skill"))
	page.add_child(_sub_line(
		"E speak  ·  Enter chat  ·  I spoils  ·  M map  ·  Esc rest"))

	var bottom: = Control.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(bottom)


func _styled_line_edit(placeholder: String, secret: bool = false) -> LineEdit:
	var e: = LineEdit.new()
	e.placeholder_text = placeholder
	e.secret = secret
	e.custom_minimum_size = Vector2(320, 44)
	e.add_theme_font_override("font", Kit.font())
	e.add_theme_font_size_override("font_size", 16)
	e.add_theme_color_override("font_color", Kit.INK)
	e.add_theme_color_override("font_placeholder_color", Kit.INK_SOFT)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.92, 0.82, 0.95)
	sb.border_color = Color(0.55, 0.42, 0.22, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	e.add_theme_stylebox_override("normal", sb)
	e.add_theme_stylebox_override("focus", sb)
	return e


func _build_auth_form(page: VBoxContainer) -> void :
	page.add_child(Kit.spacer(10))
	page.add_child(_sub_line("1) Browse Servers & Join  ·  2) Create account / Sign in  ·  3) Enter the world"))
	page.add_child(_sub_line("Create an account to save your legend on this PC."))

	var form: = VBoxContainer.new()
	form.add_theme_constant_override("separation", 8)
	form.alignment = BoxContainer.ALIGNMENT_CENTER
	form.custom_minimum_size = Vector2(340, 0)
	page.add_child(_centered(form))

	_name_edit = _styled_line_edit("Hero name (optional)")
	form.add_child(_name_edit)
	_user_edit = _styled_line_edit("Username")
	form.add_child(_user_edit)
	_pass_edit = _styled_line_edit("Password (6+ chars)", true)
	form.add_child(_pass_edit)

	_auth_status = Kit.make_hud_label("", 14, Color(1.0, 0.85, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_auth_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_auth_status.custom_minimum_size = Vector2(420, 0)
	form.add_child(_auth_status)


	var create_btn: = Kit.make_button("Register", true)
	create_btn.pressed.connect(_on_create_account)
	form.add_child(create_btn)
	var login_btn: = Kit.make_button("Sign In", false)
	login_btn.pressed.connect(_on_sign_in)
	form.add_child(login_btn)
	var guest: = Kit.make_button("Play Guest", false)
	guest.pressed.connect( func() -> void :
		if NetSession:
			NetSession.clear_pending_join()
		_load_from_save = false
		_show_step(2)
	)
	form.add_child(guest)

	var guest_browse: = Kit.make_button("Browse Servers → Join", true)
	guest_browse.pressed.connect(_open_server_browser)
	form.add_child(guest_browse)
	page.add_child(_sub_line("After Join Selected: register or sign in, pick empire/class, then Play to connect."))


func _build_logged_in_actions(page: VBoxContainer) -> void :
	page.add_child(Kit.spacer(12))
	page.add_child(Kit.make_hud_label(
		"Signed in as %s" % AccountSystem.display_name, 
		18, Color(0.85, 1.0, 0.75), HORIZONTAL_ALIGNMENT_CENTER))
	if AccountSystem.has_local_save():
		page.add_child(_sub_line("Continue alone, or browse named multiplayer worlds."))
	else:
		page.add_child(_sub_line("No save yet — start a new legend, or browse servers."))

	page.add_child(Kit.spacer(10))
	var actions: = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	page.add_child(_centered(actions))

	if AccountSystem.has_local_save():
		var cont: = Kit.make_button("Continue Alone", true)
		cont.pressed.connect(_on_continue_legend)
		actions.add_child(cont)

	var begin: = Kit.make_button("New Game", not AccountSystem.has_local_save())
	begin.pressed.connect( func() -> void :
		if NetSession:
			NetSession.clear_pending_join()
		_load_from_save = false
		_show_step(2)
	)
	actions.add_child(begin)


	var browse_btn: = Kit.make_button("Browse Servers → Join", true)
	browse_btn.pressed.connect(_open_server_browser)
	actions.add_child(browse_btn)
	actions.add_child(_sub_line("Pick a world → Join Selected → continue to empire/class → Play joins automatically."))

	var logout: = Kit.make_button("Sign Out", false)
	logout.pressed.connect( func() -> void :
		AccountSystem.logout()
		if NetSession:
			NetSession.clear_pending_join()
		_show_step(1)
	)
	actions.add_child(logout)

	_auth_status = Kit.make_hud_label("", 14, Color(1.0, 0.85, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_auth_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_auth_status.custom_minimum_size = Vector2(420, 0)
	actions.add_child(_auth_status)


func _set_auth_status(msg: String) -> void :
	if _auth_status != null and is_instance_valid(_auth_status):
		_auth_status.text = msg


func _on_create_account() -> void :
	var user: = _user_edit.text if _user_edit else ""
	var password: = _pass_edit.text if _pass_edit else ""
	var hero: = _name_edit.text if _name_edit else ""
	if AccountSystem.register(user, password, hero):
		GameState.player_name = AccountSystem.display_name
		_set_auth_status("Account created. Starting your legend…")
		_load_from_save = false
		_show_step(2)
	else:
		_set_auth_status(AccountSystem.last_error)


func _on_sign_in() -> void :
	var user: = _user_edit.text if _user_edit else ""
	var password: = _pass_edit.text if _pass_edit else ""
	_set_auth_status("Signing in…")
	if not AccountSystem.login(user, password):
		_set_auth_status(AccountSystem.last_error)
		return

	if AccountSystem.is_logged_in():
		GameState.player_name = AccountSystem.display_name
		_show_step(1)
	else:
		_set_auth_status("Contacting sync server…")


func _on_sync_finished(ok: bool, message: String) -> void :
	_set_auth_status(message)
	if ok and _step == 1:

		_show_step(1)


func _on_continue_legend() -> void :
	if NetSession:
		NetSession.clear_pending_join()
	if not AccountSystem.load_game():
		_set_auth_status(AccountSystem.last_error)
		return
	_load_from_save = true
	_empire = GameState.empire
	_class = GameState.player_class
	AudioManager.play_sfx("ui_confirm")
	GameCursor.apply()
	LoadingScreen.preload_and_change_scene("res://scenes/game_world.tscn", 1.2)


func _open_server_browser() -> void :
	var Browser: = load("res://scripts/ui/panel_server_browser.gd")
	if Browser == null:
		_set_auth_status("Server browser unavailable.")
		return
	var panel: Control = Browser.new()
	add_child(panel)


func _open_settings() -> void :
	var SettingsPanel: = load("res://scripts/ui/panel_settings.gd")
	if SettingsPanel == null:
		return
	var panel: Control = SettingsPanel.new()
	add_child(panel)




func _build_empire_step() -> void :
	_set_backdrop(BG + "empire_" + _empire + ".png", 0.45)
	var page: = _page(8)

	page.add_child(_title_line("Choose Your Empire"))
	page.add_child(_sub_line(
		"Three realms share one peninsula, and their borders are drawn in gold."))



	var map: = _image(MAP, Vector2(780, 300), false)
	if map != null:
		map.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		page.add_child(_centered(map))

	var cards: = _row(16)
	cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	page.add_child(cards)
	for key in GameState.EMPIRES:
		var id: String = key
		var data: Dictionary = GameState.EMPIRES[id]
		var card: = _make_empire_card(id, data)
		_empire_cards[id] = card
		cards.add_child(card)

	var nav: = _row(18)
	page.add_child(nav)

	var back: = Kit.make_button("Back", false)
	back.pressed.connect(_show_step.bind(1))
	nav.add_child(back)

	var study: = Kit.make_button("Map", false)
	study.pressed.connect(_show_map_overlay)
	nav.add_child(study)

	_continue_btn = Kit.make_button("Continue", true)
	_continue_btn.pressed.connect(_show_step.bind(3))
	nav.add_child(_continue_btn)

	_equalize_heights(_empire_cards)
	_refresh_empire_selection()


func _make_empire_card(id: String, data: Dictionary) -> PanelContainer:
	var card: = Kit.make_card_panel()
	card.custom_minimum_size = Vector2(CARD_W, EMPIRE_CARD_H)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v: = _card_body(card)

	var art: = _image(BG + "empire_" + id + ".png", Vector2(TEXT_W, 56), true)
	if art != null:
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(art)
		v.add_child(Kit.spacer(4))

	var colour: Color = data.get("color", Kit.INK_GOLD)
	var band: = _colour_band(colour)
	band.custom_minimum_size = Vector2(TEXT_W, 4)
	band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(band)

	var empire_name: String = data.get("name", id.capitalize())
	v.add_child(_wrapped(empire_name, 16, Kit.INK_TITLE, TEXT_W))
	v.add_child(_wrapped(String(EMPIRE_REGION.get(id, "")), 10, Kit.INK_SOFT, TEXT_W))
	v.add_child(_wrapped(String(EMPIRE_LORE.get(id, data.get("desc", ""))), 10, Kit.INK_SOFT, TEXT_W))
	v.add_child(_icon_line("icon_laurel", String(data.get("bonus_desc", "")), Kit.INK_GOLD, TEXT_W))

	var pledge: = _card_button("Pledge")
	pledge.pressed.connect(_on_pick_empire.bind(id))
	v.add_child(pledge)
	return card


func _on_pick_empire(id: String) -> void :
	_empire = id
	AudioManager.play_sfx("ui_confirm")
	_set_backdrop(BG + "empire_" + _empire + ".png", 0.45)
	_refresh_empire_selection()
	if _map_view != null and is_instance_valid(_map_view) and _map_view.has_method("set_selected"):
		if String(_map_view.get("selected")) != id:
			_map_view.call("set_selected", id)


func _refresh_empire_selection() -> void :
	for key in _empire_cards:
		var card: Control = _empire_cards[key]

		card.modulate = Color(1, 1, 1, 1) if key == _empire else Color(0.88, 0.86, 0.82, 0.85)

	if _continue_btn != null:
		_continue_btn.text = "Continue"




func _build_class_step() -> void :
	_set_backdrop(BG + "class_" + _class + ".png", 0.48)
	var page: = _page(8)

	page.add_child(_title_line("Choose Your Path"))
	var data: Dictionary = GameState.EMPIRES.get(_empire, {})
	page.add_child(_sub_line("Sworn to %s — now choose the hands that will serve her."
		%String(data.get("name", "Sparta"))))

	var cards: = _row(26)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(cards)
	for key in GameState.CLASSES:
		var id: String = key
		var cdata: Dictionary = GameState.CLASSES[id]
		var card: = _make_class_card(id, cdata)
		_class_cards[id] = card
		cards.add_child(card)

	var centaur_credit: String = String(preload("res://scripts/enemy.gd").ENEMY_CONFIGS["centaur_enemy"].get("credit", ""))
	if centaur_credit != "":
		page.add_child(_sub_line(centaur_credit))

	var nav: = _row(18)
	page.add_child(nav)

	var back: = Kit.make_button("Back", false)
	back.pressed.connect(_show_step.bind(2))
	nav.add_child(back)

	var play: = Kit.make_button("Enter", true)
	play.pressed.connect(_on_play)
	nav.add_child(play)

	_equalize_heights(_class_cards)
	_refresh_class_selection()


func _make_class_card(id: String, data: Dictionary) -> PanelContainer:
	var card: = Kit.make_card_panel()
	card.custom_minimum_size = Vector2(CARD_W, CLASS_CARD_H)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v: = _card_body(card)

	var art: = _image(BG + "class_" + id + ".png", Vector2(TEXT_W, 90), true)
	if art != null:
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(art)
		v.add_child(Kit.spacer(6))

	var class_name_text: String = data.get("name", id.capitalize())
	v.add_child(_wrapped(class_name_text, 16, Kit.INK_TITLE, TEXT_W))
	v.add_child(_wrapped(String(CLASS_LORE.get(id, data.get("desc", ""))), 10, Kit.INK_SOFT, TEXT_W))
	var credit: String = String(data.get("credit", ""))
	if credit != "":
		v.add_child(_wrapped(credit, 13, Kit.INK_SOFT, TEXT_W))
	v.add_child(_icon_line("icon_sword", String(data.get("weapon_name", "")), Kit.INK, TEXT_W))
	v.add_child(_icon_line("icon_mana", String(data.get("skill_name", "")), Kit.INK_GOLD, TEXT_W))

	var walk: = _card_button("Choose")
	walk.pressed.connect(_on_pick_class.bind(id))
	v.add_child(walk)
	return card


func _on_pick_class(id: String) -> void :
	_class = id
	AudioManager.play_sfx("ui_confirm")
	_set_backdrop(BG + "class_" + _class + ".png", 0.48)
	_refresh_class_selection()


func _refresh_class_selection() -> void :
	for key in _class_cards:
		var card: Control = _class_cards[key]
		card.modulate = Color(1, 1, 1, 1) if key == _class else Color(0.88, 0.86, 0.82, 0.85)




func _show_map_overlay() -> void :
	if _overlay != null:
		return
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim: = Kit.make_dimmer()
	dim.color = Color(0.02, 0.015, 0.03, 0.86)
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var m: = Kit.make_margin(28)
	_overlay.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	v.add_child(_title_line("The Realms of Hellas"))
	v.add_child(_sub_line(
		"Click a realm — its land border lights gold. The chronicle names kings and wars."))

	_map_view = EmpireMapView.new()
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.custom_minimum_size = Vector2(0, 420)
	v.add_child(_map_view)
	_map_view.empire_selected.connect(_on_pick_empire)
	_map_view.call_deferred("set_selected", _empire)

	var close: = Kit.make_button("Close", false)
	close.pressed.connect(_close_overlay)
	v.add_child(_centered(close))


func _close_overlay() -> void :
	if _overlay == null:
		return
	var o: = _overlay
	_overlay = null
	_map_view = null
	remove_child(o)
	o.queue_free()




func _on_play() -> void :
	if not _load_from_save:
		GameState.reset_run()
		GameState.empire = _empire
		GameState.player_class = _class
		if AccountSystem.is_logged_in() and AccountSystem.display_name != "":
			GameState.player_name = AccountSystem.display_name
	AudioManager.play_sfx("ui_confirm")
	GameCursor.apply()
	if AccountSystem.is_logged_in():
		AccountSystem.save_game()
	LoadingScreen.preload_and_change_scene("res://scenes/game_world.tscn", 1.5)
