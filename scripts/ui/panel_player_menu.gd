extends Control
## Metin2-style right-click player menu (compact, at cursor).


const Kit = preload("res://scripts/ui/ui_kit.gd")

var hud: CanvasLayer
var target_peer: int = 0
var target_name: String = "Champion"
var target_account: String = ""

signal action_chosen(action: String, peer_id: int)

var _acted: = false
var _panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_bg)
	tree_exiting.connect(_on_exiting)
	_build_menu()


func _build_menu() -> void:
	_panel = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.06, 0.94)
	sb.border_color = Color(0.72, 0.58, 0.28, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.custom_minimum_size = Vector2(200, 0)
	add_child(_panel)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_panel.add_child(v)

	var title: = Kit.make_hud_label(target_name, 15, Color(1.0, 0.86, 0.42))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var rule: = ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Color(0.55, 0.42, 0.18, 0.85)
	v.add_child(rule)

	_add_row(v, "Add Friend", "friend")
	_add_row(v, "Whisper", "whisper")
	_add_row(v, "Trade", "trade")
	_add_row(v, "Invite to Group", "party")
	_add_row(v, "Duel", "duel")
	_add_row(v, "Cancel", "cancel", true)

	## Place near cursor; keep on-screen.
	await get_tree().process_frame
	var mp: = get_viewport().get_mouse_position()
	var sz: = _panel.get_combined_minimum_size()
	var vp: = get_viewport().get_visible_rect().size
	_panel.position = Vector2(
		clampf(mp.x + 6.0, 8.0, maxf(8.0, vp.x - sz.x - 8.0)),
		clampf(mp.y + 6.0, 8.0, maxf(8.0, vp.y - sz.y - 8.0))
	)


func _add_row(v: VBoxContainer, label: String, action: String, muted: bool = false) -> void:
	var b: = Button.new()
	b.text = label
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(184, 28)
	b.add_theme_font_override("font", Kit.font())
	b.add_theme_font_size_override("font_size", 14)
	var col: = Color(0.72, 0.7, 0.66) if muted else Color(0.95, 0.92, 0.84)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.45))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.3))
	var hover: = StyleBoxFlat.new()
	hover.bg_color = Color(0.22, 0.18, 0.1, 0.95)
	hover.set_corner_radius_all(1)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var empty: = StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.pressed.connect(func() -> void:
		if action == "cancel":
			_cancel()
			return
		_acted = true
		action_chosen.emit(action, target_peer)
		queue_free()
	)
	v.add_child(b)


func _on_exiting() -> void:
	if not _acted and hud != null and hud.has_method("_set_ui_open"):
		hud.call("_set_ui_open", false, true)


func _cancel() -> void:
	queue_free()


func _on_bg(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_LEFT or ev.button_index == MOUSE_BUTTON_RIGHT:
			## Click outside the panel closes.
			if _panel != null and not _panel.get_global_rect().has_point(ev.position):
				queue_free()
