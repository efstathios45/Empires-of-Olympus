extends SceneTree
func _init() -> void :
	call_deferred("_run")
func _run() -> void :
	var scr = load("res://scripts/ui/panel_inventory.gd")
	if scr == null:
		push_error("load panel_inventory failed")
		quit(1)
		return
	var n = Control.new()
	n.set_script(scr)
	get_root().add_child(n)

	await process_frame
	await process_frame
	await process_frame
	if n.get("_equip_btns") == null or (n.get("_equip_btns") as Dictionary).is_empty():

		push_error("equip buttons missing")
		quit(1)
		return
	var cells: Array = n.get("_bag_cells")
	if cells.size() != 36:
		push_error("bag cells=%d" % cells.size())
		quit(1)
		return
	print("SMOKE_INV_LOAD_OK slots=", (n.get("_equip_btns") as Dictionary).size(), " cells=", cells.size())
	quit(0)
