extends Control
## Main menu — a three-step ceremony:
##   1. Title      — key art, wordmark, the road in.
##   2. Empire     — the painted map of Hellas + three realm cards with lore.
##   3. Path       — hero portraits, class lore, then into the world.
## The backdrop reacts to the current choice, so the screen always shows the
## realm or the hero the player is looking at.

const Kit = preload("res://scripts/ui/ui_kit.gd")

const BG := "res://assets/textures/backgrounds/"
const POSTER := "res://assets/ui/title_poster.webp"
const WORDMARK := "res://assets/ui/wordmark_title.png"
const MAP := BG + "empire_map_hellas.png"

## Card geometry. The panel art already insets content by 48px, so the inner
## margin only needs to add breathing room on top of that.
## Card heights are floors — a card grows to fit its lore, so the map below
## the title is the element that absorbs whatever height is left over.
const CARD_W := 480
const EMPIRE_CARD_H := 440
const CLASS_CARD_H := 560
const CARD_PAD := 14
const TEXT_W := CARD_W - 96 - CARD_PAD * 2

const DIM := Color(0.86, 0.82, 0.72)

## In-fiction lore, written for the pledge screen.
const EMPIRE_LORE := {
	"sparta": "Born upon the shield, buried beneath it. In Laconia the phalanx moves as one beast of bronze, and it never breaks.",
	"athens": "Under Athena's olive the academy lamps burn until dawn. A mind honed to an edge cuts deeper than any blade.",
	"corinth": "Two seas, one isthmus, and every keel in Hellas paying toll. Corinth buys what she cannot outrun.",
}

## Where each realm sits on the map, so the cards read against the borders.
const EMPIRE_REGION := {
	"sparta": "Crimson highlands — south-west",
	"athens": "Blue coasts and isles — east",
	"corinth": "Golden isthmus — the centre",
}

