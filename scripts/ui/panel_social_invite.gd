extends Control
## Metin2-style invite toast: Accept / Decline.


const Kit = preload("res://scripts/ui/ui_kit.gd")

signal answered(accepted: bool)

var kind: String = "friend" ## friend | party | trade | duel
var from_peer: int = 0
var from_name: String = "Champion"
var payload: Dictionary = {}

var _answered: = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_top = 18
	offset_bottom = 130
	offset_left = 0
	offset_right = 0

	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.05, 0.94)
	sb.border_color = Color(0.78, 0.62, 0.28, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)

	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	v.add_child(Kit.make_hud_label(_title(), 16, Color(1.0, 0.88, 0.45), HORIZONTAL_ALIGNMENT_CENTER))
	var msg: = Kit.make_hud_label(_message(), 14, Color(0.92, 0.9, 0.84), HORIZONTAL_ALIGNMENT_CENTER)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(380, 0)
	v.add_child(msg)

	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var yes: = _btn("Accept", true)
	yes.pressed.connect(func() -> void: _finish(true))
	row.add_child(yes)
	var no: = _btn("Decline", false)
	no.pressed.connect(func() -> void: _finish(false))
	row.add_child(no)


func _title() -> String:
	match kind:
		"friend":
			return "Friend Request"
		"party":
			return "Group Invite"
		"trade":
			return "Trade Request"
		"duel":
			return "Duel Challenge"
		_:
			return "Invitation"


func _message() -> String:
	match kind:
		"friend":
			return "%s wants to add you to their friend list. Accept?" % from_name
		"party":
			return "%s invited you to their group. Join?" % from_name
		"trade":
			return "%s wants to trade with you. Open trade window?" % from_name
		"duel":
			return "%s challenged you to a duel (loser drops item + 15%% gold). Fight?" % from_name
		_:
			return "%s sent you an invite." % from_name


func _btn(text: String, primary: bool) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 34)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Kit.font())
	b.add_theme_font_size_override("font_size", 14)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.28, 0.08, 0.95) if primary else Color(0.18, 0.16, 0.14, 0.95)
	sb.border_color = Color(0.85, 0.7, 0.3, 0.9) if primary else Color(0.45, 0.4, 0.32, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	return b


func _finish(ok: bool) -> void:
	if _answered:
		return
	_answered = true
	answered.emit(ok)
	queue_free()
