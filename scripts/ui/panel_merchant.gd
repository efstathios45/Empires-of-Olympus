extends Control
## Merchant panel — Kyros buys your bag spoils for flat vendor gold.
## Sell prices follow classic ARPG vendor-trash bands (~15–200 gold).

const Kit = preload("res://scripts/ui/ui_kit.gd")

var hud: CanvasLayer
var _list: VBoxContainer
var _gold_label: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Kit.make_dimmer())

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := Kit.make_panel(false)
	panel.custom_minimum_size = Vector2(780, 600)
	center.add_child(panel)

	var margin := Kit.make_margin(28)
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	v.add_child(Kit.make_label("Kyros the Broker", 22, Kit.INK_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	var tag := Kit.make_label(
		"I buy bronze and bone alike — cheap, honest, and without questions.",
		13, Kit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size = Vector2(720, 0)
	v.add_child(tag)

	_gold_label = Kit.make_label("Your gold: %d" % GameState.gold, 15, Kit.INK_GOLD,
		HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_gold_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_hint = Kit.make_label("", 14, Kit.INK_SOFT)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(740, 0)
	v.add_child(_hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var sell_all := Kit.make_button("Sell All Spoils", false)
	sell_all.custom_minimum_size = Vector2(280, 56)
	sell_all.pressed.connect(_on_sell_all)
	row.add_child(sell_all)
	var close_btn := Kit.make_button("Leave", true)
	close_btn.custom_minimum_size = Vector2(220, 56)
	close_btn.pressed.connect(func() -> void: hud.close_panel_from_click())
	row.add_child(close_btn)

	GameState.inventory_changed.connect(_rebuild)
	GameState.gold_changed.connect(_on_gold)
	_rebuild()


func _exit_tree() -> void:
	if GameState.inventory_changed.is_connected(_rebuild):
		GameState.inventory_changed.disconnect(_rebuild)
	if GameState.gold_changed.is_connected(_on_gold):
		GameState.gold_changed.disconnect(_on_gold)


func _on_gold(_g: int) -> void:
	_refresh_gold()


func _refresh_gold() -> void:
	_gold_label.text = "Your gold: %d" % GameState.gold


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_refresh_gold()
	if GameState.bag.is_empty():
		var empty := Kit.make_label("Your bag is empty. Hunt the wilds, then return.", 14, Kit.INK_SOFT)
		_list.add_child(empty)
		_hint.text = ""
		return
	for i in GameState.bag.size():
		var e: Dictionary = GameState.bag[i]
		var id: String = String(e.get("id", ""))
		var def: Dictionary = GameState.item_def(id)
		var count: int = int(e.get("count", 1))
		var sell: int = GameState.item_sell_price(id)
		var cells: Vector2i = GameState.item_cells(id)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		_list.add_child(line)
		var name_l := Kit.make_label("%s%s  (%dx%d)" % [
			String(def.get("name", id)),
			(" ×%d" % count) if count > 1 else "",
			cells.x, cells.y], 13)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.custom_minimum_size = Vector2(360, 0)
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(name_l)
		var price_l := Kit.make_label("%d g" % sell, 16, Kit.INK_GOLD)
		price_l.custom_minimum_size = Vector2(70, 0)
		line.add_child(price_l)
		var btn := Kit.make_button("Sell 1", false)
		btn.custom_minimum_size = Vector2(110, 44)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_sell.bind(i, 1))
		line.add_child(btn)
		if count > 1:
			var btn_all := Kit.make_button("Sell stack", false)
			btn_all.custom_minimum_size = Vector2(130, 44)
			btn_all.add_theme_font_size_override("font_size", 15)
			btn_all.pressed.connect(_on_sell.bind(i, count))
			line.add_child(btn_all)
	_hint.text = "Prices are vendor trash rates — roughly a third of shop cost, 15–200 gold for loot."


func _on_sell(index: int, amount: int) -> void:
	# Indices shift after removal; re-find by snapshot id if needed.
	if index < 0 or index >= GameState.bag.size():
		_rebuild()
		return
	var id: String = String(GameState.bag[index].get("id", ""))
	var gained: int = GameState.sell_bag_entry(index, amount)
	if gained > 0:
		AudioManager.play_sfx("gold_pickup", -2.0)
		_hint.text = "Kyros weighs the %s… %d gold." % [GameState.item_name(id), gained]
	_rebuild()


func _on_sell_all() -> void:
	var total := 0
	# Sell from the end so indices stay valid.
	for i in range(GameState.bag.size() - 1, -1, -1):
		var e: Dictionary = GameState.bag[i]
		total += GameState.sell_bag_entry(i, int(e.get("count", 1)))
	if total > 0:
		AudioManager.play_sfx("gold_pickup", -1.0)
		_hint.text = "Kyros clears your bag for %d gold." % total
	_rebuild()
