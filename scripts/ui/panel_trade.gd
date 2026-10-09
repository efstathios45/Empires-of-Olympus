extends Control
## Simple inventory trade — offer bag items, confirm to exchange.


const Kit = preload("res://scripts/ui/ui_kit.gd")

var hud: CanvasLayer
var peer_id: int = 0
var peer_name: String = "Champion"
var _offer: Array = []
var _status: Label
var _list: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())
	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: = Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(640, 520)
	center.add_child(panel)
	var margin: = Kit.make_margin(16)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)
	v.add_child(Kit.make_label("Trade with %s" % peer_name, 24, Kit.INK_TITLE))
	v.add_child(Kit.make_label("Click items to offer them. Confirm when ready.", 14, Kit.INK_SOFT))
	_list = VBoxContainer.new()
	v.add_child(_list)
	_rebuild()
	_status = Kit.make_label("", 14, Kit.INK_SOFT)
	v.add_child(_status)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var send: = Kit.make_button("Send offer", false)
	send.pressed.connect(func() -> void:
		SocialSystem.set_trade_offer(_offer)
		_status.text = "Offer sent (%d items)." % _offer.size()
	)
	row.add_child(send)
	var conf: = Kit.make_button("Confirm trade", true)
	conf.pressed.connect(func() -> void:
		SocialSystem.set_trade_offer(_offer)
		SocialSystem.confirm_trade()
		_status.text = "Confirmed — waiting for partner / completing…"
	)
	row.add_child(conf)
	var close: = Kit.make_button("Close", false)
	close.pressed.connect(func() -> void:
		SocialSystem.close_trade()
		if hud:
			hud.close_panel_from_click()
	)
	row.add_child(close)
	if SocialSystem and not SocialSystem.trade_updated.is_connected(_on_trade_upd):
		SocialSystem.trade_updated.connect(_on_trade_upd)
	if SocialSystem and not SocialSystem.trade_closed.is_connected(_on_closed):
		SocialSystem.trade_closed.connect(_on_closed)


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(Kit.make_label("Your bag (click to toggle offer)", 16, Kit.INK_GOLD))
	for e in GameState.bag:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var id: = String(e.get("id", ""))
		if id == "":
			continue
		var def: = GameState.item_def(id)
		var row: = HBoxContainer.new()
		_list.add_child(row)
		var offered: = _offer.has(id)
		var lab: = Kit.make_label("%s%s" % [String(def.get("name", id)), "  [OFFERED]" if offered else ""], 14, Kit.INK_GOLD if offered else Kit.INK)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
		var btn: = Kit.make_button("Toggle", false)
		btn.pressed.connect(_toggle.bind(id))
		row.add_child(btn)


func _toggle(item_id: String) -> void:
	if _offer.has(item_id):
		_offer.erase(item_id)
	else:
		_offer.append(item_id)
	_rebuild()


func _on_trade_upd(data: Dictionary) -> void:
	var theirs: Array = data.get("theirs", [])
	_status.text = "Their offer: %d item(s)%s" % [theirs.size(), " · they locked" if bool(data.get("they_locked", false)) else ""]


func _on_closed() -> void:
	if hud:
		hud.close_panel_from_click()
