extends Control
## Rest menu — controls, local save, multiplayer browser, road back to title.

const Kit = preload("res://scripts/ui/ui_kit.gd")

## panel_scroll content_margin ~118×2 + inner margin 20×2 → keep text inside cream.
const TEXT_W := 400

var hud: CanvasLayer
var _status: Label
var _invite_label: Label
var _host_name_edit: LineEdit


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(720, 980)
	panel.clip_contents = true
	center.add_child(panel)

	var margin := Kit.make_margin(20)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	v.add_child(Kit.make_label("Rest a Moment", 34, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.make_label("Ways of the Champion", 19, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(Kit.spacer(4))

	for line in [
			"WASD — move   •   Middle-mouse drag — look",
			"Left click — strike   •   RMB — heavy blow",
			"Q — god-skill   •   F — raise shield   •   C — dodge roll",
			"Shift — sprint   •   Space — leap   •   E — speak / touch",
			"Enter — chat   •   Esc — close chat / rest",
			"1 / 2 — health & spirit potions",
			"I — spoils   •   L — clan   •   M — map of Hellas",
			"Multiplayer — browse named worlds (IPs hidden from players)"]:
		var l := Kit.make_label(String(line), 15, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(TEXT_W, 0)
		v.add_child(l)

	v.add_child(Kit.spacer(4))

	_status = Kit.make_label("", 14, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(TEXT_W, 0)
	v.add_child(_status)

	_invite_label = Kit.make_label("", 15, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER)
	_invite_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_invite_label.custom_minimum_size = Vector2(TEXT_W, 0)
	v.add_child(_invite_label)

	_refresh_status()

	if not AccountSystem.save_finished.is_connected(_on_save_finished):
		AccountSystem.save_finished.connect(_on_save_finished)
	if NetSession and not NetSession.session_changed.is_connected(_refresh_status):
		NetSession.session_changed.connect(_refresh_status)
	if NetSession and not NetSession.invite_ready.is_connected(_on_invite_ready):
		NetSession.invite_ready.connect(_on_invite_ready)

	_host_name_edit = LineEdit.new()
	_host_name_edit.placeholder_text = "World name for browser"
	_host_name_edit.text = "Hellas Arena"
	_host_name_edit.custom_minimum_size = Vector2(Kit.BTN_SIZE.x, 40)
	_host_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_host_name_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_centered_control(_host_name_edit))

	var host_btn := Kit.make_button("Host World", true)
	host_btn.pressed.connect(_on_host)
	v.add_child(host_btn)

	var browser_btn := Kit.make_button("Server Browser", true)
	browser_btn.pressed.connect(_on_open_browser)
	v.add_child(browser_btn)

	var copy_btn := Kit.make_button("Copy Invite (host)", false)
	copy_btn.pressed.connect(_on_copy_invite)
	v.add_child(copy_btn)

	var leave_net := Kit.make_button("Leave World", false)
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


func _centered_control(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


func _on_settings() -> void:
	var SettingsPanel := load("res://scripts/ui/panel_settings.gd")
	if SettingsPanel == null:
		return
	var panel: Control = SettingsPanel.new()
	add_child(panel)
	panel.closed.connect(func() -> void: pass)


func _on_open_browser() -> void:
	var Browser := load("res://scripts/ui/panel_server_browser.gd")
	if Browser == null:
		return
	var panel: Control = Browser.new()
	add_child(panel)
	if panel.has_signal("closed"):
		panel.closed.connect(func() -> void: _refresh_status())


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
		if NetSession.is_hosting():
			var inv := NetSession.invite_text()
			var sname := NetSession.server_name()
			if inv != "" and not inv.begins_with("0.0.0.0"):
				_invite_label.text = "Hosting '%s' · invite ready (Copy Invite — host only)" % sname
			else:
				_invite_label.text = "Hosting '%s' · fetching invite…" % sname
		elif NetSession.is_online():
			_invite_label.text = "Connected online — Enter to chat"
		else:
			_invite_label.text = "Solo — Host or open Server Browser"
	_status.text = "\n".join(bits)


func _on_invite_ready(_invite: String) -> void:
	_refresh_status()


func _on_host() -> void:
	if NetSession == null:
		return
	var nm := _host_name_edit.text if _host_name_edit else "Hellas Arena"
	_status.text = NetSession.host(NetSession.DEFAULT_PORT, nm)
	_refresh_status()


func _on_copy_invite() -> void:
	if NetSession == null:
		return
	if not NetSession.is_hosting():
		_status.text = "Only the host can copy the invite."
		return
	var inv := NetSession.invite_text()
	if inv == "" or inv.begins_with("0.0.0.0"):
		_status.text = "Host first — waiting for public IP…"
		return
	DisplayServer.clipboard_set(inv)
	_status.text = "Copied invite (host only). Friends Add Server by name in the browser."


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
