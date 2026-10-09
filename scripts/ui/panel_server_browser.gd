extends Control


const Kit = preload("res://scripts/ui/ui_kit.gd")
const TEXT_W: = 520

signal closed

var _status: Label
var _list: VBoxContainer
var _name_edit: LineEdit
var _addr_edit: LineEdit
var _host_name_edit: LineEdit
var _selected: Dictionary = {}


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center: = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vp: = get_viewport().get_visible_rect().size
	var panel_h: float = clampf(vp.y - 48.0, 520.0, 980.0)
	var panel: = Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(760, panel_h)
	panel.clip_contents = true
	center.add_child(panel)

	var margin: = Kit.make_margin(14)
	panel.add_child(margin)

	var outer: = ScrollContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(outer)

	var root: = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(root)

	root.add_child(Kit.make_label("Multiplayer Worlds", 32, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(Kit.make_label(
		"Browse LAN games by name · save friends' worlds · chat in-game with Enter", 
		14, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	_status = Kit.make_label("", 14, Kit.INK_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(TEXT_W, 0)
	root.add_child(_status)

	var scroll: = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(TEXT_W + 40, 120)
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(_centered(scroll))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var refresh: = Kit.make_button("Refresh List", false)
	refresh.pressed.connect(_refresh_list)
	root.add_child(_centered(refresh))

	var join_btn: = Kit.make_button("Join Selected", true)
	join_btn.pressed.connect(_on_join_selected)
	root.add_child(_centered(join_btn))


	root.add_child(Kit.spacer(2))
	root.add_child(Kit.make_label("Add friend server", 18, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(Kit.make_label(
		"Paste the invite they copied. List shows the name only.", 
		13, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Display name (e.g. Alex's World)"
	_name_edit.custom_minimum_size = Vector2(Kit.BTN_SIZE.x, 40)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_centered(_name_edit))
	_addr_edit = LineEdit.new()
	_addr_edit.placeholder_text = "Invite address (kept private in list)"
	_addr_edit.custom_minimum_size = Vector2(Kit.BTN_SIZE.x, 40)
	_addr_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_centered(_addr_edit))
	var add_btn: = Kit.make_button("Add Server", false)
	add_btn.pressed.connect(_on_add_saved)
	root.add_child(_centered(add_btn))
	var rem_btn: = Kit.make_button("Remove Saved", false)
	rem_btn.pressed.connect(_on_remove_saved)
	root.add_child(_centered(rem_btn))

	root.add_child(Kit.spacer(2))
	root.add_child(Kit.make_label("Host a world", 18, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	_host_name_edit = LineEdit.new()
	_host_name_edit.placeholder_text = "World name (shown in browser)"
	_host_name_edit.text = "Hellas Arena"
	_host_name_edit.custom_minimum_size = Vector2(Kit.BTN_SIZE.x, 40)
	_host_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_centered(_host_name_edit))
	var host_btn: = Kit.make_button("Host World", true)
	host_btn.pressed.connect(_on_host)
	root.add_child(_centered(host_btn))
	var copy_btn: = Kit.make_button("Copy Invite", false)
	copy_btn.pressed.connect(_on_copy_invite)
	root.add_child(_centered(copy_btn))

	var leave: = Kit.make_button("Leave World", false)
	leave.pressed.connect(_on_leave)
	root.add_child(_centered(leave))

	var back: = Kit.make_button("Back", false)
	back.pressed.connect(_on_back)
	root.add_child(_centered(back))

	if ServerBrowser and not ServerBrowser.list_changed.is_connected(_refresh_list):
		ServerBrowser.list_changed.connect(_refresh_list)
	if NetSession and not NetSession.session_changed.is_connected(_on_session):
		NetSession.session_changed.connect(_on_session)
	_refresh_list()
	_on_session()


func _centered(c: Control) -> CenterContainer:
	var cc: = CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


func _on_session(_a: Variant = null) -> void :
	if NetSession == null:
		return
	_status.text = NetSession.status_text()


func _refresh_list(_a: Variant = null) -> void :
	for c in _list.get_children():
		c.queue_free()
	if ServerBrowser == null:
		return
	var rows: Array = ServerBrowser.list_rows()
	if rows.is_empty():
		var empty: = Kit.make_label(
			"No LAN worlds right now. Host one, or Add a friend's server by name.", 
			14, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(TEXT_W, 0)
		_list.add_child(empty)
		return
	for row in rows:
		_list.add_child(_make_row(row))


func _make_row(row: Dictionary) -> Button:
	var nm: = String(row.get("name", "World"))
	var detail: = String(row.get("detail", ""))
	var btn: = Button.new()
	btn.text = "%s\n%s" % [nm, detail]
	btn.custom_minimum_size = Vector2(TEXT_W, 56)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_override("font", Kit.font())
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Kit.INK)
	var selected: bool = (
		String(_selected.get("name", "")) == nm
		and String(_selected.get("source", "")) == String(row.get("source", ""))
	)
	if selected:
		btn.add_theme_color_override("font_color", Kit.INK_TITLE)
	btn.pressed.connect( func() -> void :
		_selected = row
		_status.text = "Selected: %s" % nm
		_refresh_list()
	)
	return btn


func _on_join_selected() -> void :
	if NetSession == null:
		return
	if _selected.is_empty():
		_status.text = "Select a world in the list first."
		return
	var addr: = String(_selected.get("address", ""))
	var port: = int(_selected.get("port", 7777))
	var nm: = String(_selected.get("name", ""))
	if addr.is_empty():
		_status.text = "That server has no join address."
		return

	if get_tree().get_first_node_in_group("game_world") != null:
		_status.text = NetSession.join("%s:%d" % [addr, port], port, nm)
	else:
		_status.text = NetSession.set_pending_join("%s:%d" % [addr, port], nm)
		var acc: = get_node_or_null("/root/AccountSystem")
		var logged: = acc != null and acc.has_method("is_logged_in") and bool(acc.call("is_logged_in"))
		if logged:
			_status.text += " — choose empire/class then Play to connect."
			## Stay on menu so they finish character; Play will join via pending.
			queue_free()
		else:
			_status.text += " — next: Register or Sign In, then empire/class → Play."
			queue_free()


func _on_host() -> void :
	if NetSession == null:
		return
	if get_tree().get_first_node_in_group("game_world") == null:
		_status.text = "Enter the world first (Play), then Host from here or Esc menu."
		return
	var nm: = _host_name_edit.text if _host_name_edit else "Hellas Arena"
	_status.text = NetSession.host(NetSession.DEFAULT_PORT, nm)


func _on_copy_invite() -> void :
	if NetSession == null or not NetSession.is_hosting():
		_status.text = "Only the host can copy the invite address."
		return
	var inv: = NetSession.invite_text()
	if inv == "" or inv.begins_with("0.0.0.0"):
		_status.text = "Invite not ready yet — wait a moment for public IP…"
		return
	DisplayServer.clipboard_set(inv)
	_status.text = "Copied invite (host only). Send privately; friends Add Server by name."


func _on_add_saved() -> void :
	if ServerBrowser == null:
		return
	var msg: = ServerBrowser.add_saved_server(
		_name_edit.text if _name_edit else "", 
		_addr_edit.text if _addr_edit else "")
	_status.text = msg
	if _addr_edit:
		_addr_edit.text = ""
	_refresh_list()


func _on_remove_saved() -> void :
	if ServerBrowser == null or _selected.is_empty():
		return
	if String(_selected.get("source", "")) != "saved":
		_status.text = "Select a saved server to remove (LAN entries expire alone)."
		return
	ServerBrowser.remove_saved_server(String(_selected.get("name", "")))
	_selected = {}
	_status.text = "Removed saved server."
	_refresh_list()


func _on_leave() -> void :
	if NetSession:
		NetSession.disconnect_session()
	_status.text = "Back to solo."


func _on_back() -> void :
	closed.emit()
	queue_free()
