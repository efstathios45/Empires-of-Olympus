extends Control
## Simple plaza merchant shop.


const Kit = preload("res://scripts/ui/ui_kit.gd")

var hud: CanvasLayer
var shop_id: String = "oil"
var speaker_name: String = "Merchant"

var _result: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())
	var center: = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: = Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(720, 520)
	center.add_child(panel)
	var margin: = Kit.make_margin(18)
	panel.add_child(margin)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)
	var shop: Dictionary = GameState.MERCHANT_SHOPS.get(shop_id, {})
	v.add_child(Kit.make_label(String(shop.get("title", speaker_name)), 26, Kit.INK_TITLE))
	var quote: = Kit.make_label("\"%s\"" % String(shop.get("quote", "")), 15, Kit.INK_SOFT)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(quote)
	v.add_child(Kit.make_label("Your gold: %d δρ" % GameState.gold, 16, Kit.INK_GOLD))
	for item_id in shop.get("items", []):
		var id: = String(item_id)
		var def: Dictionary = GameState.SHOP_ITEMS.get(id, GameState.item_def(id))
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		v.add_child(row)
		row.add_child(Kit.make_label(String(def.get("name", id)), 16, Kit.INK))
		var price: = int(def.get("price", 0))
		row.add_child(Kit.make_label("%d δρ" % price, 15, Kit.INK_GOLD))
		var buy: = Kit.make_button("Buy", false)
		buy.pressed.connect(_buy.bind(id))
		row.add_child(buy)
	_result = Kit.make_label("", 14, Kit.INK_SOFT)
	v.add_child(_result)
	var close_btn: = Kit.make_button("Leave", true)
	close_btn.pressed.connect(func() -> void:
		if hud:
			hud.close_panel_from_click()
	)
	v.add_child(close_btn)


func _buy(item_id: String) -> void:
	if GameState.buy_merchant_item(shop_id, item_id):
		_result.text = "Purchased."
		if GameState.tutorial_step < 5:
			GameState.advance_tutorial(5)
		if NetSession.is_hosting():
			NetSession.broadcast_world_save()
	else:
		_result.text = "Cannot buy — gold or bag space."
