extends Control
## Right-click context menu on another player.


const Kit = preload("res://scripts/ui/ui_kit.gd")

var hud: CanvasLayer
var target_peer: int = 0
var target_name: String = "Champion"
var target_account: String = ""

signal action_chosen(action: String, peer_id: int)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_bg)
	tree_exiting.connect(_on_exiting)
	var panel: = Kit.make_panel(true)
	panel.custom_minimum_size = Vector2(280, 0)
	var mp: = get_viewport().get_mouse_position()
	panel.position = mp + Vector2(8, 8)
	add_child(panel)
	var margin: = Kit.make_margin(10)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	margin.add_child(v)
	v.add_child(Kit.make_label(target_name, 18, Kit.INK_GOLD))
	_add_btn(v, "Friend request", "friend")
	_add_btn(v, "Personal message", "whisper")
	_add_btn(v, "Trade inventory", "trade")
	_add_btn(v, "Invite to group", "party")
	_add_btn(v, "Challenge to duel", "duel")
	var close: = Kit.make_button("Cancel", false)
	close.pressed.connect(_cancel)
	v.add_child(close)


var _acted: = false


func _on_exiting() -> void:
	if not _acted and hud != null and hud.has_method("_set_ui_open"):
		hud.call("_set_ui_open", false, true)


func _cancel() -> void:
	queue_free()


func _on_bg(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		queue_free()


func _add_btn(v: VBoxContainer, label: String, action: String) -> void:
	var b: = Kit.make_button(label, false)
	b.pressed.connect(func() -> void:
		_acted = true
		action_chosen.emit(action, target_peer)
		queue_free()
	)
	v.add_child(b)
