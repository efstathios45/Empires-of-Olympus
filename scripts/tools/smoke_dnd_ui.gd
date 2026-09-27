extends SceneTree
## Build panoply panel, simulate get/can/drop callables for boots → boots / wrong slot.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var gs := get_root().get_node("GameState")
	gs.call("reset_run")
	## Ensure leather_boots present
	var has_boots := false
	for e in gs.get("bag"):
		if str(e.get("id", "")) == "leather_boots":
			has_boots = true
			break
	if not has_boots:
		gs.call("try_add_to_bag", "leather_boots", 1)
	var scr = load("res://scripts/ui/panel_inventory.gd")
	var panel = Control.new()
	panel.set_script(scr)
	get_root().add_child(panel)
	await process_frame
	await process_frame
	await process_frame
	## Find bag cell with boots
	var cells: Array = panel.get("_bag_cells")
	var boots_cell := -1
	var boots_entry := -1
	for i in range(cells.size()):
		var ei := int(cells[i]["entry"])
		if ei < 0:
			continue
		var bag: Array = gs.get("bag")
		if ei < bag.size() and str(bag[ei].get("id", "")) == "leather_boots":
			boots_cell = i
			boots_entry = ei
			break
	if boots_cell < 0:
		push_error("no boots cell")
		quit(1)
		return
	var data: Variant = panel.call("_bag_get_drag", Vector2(10, 10), boots_cell)
	print("DRAG_DATA=", data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("drag data null")
		quit(1)
		return
	var can_weapon: bool = bool(panel.call("_slot_can_drop", Vector2(), data, "weapon"))
	var can_boots: bool = bool(panel.call("_slot_can_drop", Vector2(), data, "boots"))
	print("CAN_WEAPON=", can_weapon, " CAN_BOOTS=", can_boots)
	if can_weapon:
		push_error("weapon should reject boots")
		quit(1)
		return
	if not can_boots:
		push_error("boots should accept")
		quit(1)
		return
	panel.call("_slot_drop", Vector2(), data, "boots")
	var eq: Dictionary = gs.get("equipped")
	print("EQUIPPED_BOOTS=", eq.get("boots", ""))
	if str(eq.get("boots", "")) != "leather_boots":
		push_error("equip failed via panel drop")
		quit(1)
		return
	## Unequip via bag drop
	var udata: Variant = panel.call("_slot_get_drag", Vector2(), "boots")
	print("UNEQUIP_DRAG=", udata)
	panel.call("_bag_drop", Vector2(), udata, 0)
	eq = gs.get("equipped")
	if str(eq.get("boots", "")) != "":
		push_error("unequip failed")
		quit(1)
		return
	print("SMOKE_DND_UI_OK")
	quit(0)
