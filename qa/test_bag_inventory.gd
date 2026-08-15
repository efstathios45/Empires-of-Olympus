extends SceneTree
## Headless checks for bag packing + loot scale helper.
## Run: godot --headless --path . --script res://qa/test_bag_inventory.gd

var GS


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	GS = load("res://scripts/autoloads/game_state.gd").new()
	root.add_child(GS)
	await process_frame
	var failed := 0
	failed += _test_bag_footprints()
	failed += _test_bag_capacity()
	failed += _test_sell_prices()
	failed += _test_scale_helper()
	if failed == 0:
		print("BAG_TEST_OK")
		quit(0)
	else:
		print("BAG_TEST_FAIL count=", failed)
		quit(1)


func _test_bag_footprints() -> int:
	var fails := 0
	var sword: Vector2i = GS.item_cells("xiphos")
	var potion: Vector2i = GS.item_cells("health_potion")
	var helm: Vector2i = GS.item_cells("corinthian_helm")
	if sword != Vector2i(1, 2):
		print("FAIL sword cells ", sword)
		fails += 1
	if potion != Vector2i(1, 1) or helm != Vector2i(1, 1):
		print("FAIL 1x1 cells", potion, helm)
		fails += 1
	return fails


func _test_bag_capacity() -> int:
	var fails := 0
	GS.bag.clear()
	GS._resync_derived_counts()
	# Fill with non-stackable 1×1 shields (multiple copies allowed).
	var added := 0
	while GS.try_add_to_bag("aspis"):
		added += 1
		if added > 50:
			break
	if added != GS.BAG_W * GS.BAG_H:
		print("FAIL expected full 1x1 fill ", GS.BAG_W * GS.BAG_H, " got ", added)
		fails += 1
	if GS.try_add_to_bag("corinthian_helm"):
		print("FAIL added helm into full bag")
		fails += 1
	# Stackable onto existing type still works when that type is present —
	# verify wolf pelt cannot start a NEW stack when full of shields.
	if GS.try_add_to_bag("mat_wolf_pelt"):
		print("FAIL started new stack in full bag")
		fails += 1
	GS.bag.clear()
	var swords := 0
	while GS.try_add_to_bag("xiphos"):
		swords += 1
		if swords > 30:
			break
	# 6×6 grid, each sword 1×2 → 18 swords, zero free cells.
	if swords != 18:
		print("FAIL expected 18 swords in 6x6, got ", swords)
		fails += 1
	if GS.try_add_to_bag("xiphos"):
		print("FAIL fitted extra sword")
		fails += 1
	if GS.try_add_to_bag("aspis"):
		print("FAIL shield fit into sword-packed bag")
		fails += 1
	return fails


func _test_sell_prices() -> int:
	var fails := 0
	var pelt: int = GS.item_sell_price("mat_wolf_pelt")
	var horn: int = GS.item_sell_price("mat_minotaur_horn")
	var pot: int = GS.item_sell_price("health_potion")
	if pelt < 10 or pelt > 40:
		print("FAIL pelt sell ", pelt)
		fails += 1
	if horn < 100 or horn > 220:
		print("FAIL minotaur horn sell ", horn)
		fails += 1
	if pot != 10:
		print("FAIL potion sell ", pot)
		fails += 1
	GS.bag.clear()
	GS.gold = 0
	GS.try_add_to_bag("mat_wolf_pelt", 2)
	var gained: int = GS.sell_bag_entry(0, 1)
	if gained != pelt or GS.gold != pelt:
		print("FAIL sell gold ", gained, GS.gold)
		fails += 1
	return fails


func _test_scale_helper() -> int:
	var fails := 0
	var root_n := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 40, 10)
	mi.mesh = box
	root_n.add_child(mi)
	ModelUtils.scale_to_max_extent(root_n, 0.42)
	var extent := ModelUtils.measure_max_extent(root_n)
	if absf(extent - 0.42) > 0.05:
		print("FAIL scale_to_max_extent got ", extent)
		fails += 1
	root_n.free()
	return fails
