extends Control


const Kit = preload("res://scripts/ui/ui_kit.gd")

const LOG_W: = 520
const LOG_H: = 168
const VISIBLE_LINES: = 7

signal chat_opened
signal chat_closed

var is_open: bool = false

var _log: RichTextLabel
var _input: LineEdit
var _hint: Label
var _box: PanelContainer


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	var chat: = _chat()
	if chat != null:
		if not chat.message_received.is_connected(_on_message):
			chat.message_received.connect(_on_message)
		_replay_history()
	set_process_unhandled_input(true)


func _chat() -> Node:
	return get_node_or_null("/root/ChatSystem")


func _build() -> void :
	var anchor: = Control.new()
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	anchor.offset_left = 18
	anchor.offset_top = -260
	anchor.offset_right = 18 + LOG_W
	anchor.offset_bottom = -18
	add_child(anchor)

	var v: = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(v)

	_box = Kit.make_dark_panel(0.55)
	_box.custom_minimum_size = Vector2(LOG_W, LOG_H)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_box)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(margin)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.fit_content = false
	_log.scroll_active = true
	_log.selection_enabled = false
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_override("normal_font", Kit.font())
	_log.add_theme_font_size_override("normal_font_size", 15)
	_log.add_theme_color_override("default_color", Color(0.95, 0.92, 0.84))
	margin.add_child(_log)

	_hint = Kit.make_hud_label("Enter — chat", 13, Color(0.85, 0.8, 0.7))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_hint)

	_input = LineEdit.new()
	_input.visible = false
	_input.placeholder_text = "Say…"
	_input.max_length = 120
	_input.custom_minimum_size = Vector2(LOG_W, 40)
	_input.add_theme_font_override("font", Kit.font())
	_input.add_theme_font_size_override("font_size", 16)
	_input.add_theme_color_override("font_color", Kit.INK)
	_input.add_theme_color_override("font_placeholder_color", Kit.INK_SOFT)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.92, 0.82, 0.96)
	sb.border_color = Color(0.55, 0.42, 0.22, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	_input.add_theme_stylebox_override("normal", sb)
	_input.add_theme_stylebox_override("focus", sb)
	_input.text_submitted.connect(_on_submit)
	_input.gui_input.connect(_on_input_gui)
	v.add_child(_input)


func _replay_history() -> void :
	_log.clear()
	var chat: = _chat()
	if chat == null:
		return
	for entry in chat.history:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_append_line(String(entry.get("sender", "?")), String(entry.get("text", "")))


func _on_message(sender: String, text: String, _stamp: float, _peer_id: int = 0) -> void :
	_append_line(sender, text)


func _append_line(sender: String, text: String) -> void :
	var color: = "#f0d878" if sender == "Herald" else "#9fd4ff"
	if sender == (_chat().display_name() if _chat() else ""):
		color = "#ffe6a0"
	_log.append_text("[color=%s]%s[/color]: %s\n" % [color, sender, text])


func open_chat() -> void :
	if is_open:
		return
	is_open = true
	_hint.visible = false
	_input.visible = true
	_input.text = ""
	_input.grab_focus()
	chat_opened.emit()


func close_chat(recapture: bool = true) -> void :
	if not is_open:
		return
	is_open = false
	_input.text = ""
	_input.release_focus()
	_input.visible = false
	_hint.visible = true
	chat_closed.emit()

	if recapture:
		pass


func _on_submit(text: String) -> void :
	var chat: = _chat()
	if chat != null:
		var whisper_to: = 0
		if SocialSystem != null and SocialSystem.has_meta("whisper_target"):
			whisper_to = int(SocialSystem.get_meta("whisper_target"))
		if whisper_to > 0 and SocialSystem != null:
			SocialSystem.send_whisper(whisper_to, text)
			SocialSystem.remove_meta("whisper_target")
		else:
			chat.call("send_say", text)
	_input.text = ""
	_input.grab_focus()


func _on_input_gui(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close_chat()
		accept_event()
