extends SceneTree



func _init() -> void :
	call_deferred("_run")


func _run() -> void :
	var gs: = get_root().get_node("GameState")
	gs.call("reset_run")
	var has_boots: = false
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
	var bag: Array = gs.get("bag")
	var boots_i: = -1
	for i in range(bag.size()):
		if str(bag[i].get("id", "")) == "leather_boots":
			boots_i = i
			break
	if boots_i < 0:
		push_error("no boots")
		quit(1)
		return
	panel.call("_arm_bag_drag", boots_i, Vector2(100, 100))
	panel.set("_dragging", true)
	panel.set("_drag_armed", false)
	var boots_btn: Control = (panel.get("_equip_btns") as Dictionary).get("boots")
	if boots_btn == null:
		push_error("no boots button")
		quit(1)
		return
	var drop_pos: Vector2 = boots_btn.get_global_rect().get_center()
	panel.call("_finish_drag", drop_pos)
	var eq: Dictionary = gs.get("equipped")
	if str(eq.get("boots", "")) != "leather_boots":
		push_error("manual drag equip failed: %s" % str(eq.get("boots", "")))
		quit(1)
		return
	panel.call("_arm_slot_drag", "boots", "leather_boots", drop_pos)
	panel.set("_dragging", true)
	panel.set("_drag_armed", false)
	var cells: Array = panel.get("_bag_cells")
	var pouch_pos: Vector2 = (cells[0]["panel"] as Control).get_global_rect().get_center()
	panel.call("_finish_drag", pouch_pos)
	eq = gs.get("equipped")
	if str(eq.get("boots", "")) != "":
		push_error("manual unequip failed")
		quit(1)
		return
	print("SMOKE_DND_UI_OK manual")
	quit(0)
