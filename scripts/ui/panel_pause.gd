extends Control
## Rest menu — controls, local save, and the road back to the title.

const Kit = preload("res://scripts/ui/ui_kit.gd")

## panel_scroll content_margin ~118×2 + inner margin 20×2 → keep text inside cream.
const TEXT_W := 400

var hud: CanvasLayer
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(720, 920)
	panel.clip_contents = true
	center.add_child(panel)

	var margin := Kit.make_margin(20)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	v.add_child(Kit.make_label("Rest a Moment", 34, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.make_label("Ways of the Champion", 19, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.spacer(4))

	for line in [
			"WASD — move   •   Middle-mouse drag — look   •   Wheel — zoom",
			"Left click — strike   •   RMB — heavy blow",
			"Q — god-skill   •   F — raise shield   •   C — dodge roll",
			"Shift — sprint   •   Space — leap   •   E — speak / touch",
			"Enter — chat   •   Esc — close chat / rest",
			"1 / 2 — health & spirit potions",
			"I — spoils   •   L — clan   •   M — map of Hellas",
			"Rival empires can fight; fallen champions drop gear"]:
		var l := Kit.make_label(String(line), 16, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(TEXT_W, 0)
		v.add_child(l)

	v.add_child(Kit.spacer(6))

	_status = Kit.make_label("", 14, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(TEXT_W, 0)
	v.add_child(_status)
	_refresh_status()

	if not AccountSystem.save_finished.is_connected(_on_save_finished):
		AccountSystem.save_finished.connect(_on_save_finished)
	if NetSession and not NetSession.session_changed.is_connected(_refresh_status):
		NetSession.session_changed.connect(_refresh_status)

	var host_btn := Kit.make_button("Host Arena", true)
	host_btn.pressed.connect(_on_host)
	v.add_child(host_btn)

	var join_btn := Kit.make_button("Join localhost", false)
	join_btn.pressed.connect(_on_join)
	v.add_child(join_btn)

	var leave_net := Kit.make_button("Leave Arena", false)
	leave_net.pressed.connect(_on_leave_net)
	v.add_child(leave_net)

	var settings_btn := Kit.make_button("Settings", false)
	settings_btn.pressed.connect(_on_settings)
	v.add_child(settings_btn)

	var save_btn := Kit.make_button("Save", true)
	save_btn.pressed.connect(_on_save)
	v.add_child(save_btn)

	var resume := Kit.make_button("Resume", true)
	resume.pressed.connect(func() -> void: hud.close_panel_from_click())
	v.add_child(resume)

	var menu := Kit.make_button("Quit", false)
	menu.pressed.connect(_on_menu)
	v.add_child(menu)


func _on_settings() -> void:
	var SettingsPanel := load("res://scripts/ui/panel_settings.gd")
	if SettingsPanel == null:
		return
	var panel: Control = SettingsPanel.new()
	add_child(panel)
	panel.closed.connect(func() -> void: pass)


func _on_save() -> void:
	if not AccountSystem.is_logged_in():
		_status.text = "Register on the title screen to save."
		return
	var extra := {}
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		extra["pos"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z,
		}
	if AccountSystem.save_game(extra):
		_status.text = "Saved."
	else:
		_status.text = AccountSystem.last_error


func _on_save_finished(ok: bool, message: String) -> void:
	_status.text = message if message != "" else ("Saved." if ok else "Save failed.")


func _refresh_status(_a: Variant = null) -> void:
	var bits: PackedStringArray = []
	if AccountSystem.is_logged_in():
		bits.append("Signed in as %s" % AccountSystem.display_name)
	else:
		bits.append("Guest — register on the title screen to save.")
	if NetSession:
		bits.append(NetSession.status_text())
	_status.text = "\n".join(bits)


func _on_host() -> void:
	if NetSession == null:
		return
	_status.text = NetSession.host()


func _on_join() -> void:
	if NetSession == null:
		return
	_status.text = NetSession.join("127.0.0.1")


func _on_leave_net() -> void:
	if NetSession == null:
		return
	NetSession.disconnect_session()
	_refresh_status()


func _on_menu() -> void:
	if AccountSystem.is_logged_in():
		_on_save()
	if NetSession:
		NetSession.disconnect_session()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	LoadingScreen.preload_and_change_scene("res://scenes/ui/main_menu.tscn", 1.0)
