extends SceneTree
## Verify loot GLBs scale to pocket size (no giant blocks).

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var paths := [
		"res://assets/props/gear/xiphos_sword.glb",
		"res://assets/props/gear/aspis_shield.glb",
		"res://assets/props/gear/corinthian_helmet.glb",
		"res://assets/props/gear/kontos_spear.glb",
		"res://assets/props/weapons/cretan_bow.glb",
	]
	var failed := 0
	for path in paths:
		if not ResourceLoader.exists(path):
			print("SKIP missing ", path)
			continue
		var scene: PackedScene = load(path) as PackedScene
		if scene == null:
			print("FAIL load ", path)
			failed += 1
			continue
		var inst: Node3D = scene.instantiate()
		root.add_child(inst)
		await process_frame
		var before: float = ModelUtils.measure_max_extent(inst)
		ModelUtils.scale_to_max_extent(inst, 0.42)
		var after: float = ModelUtils.measure_max_extent(inst)
		print("SCALE ", path.get_file(), " before=", snappedf(before, 0.01), " after=", snappedf(after, 0.01))
		if after > 0.55 or after < 0.2:
			print("FAIL bad extent ", after)
			failed += 1
		inst.queue_free()
	# Stub-sized box sanity (what potions use).
	var stub := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.28, 0.28)
	stub.mesh = box
	root.add_child(stub)
	if ModelUtils.measure_max_extent(stub) > 0.5:
		print("FAIL stub too big")
		failed += 1
	stub.queue_free()
	if failed == 0:
		print("LOOT_SCALE_OK")
		quit(0)
	else:
		print("LOOT_SCALE_FAIL ", failed)
		quit(1)