const CLASS_LORE := {
	"hoplite": "Shield and spear as one. Where you plant your feet the line holds.",
	"toxotes": "Cretan bow on cliff winds. Nothing reaches you; you reach everything.",
	"magos": "Storm already living in your hands. You answer the thunderhead in kind.",
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
var _empire_map: Control = null
var _empire_map_big: Control = null


func _ready() -> void:
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

	_show_step(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _overlay != null:
			_close_overlay()
		elif _step > 1:
			_show_step(_step - 1)


# ── Frame plumbing ───────────────────────────────────────────────────────

func _set_backdrop(path: String, shade_alpha: float) -> void:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_backdrop.texture = tex
	_shade.color = Color(0.02, 0.015, 0.03, shade_alpha)
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	_backdrop.modulate = Color(1, 1, 1, 0.3)
	_bg_tween = _backdrop.create_tween()
	_bg_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.35)


## A full-rect page: outer margin so nothing hugs the screen edge, then a VBox.
func _page(sep: int = 8) -> VBoxContainer:
	var m := Kit.make_margin(24)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	return v


func _show_step(step: int) -> void:
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


# ── Shared builders ──────────────────────────────────────────────────────

func _image(path: String, size: Vector2, cover: bool) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var t := TextureRect.new()
	var tex: Texture2D = load(path)
	t.texture = tex
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.clip_contents = cover
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Map texture + red frontier barriers + selected-empire glow.
func _empire_map_board(size: Vector2) -> Control:
	if not ResourceLoader.exists(MAP):
		return null
	var board := Control.new()
	board.custom_minimum_size = size
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.clip_contents = true

	var tex := TextureRect.new()
	tex.texture = load(MAP)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(tex)
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var overlay: Control = (load("res://scripts/ui/empire_map_overlay.gd") as GDScript).new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if overlay.has_method("set_selected"):
		overlay.call("set_selected", _empire)
	board.set_meta("overlay", overlay)
	return board


func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


func _row(sep: int = 20) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


## Body text on marble: dark ink, wrapped, with a width to wrap against.
func _wrapped(text: String, size: int, color: Color, width: int) -> Label:
	var l := Kit.make_label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	l.add_theme_constant_override("line_spacing", 1)
	l.clip_text = false
	return l


## Icon + one line of gold ink, e.g. a weapon or a realm bonus.
func _icon_line(icon: String, text: String, color: Color, width: int) -> HBoxContainer:
	var h := _row(8)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ico := Kit.make_icon(icon, 24)
	if ico != null and ico.texture != null:
		h.add_child(ico)
	var l := Kit.make_label(text, 14, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(maxi(40, width - 32), 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	h.add_child(l)
	return h


func _card_body(card: PanelContainer) -> VBoxContainer:
	var m := Kit.make_margin(CARD_PAD)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	return v


## Cards in a row share the tallest card's height, whatever the lore length.
func _equalize_heights(cards: Dictionary) -> void:
	var tallest: float = 0.0
	for key in cards:
		var c: Control = cards[key]
		tallest = maxf(tallest, c.get_combined_minimum_size().y)
	for key in cards:
		var c2: Control = cards[key]
		c2.custom_minimum_size.y = tallest


func _card_button(text: String) -> Button:
	var b := Kit.make_button(text, false)
	b.custom_minimum_size = Vector2(280, 62)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b


## A thin band of the realm's map colour, tying card to territory.
func _colour_band(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(TEXT_W, 5)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _title_line(text: String) -> Label:
	return Kit.make_hud_label(text, 46, Color(1.0, 0.93, 0.76), HORIZONTAL_ALIGNMENT_CENTER)


func _sub_line(text: String) -> Label:
	return Kit.make_hud_label(text, 18, DIM, HORIZONTAL_ALIGNMENT_CENTER)


# ── Step 1: title ────────────────────────────────────────────────────────

func _build_title_step() -> void:
	_set_backdrop(POSTER, 0.35)
	var page := _page(10)

	var top := Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.size_flags_stretch_ratio = 0.55
	page.add_child(top)

	var mark := _image(WORDMARK, Vector2(620, 200), false)
	if mark != null:
		page.add_child(_centered(mark))
	else:
		page.add_child(_title_line("Empires of Olympus"))

	page.add_child(Kit.make_hud_label(
		"Three empires. Three paths. One legend cut in bronze.",
		24, Color(1.0, 0.94, 0.8), HORIZONTAL_ALIGNMENT_CENTER))
	page.add_child(Kit.spacer(26))

	var begin := Kit.make_button("Begin Your Legend", true)
	begin.custom_minimum_size = Vector2(360, 74)
	begin.add_theme_font_size_override("font_size", 26)
	begin.pressed.connect(_show_step.bind(2))
	page.add_child(_centered(begin))

	page.add_child(Kit.spacer(18))
	page.add_child(_sub_line(
		"WASD move  ·  Mouse look  ·  Click to strike  ·  Q god-skill"))
	page.add_child(_sub_line(
		"E speak  ·  I spoils  ·  M map"))

	var bottom := Control.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(bottom)


# ── Step 2: the empires of Hellas ────────────────────────────────────────

func _build_empire_step() -> void:
	_set_backdrop(BG + "empire_" + _empire + ".png", 0.58)
	var page := _page(8)

	page.add_child(_title_line("Choose Your Empire"))
	page.add_child(_sub_line(
		"Three realms share one peninsula, and their borders are drawn in gold."))

	var map := _empire_map_board(Vector2(560, 240))
	if map != null:
		_empire_map = map
		map.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page.add_child(map)

	var cards := _row(26)
	cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	page.add_child(cards)
	for key in GameState.EMPIRES:
		var id: String = key
		var data: Dictionary = GameState.EMPIRES[id]
		var card := _make_empire_card(id, data)
		_empire_cards[id] = card
		cards.add_child(card)

	var nav := _row(18)
	page.add_child(nav)

	var back := Kit.make_button("Back", false)
	back.custom_minimum_size = Vector2(220, 62)
	back.pressed.connect(_show_step.bind(1))
	nav.add_child(back)

	var study := Kit.make_button("Study the Map", false)
	study.custom_minimum_size = Vector2(280, 62)
	study.pressed.connect(_show_map_overlay)
	nav.add_child(study)

	_continue_btn = Kit.make_button("Continue", true)
	_continue_btn.custom_minimum_size = Vector2(320, 66)
	_continue_btn.add_theme_font_size_override("font_size", 22)
	_continue_btn.pressed.connect(_show_step.bind(3))
	nav.add_child(_continue_btn)

	_equalize_heights(_empire_cards)
	_refresh_empire_selection()


func _make_empire_card(id: String, data: Dictionary) -> PanelContainer:
	var card := Kit.make_card_panel()
	card.custom_minimum_size = Vector2(CARD_W, EMPIRE_CARD_H)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := _card_body(card)

	var art := _image(BG + "empire_" + id + ".png", Vector2(TEXT_W, 110), true)
	if art != null:
		v.add_child(art)

	var colour: Color = data.get("color", Kit.INK_GOLD)
	v.add_child(_colour_band(colour))

	var empire_name: String = data.get("name", id.capitalize())
	v.add_child(Kit.make_label(empire_name, 30, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_wrapped(String(EMPIRE_REGION.get(id, "")), 13, Kit.INK_SOFT, TEXT_W))
	v.add_child(_wrapped(String(EMPIRE_LORE.get(id, data.get("desc", ""))), 14, Kit.INK_SOFT, TEXT_W))
	v.add_child(_icon_line("icon_laurel", String(data.get("bonus_desc", "")), Kit.INK_GOLD, TEXT_W - 40))

	var pledge := _card_button("Pledge")
	pledge.pressed.connect(_on_pick_empire.bind(id))
	v.add_child(pledge)
	return card


func _on_pick_empire(id: String) -> void:
	_empire = id
	AudioManager.play_sfx("ui_confirm")
	_set_backdrop(BG + "empire_" + _empire + ".png", 0.58)
	_refresh_empire_selection()


func _refresh_empire_selection() -> void:
	for key in _empire_cards:
		var card: Control = _empire_cards[key]
		var on: bool = key == _empire
		card.modulate = Color(1, 1, 1, 1) if on else Color(0.72, 0.7, 0.66, 0.62)
		# Stronger selected-card rim via modulate punch.
		if on:
			card.scale = Vector2(1.02, 1.02)
		else:
			card.scale = Vector2.ONE
	if _empire_map != null:
		var ov = _empire_map.get_meta("overlay", null)
		if ov != null and ov.has_method("set_selected"):
			ov.call("set_selected", _empire)
	if _empire_map_big != null:
		var ovb = _empire_map_big.get_meta("overlay", null)
		if ovb != null and ovb.has_method("set_selected"):
			ovb.call("set_selected", _empire)
	if _continue_btn != null:
		var data: Dictionary = GameState.EMPIRES.get(_empire, {})
		_continue_btn.text = "Continue as %s" % String(data.get("name", "Sparta"))


# ── Step 3: the path you walk ────────────────────────────────────────────

func _build_class_step() -> void:
	_set_backdrop(BG + "class_" + _class + ".png", 0.6)
	var page := _page(8)

	page.add_child(_title_line("Choose Your Path"))
	var data: Dictionary = GameState.EMPIRES.get(_empire, {})
	page.add_child(_sub_line("Sworn to %s — now choose the hands that will serve her."
		% String(data.get("name", "Sparta"))))

	var cards := _row(26)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(cards)
	for key in GameState.CLASSES:
		var id: String = key
		var cdata: Dictionary = GameState.CLASSES[id]
		var card := _make_class_card(id, cdata)
		_class_cards[id] = card
		cards.add_child(card)

	var nav := _row(18)
	page.add_child(nav)

	var back := Kit.make_button("Back", false)
	back.custom_minimum_size = Vector2(220, 62)
	back.pressed.connect(_show_step.bind(2))
	nav.add_child(back)

	var play := Kit.make_button("Enter Hellas", true)
	play.custom_minimum_size = Vector2(360, 74)
	play.add_theme_font_size_override("font_size", 26)
	play.pressed.connect(_on_play)
	nav.add_child(play)

	_equalize_heights(_class_cards)
	_refresh_class_selection()


func _make_class_card(id: String, data: Dictionary) -> PanelContainer:
	var card := Kit.make_card_panel()
	card.custom_minimum_size = Vector2(CARD_W, CLASS_CARD_H)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.clip_contents = true
	var v := _card_body(card)

	var art := _image(BG + "class_" + id + ".png", Vector2(TEXT_W, 150), true)
	if art != null:
		v.add_child(art)

	var class_name_text: String = data.get("name", id.capitalize())
	v.add_child(Kit.make_label(class_name_text, 26, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_wrapped(String(CLASS_LORE.get(id, data.get("desc", ""))), 13, Kit.INK_SOFT, TEXT_W))
	v.add_child(_icon_line("icon_sword", String(data.get("weapon_name", "")), Kit.INK, TEXT_W - 36))
	v.add_child(_icon_line("icon_mana", String(data.get("skill_name", "")), Kit.INK_GOLD, TEXT_W - 36))

	var walk := _card_button("Walk this Path")
	walk.pressed.connect(_on_pick_class.bind(id))
	v.add_child(walk)
	return card


func _on_pick_class(id: String) -> void:
	_class = id
	AudioManager.play_sfx("ui_confirm")
	_set_backdrop(BG + "class_" + _class + ".png", 0.6)
	_refresh_class_selection()


func _refresh_class_selection() -> void:
	for key in _class_cards:
		var card: Control = _class_cards[key]
		card.modulate = Color(1, 1, 1, 1) if key == _class else Color(0.72, 0.7, 0.66, 0.62)


# ── The map, full screen ─────────────────────────────────────────────────

func _show_map_overlay() -> void:
	if _overlay != null:
		return
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := Kit.make_dimmer()
	dim.color = Color(0.02, 0.015, 0.03, 0.82)
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var m := Kit.make_margin(34)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)

	v.add_child(_title_line("The Realms of Hellas"))
	var big := _empire_map_board(Vector2(900, 400))
	if big != null:
		_empire_map_big = big
		big.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(big)
	v.add_child(_sub_line(
		"Red barriers mark the frontiers  ·  Chosen realm glows in the loupe"))

	var close := Kit.make_button("Close", false)
	close.custom_minimum_size = Vector2(260, 62)
	close.pressed.connect(_close_overlay)
	v.add_child(_centered(close))


func _close_overlay() -> void:
	if _overlay == null:
		return
	var o := _overlay
	_overlay = null
	remove_child(o)
	o.queue_free()


# ── Into the world ───────────────────────────────────────────────────────

func _on_play() -> void:
	GameState.empire = _empire
	GameState.player_class = _class
	GameState.reset_run()
	AudioManager.play_sfx("ui_confirm")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	LoadingScreen.preload_and_change_scene("res://scenes/game_world.tscn", 1.5)
