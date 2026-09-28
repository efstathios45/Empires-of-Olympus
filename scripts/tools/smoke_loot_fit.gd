extends SceneTree
## Headless smoke: fit gear GLB loot the same path as combat drops.
## Run: godot --headless --path . -s res://scripts/tools/smoke_loot_fit.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var ids := ["xiphos", "aspis", "corinthian_helm", "health_potion", "gold_coin"]
	var root := Node3D.new()
	root.name = "SmokeRoot"
	root.add_to_group("game_world")
	root.set_script(load("res://scripts/tools/smoke_world_stub.gd"))
	get_root().add_child(root)

	var LootPickup := load("res://scripts/loot_pickup.gd")
	if LootPickup == null:
		push_error("FAIL: loot_pickup.gd missing")
		quit(1)
		return

	for id in ids:
		var drop: Node = LootPickup.new()
		root.add_child(drop)
		drop.call("setup", id, Vector3(0, 0.2, 0), 12 if id == "gold_coin" else 0)
		## Force deferred refit synchronously.
		if drop.has_method("_refit_visual"):
			drop.call("_refit_visual")
		var extent := 0.0
		var mesh_root: Node3D = drop.get_node_or_null("Mesh") as Node3D
		if mesh_root != null:
			for child in mesh_root.get_children():
				if child is Node3D:
					extent = maxf(extent, ModelUtils.measure_max_extent(child as Node3D))
		print("[smoke_loot] id=", id, " children=", mesh_root.get_child_count() if mesh_root else -1, " extent=", extent)
		drop.queue_free()

	## Direct GLB fit path (weapon with meshes).
	var glb := "res://assets/props/gear/xiphos_sword.glb"
	if ResourceLoader.exists(glb):
		var scene: PackedScene = load(glb) as PackedScene
		var inst: Node3D = scene.instantiate()
		root.add_child(inst)
		ModelUtils.scale_to_max_extent(inst, 0.70)
		var e := ModelUtils.measure_max_extent(inst)
		print("[smoke_loot] direct xiphos extent=", e)
		if e <= 0.0 or e > 1.5:
			push_error("FAIL: xiphos extent out of range: %s" % e)
			ok = false
		else:
			print("OK: xiphos fit")
	else:
		push_error("FAIL: missing %s" % glb)
		ok = false

	if ok:
		print("SMOKE_LOOT_FIT_OK")
		quit(0)
	else:
		print("SMOKE_LOOT_FIT_FAIL")
		quit(1)
