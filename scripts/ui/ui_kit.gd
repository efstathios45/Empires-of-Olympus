extends Node



const FONT_PATH: = "res://assets/fonts/cinzel.ttf"
const ICON_DIR: = "res://assets/ui/"


const BTN_SIZE: = Vector2(220, 62)

const BTN_FONT: = 15

const BTN_PAD_X: = 32.0
const BTN_PAD_Y: = 14.0

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
	var p: = ICON_DIR + name + ".png"
	if ResourceLoader.exists(p):
		return load(p)
	return null


const INK: = Color(0.15, 0.11, 0.07)
const INK_SOFT: = Color(0.33, 0.25, 0.17)
const INK_TITLE: = Color(0.42, 0.13, 0.1)
const INK_GOLD: = Color(0.48, 0.33, 0.06)
const INK_GOOD: = Color(0.1, 0.36, 0.14)

static func make_label(text: String, size: int = 18, 
		color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:

	var l: = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func make_hud_label(text: String, size: int = 18, 
		color: Color = Color(1.0, 0.96, 0.86), align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:

	var l: = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l



static func button_text_width() -> float:
	return BTN_SIZE.x - BTN_PAD_X * 2.0



static func button_text_fits(text: String) -> bool:
	var f: = font()
	if f == null:
		return text.length() <= 14
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BTN_FONT).x <= button_text_width()


static func _button_style(primary: bool) -> StyleBox:
	var path: = "res://assets/ui/btn_blank.tres" if primary else "res://assets/ui/btn_blank_alt.tres"
	var base: StyleBox = style(path)
	if base == null:
		return null
	var sb: StyleBox = base.duplicate()

	sb.content_margin_left = BTN_PAD_X
	sb.content_margin_right = BTN_PAD_X
	sb.content_margin_top = BTN_PAD_Y
	sb.content_margin_bottom = BTN_PAD_Y
	return sb


static func make_button(text: String, primary: bool = true) -> Button:

	var b: = Button.new()
	b.text = text
	b.custom_minimum_size = BTN_SIZE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var sb: = _button_style(primary)
	if sb:
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
	var c: = INK_TITLE if primary else INK
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, c)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.45))
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", BTN_FONT)
	b.mouse_entered.connect( func() -> void : b.modulate = Color(1.14, 1.1, 1.0))
	b.mouse_exited.connect( func() -> void : b.modulate = Color.WHITE)

	b.pressed.connect( func() -> void :
		var tree: = Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		var am: = tree.root.get_node_or_null("AudioManager")
		if am != null and am.has_method("play_sfx"):
			am.call("play_sfx", "ui_click", -4.0)
	)
	if not button_text_fits(text):
		push_warning("UIKit: button label too long for plaque — shorten it: \"%s\"" % text)
	return b



static func standardize_button(b: Button) -> void :
	if b == null:
		return
	b.custom_minimum_size = BTN_SIZE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.clip_text = true
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", BTN_FONT)


static func make_bar(fill: Color, height: int = 20) -> ProgressBar:
	var bar: = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(BTN_SIZE.x, height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg: = StyleBoxFlat.new()
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
	var fg: = StyleBoxFlat.new()
	fg.bg_color = fill
	fg.corner_radius_top_left = 3
	fg.corner_radius_top_right = 3
	fg.corner_radius_bottom_left = 3
	fg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

static func make_panel(hud_style: bool = false) -> PanelContainer:

	var p: = PanelContainer.new()
	var sb: StyleBox = style("res://assets/ui/panel_tooltip.tres" if hud_style else "res://assets/ui/panel_scroll.tres")
	if sb:
		p.add_theme_stylebox_override("panel", sb)
	return p

static func make_card_panel() -> PanelContainer:

	var p: = PanelContainer.new()
	var sb: StyleBox = style("res://assets/ui/panel_card.tres")
	if sb:
		p.add_theme_stylebox_override("panel", sb)
	return p

static func make_margin(all: int = 40) -> MarginContainer:

	var m: = MarginContainer.new()
	m.add_theme_constant_override("margin_left", all)
	m.add_theme_constant_override("margin_right", all)
	m.add_theme_constant_override("margin_top", all)
	m.add_theme_constant_override("margin_bottom", all)
	return m

static func make_dark_panel(alpha: float = 0.62) -> PanelContainer:

	var p: = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
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
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	return p

static func make_icon(name: String, size: int = 36) -> TextureRect:
	var t: = TextureRect.new()
	t.texture = icon_texture(name)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func make_dimmer() -> ColorRect:

	var d: = ColorRect.new()
	d.color = Color(0, 0, 0, 0.45)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	return d

static func spacer(h: int = 8) -> Control:
	var c: = Control.new()
	c.custom_minimum_size = Vector2(1, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
