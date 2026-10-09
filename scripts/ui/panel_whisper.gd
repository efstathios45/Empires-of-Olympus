extends Control
## Small secret-chat window (Metin2-style whisper).


const Kit = preload("res://scripts/ui/ui_kit.gd")

var hud: CanvasLayer
var peer_id: int = 0
var peer_name: String = "Champion"

var _log: RichTextLabel
var _input: LineEdit


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -360
	offset_top = -280
	offset_right = -18
	offset_bottom = -18

	var panel: = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.05, 0.93)
	sb.border_color = Color(0.55, 0.42, 0.2, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var head: = HBoxContainer.new()
	v.add_child(head)
	var title: = Kit.make_hud_label("Whisper — %s" % peer_name, 14, Color(0.75, 0.9, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var x: = Button.new()
	x.text = "✕"
	x.flat = true
	x.focus_mode = Control.FOCUS_NONE
	x.custom_minimum_size = Vector2(28, 24)
	x.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	x.pressed.connect(func() -> void:
		if hud and hud.has_method("close_whisper"):
			hud.close_whisper()
		else:
			queue_free()
	)
	head.add_child(x)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size = Vector2(0, 140)
	_log.add_theme_font_override("normal_font", Kit.font())
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log.add_theme_color_override("default_color", Color(0.92, 0.9, 0.84))
	v.add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "Secret message…"
	_input.max_length = 120
	_input.custom_minimum_size = Vector2(0, 32)
	_input.add_theme_font_override("font", Kit.font())
	_input.text_submitted.connect(_on_send)
	v.add_child(_input)
	call_deferred("_focus")

	if SocialSystem and not SocialSystem.whisper_received.is_connected(_on_whisper):
		SocialSystem.whisper_received.connect(_on_whisper)


func _focus() -> void:
	_input.grab_focus()


func _on_whisper(from_name: String, text: String) -> void:
	if from_name != peer_name and from_name != String(GameState.player_name):
		## Still show if from this peer — name match is enough for MVP.
		pass
	_append(from_name, text)


func append_local(text: String) -> void:
	_append(String(GameState.player_name), text)


func _append(who: String, text: String) -> void:
	var col: = "#9fd4ff" if who != String(GameState.player_name) else "#ffe6a0"
	_log.append_text("[color=%s]%s[/color]: %s\n" % [col, who, text])


func _on_send(text: String) -> void:
	text = text.strip_edges()
	if text == "":
		return
	SocialSystem.send_whisper(peer_id, text)
	append_local(text)
	_input.text = ""
	_input.grab_focus()
