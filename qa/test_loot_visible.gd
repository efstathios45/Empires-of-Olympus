extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var gs_script = load("res://scripts/autoloads/game_state.gd")
	var gs = gs_script.new()
	gs.name = "GameState"
	root.add_child(gs)
	# Force as singleton-like for scripts that look up /root/GameState — they use Autoload name.
	# Autoloads from --script aren't registered; patch by making node name GameState and relying on
	# get_node("/root/GameState") if used. Game scripts use global GameState identifier which fails.
	# So instead manually build visuals like loot_pickup does.
	var fails := 0
	for id in ["xiphos", "aspis", "corinthian_helm", "kontos"]:
		var def: Dictionary = gs.item_def(id)
		var glb := String(def.get("glb", ""))
		print("DEF ", id, " glb=", glb, " exists=", ResourceLoader.exists(glb))
		if glb == "" or not ResourceLoader.exists(glb):
			print("FAIL missing glb ", id)
			fails += 1
			continue
		var scene: PackedScene = load(glb)
		var inst: Node3D = scene.instantiate()
		root.add_child(inst)
		await process_frame
		var before := ModelUtils.measure_max_extent(inst)
		ModelUtils.scale_to_max_extent(inst, float({"weapon":0.7,"shield":0.55,"helmet":0.32}.get(String(def.get("kind","")), 0.4)))
		ModelUtils.ground_model(inst, 0.02)
		var after := ModelUtils.measure_max_extent(inst)
		var meshes := 0
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).mesh != null:
				meshes += 1
		print("MESH ", id, " before=", snappedf(before,0.01), " after=", snappedf(after,0.01), " meshes=", meshes)
		if meshes < 1:
			print("FAIL no meshes in glb ", id)
			fails += 1
		if after > 1.1 or after < 0.08:
			print("FAIL bad extent ", after)
			fails += 1
		inst.queue_free()
		await process_frame
	if fails == 0:
		print("LOOT_MESH_OK")
		quit(0)
	else:
		print("LOOT_MESH_FAIL ", fails)
		quit(1)
