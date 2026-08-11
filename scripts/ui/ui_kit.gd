extends Node
## UIKit — shared builders for the game's interface: real font, styled bars,
## buttons with hover feedback, icons. Everything reads from the UI kit art.

const FONT_PATH := "res://assets/fonts/cinzel.ttf"
const ICON_DIR := "res://assets/ui/"

static var _font: Font

static func font() -> Font:
	if _font == null and ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	return _font

static func style(path: String) -> StyleBox:
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func icon_texture(name: String) -> Texture2D:
	var p := ICON_DIR + name + ".png"
	if ResourceLoader.exists(p):
		return load(p)
	return null

## Panel interiors are cream marble, so body text must be DARK to be readable.
const INK := Color(0.15, 0.11, 0.07)
const INK_SOFT := Color(0.33, 0.25, 0.17)
const INK_TITLE := Color(0.42, 0.13, 0.10)
const INK_GOLD := Color(0.48, 0.33, 0.06)
const INK_GOOD := Color(0.10, 0.36, 0.14)

static func make_label(text: String, size: int = 18,
		color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	## Dark ink on marble: no outline (outlines smear small dark text).
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func make_hud_label(text: String, size: int = 18,
		color: Color = Color(1.0, 0.96, 0.86), align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	## Light text with a heavy outline — for labels drawn over the 3D world.
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l

static func make_button(text: String, primary: bool = true) -> Button:
	## Kit buttons are blank marble plaques — we draw the label ourselves.
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 60)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	var sb: StyleBox = style("res://assets/ui/btn_blank.tres" if primary else "res://assets/ui/btn_blank_alt.tres")
	if sb:
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
	var c := INK_TITLE if primary else INK
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, c)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.45))
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", 20)
	b.mouse_entered.connect(func() -> void: b.modulate = Color(1.14, 1.10, 1.0))
	b.mouse_exited.connect(func() -> void: b.modulate = Color.WHITE)
	b.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click", -4.0))
	return b

static func make_bar(fill: Color, height: int = 20) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(240, height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.06, 0.72)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bg.border_color = Color(0.72, 0.62, 0.4, 0.8)
	bg.border_width_bottom = 1
	bg.border_width_top = 1
	bg.border_width_left = 1
	bg.border_width_right = 1
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.corner_radius_top_left = 3
	fg.corner_radius_top_right = 3
	fg.corner_radius_bottom_left = 3
	fg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

static func make_panel(hud_style: bool = false) -> PanelContainer:
	## hud_style = the compact tooltip frame; otherwise the big marble scroll.
	var p := PanelContainer.new()
	var sb: StyleBox = style("res://assets/ui/panel_tooltip.tres" if hud_style else "res://assets/ui/panel_scroll.tres")
	if sb:
		p.add_theme_stylebox_override("panel", sb)
	return p

static func make_card_panel() -> PanelContainer:
	## Tall portrait frame for selection cards.
	var p := PanelContainer.new()
	var sb: StyleBox = style("res://assets/ui/panel_card.tres")
	if sb:
		p.add_theme_stylebox_override("panel", sb)
	return p

static func make_margin(all: int = 30) -> MarginContainer:
	## Keeps content inside the ornate frame instead of under the gold border.
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", all)
	m.add_theme_constant_override("margin_right", all)
	m.add_theme_constant_override("margin_top", all)
	m.add_theme_constant_override("margin_bottom", all)
	return m

static func make_dark_panel(alpha: float = 0.62) -> PanelContainer:
	## Readable dark slate for HUD widgets sitting over the bright 3D world.
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.045, 0.07, alpha)
	sb.border_color = Color(0.78, 0.65, 0.36, 0.85)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p

static func make_icon(name: String, size: int = 36) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon_texture(name)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func make_dimmer() -> ColorRect:
	## Catches clicks behind an open panel so the game camera doesn't grab them.
	var d := ColorRect.new()
	d.color = Color(0, 0, 0, 0.45)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	return d

static func spacer(h: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(1, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
