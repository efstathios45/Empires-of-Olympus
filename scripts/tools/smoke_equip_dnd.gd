extends SceneTree
## Headless: bag → panoply slot equip (drag-drop API) + wrong-slot reject.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs := get_root().get_node_or_null("GameState")
	if gs == null:
		push_error("GameState missing")
		quit(1)
		return
	gs.call("reset_run")
	## Clear starter bag noise; seed known gear.
	gs.set("bag", [])
	gs.set("equipped", {
		"helmet": "", "armor": "", "weapon": "", "shield": "",
		"boots": "", "necklace": "", "earring": "", "bracelet": "",
	})
	if not bool(gs.call("try_add_to_bag", "leather_boots", 1)):
		push_error("could not add leather_boots")
		quit(1)
		return
	if not bool(gs.call("try_add_to_bag", "xiphos", 1)):
		push_error("could not add xiphos")
		quit(1)
		return
	var bag: Array = gs.get("bag")
	var boots_i := -1
	var sword_i := -1
	for i in range(bag.size()):
		var id := str(bag[i].get("id", ""))
		if id == "leather_boots":
			boots_i = i
		elif id == "xiphos":
			sword_i = i
	if boots_i < 0 or sword_i < 0:
		push_error("seed indices missing")
		quit(1)
		return
	## Wrong slot must fail.
	if bool(gs.call("equip_from_bag_to_slot", boots_i, "weapon")):
		push_error("boots must not equip to weapon")
		quit(1)
		return
	if not bool(gs.call("equip_from_bag_to_slot", boots_i, "boots")):
		push_error("boots → boots failed")
		quit(1)
		return
	var eq: Dictionary = gs.get("equipped")
	if str(eq.get("boots", "")) != "leather_boots":
		push_error("boots slot empty after equip")
		quit(1)
		return
	## Indices shifted after remove — find sword again.
	bag = gs.get("bag")
	sword_i = -1
	for i in range(bag.size()):
		if str(bag[i].get("id", "")) == "xiphos":
			sword_i = i
			break
	if sword_i < 0:
		push_error("xiphos vanished")
		quit(1)
		return
	if not bool(gs.call("equip_from_bag_to_slot", sword_i, "weapon")):
		push_error("xiphos → weapon failed")
		quit(1)
		return
	eq = gs.get("equipped")
	if str(eq.get("weapon", "")) != "xiphos":
		push_error("weapon slot wrong")
		quit(1)
		return
	## Unequip boots back to pouch.
	if not bool(gs.call("unequip_slot", "boots")):
		push_error("unequip boots failed")
		quit(1)
		return
	if str(gs.get("equipped").get("boots", "")) != "":
		push_error("boots still worn")
		quit(1)
		return
	print("SMOKE_EQUIP_DND_OK boots+weapon")
	quit(0)
