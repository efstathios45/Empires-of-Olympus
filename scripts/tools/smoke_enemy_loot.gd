extends SceneTree


func _init() -> void :
	call_deferred("_run")

func _run() -> void :
	var root: = Node3D.new()
	root.name = "SmokeRoot"
	root.set_script(load("res://scripts/tools/smoke_world_stub.gd"))
	get_root().add_child(root)

	var LootPickup: = load("res://scripts/loot_pickup.gd")
	var gear_ids: = ["xiphos", "bronze_knife", "aspis", "corinthian_helm", "kontos"]
	var ok: = true
	for id in gear_ids:
		var drop: Node = LootPickup.new()
		root.add_child(drop)
		drop.call("setup", id, Vector3(randf_range(-2, 2), 0.2, randf_range(-2, 2)), 0)
		if drop.has_method("_refit_visual"):
			drop.call("_refit_visual")
		print("[smoke_enemy_loot] spawned ", id, " pos=", drop.global_position)

	for i in 3:
		var g: Node = LootPickup.new()
		root.add_child(g)
		g.call("setup", "gold_coin", Vector3(i, 0.2, 0), 5 + i * 3)
	print("SMOKE_ENEMY_LOOT_OK count=", root.get_child_count())
	quit(0 if ok else 1)
