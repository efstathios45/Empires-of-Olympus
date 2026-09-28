extends SceneTree
func _init(): call_deferred("run")
func run():
	for path in [
		"res://assets/characters/quaternius_hero_king/hero_king.glb",
		"res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb",
		"res://assets/characters/quaternius_guard_soldier_f/guard_soldier_f.glb",
	]:
		if not ResourceLoader.exists(path):
			print("MISSING ", path); continue
		var m: Node3D = load(path).instantiate()
		root.add_child(m)
		ModelUtils.setup_character_for_movement(m, 1.85)
		await process_frame
		var skel: Skeleton3D = m.find_child("Skeleton3D", true, false)
		var wr = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
		var ul = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("UpperArm.R"))
		print("=== ", path.get_file(), " UpperArm.R=", ul.origin, " Wrist.R=", wr.origin)
		for n in m.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null: continue
			var aabb = mi.get_aabb()
			# count approx verts near right arm corridor
			print("  mesh ", mi.name, " visible=", mi.visible, " aabb=", aabb.size)
		m.queue_free()
		await process_frame
	quit()
