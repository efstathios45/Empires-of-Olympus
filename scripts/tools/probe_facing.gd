extends SceneTree
func _init():
	call_deferred("run")
func run():
	for path in [
		"res://assets/characters/quaternius_hero_king/hero_king.glb", 
		"res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb", 
		"res://assets/characters/greek_hoplite/greek_hoplite.glb", 
	]:
		var m: Node3D = load(path).instantiate()
		root.add_child(m)
		ModelUtils.setup_character_for_movement(m, 1.85)
		var skel: Skeleton3D = m.find_child("Skeleton3D", true, false)
		var anim: AnimationPlayer = m.find_child("AnimationPlayer", true) as AnimationPlayer
		anim.play("Walk")
		for i in 10: await process_frame
		var hips = skel.find_bone("Hips")
		var head = skel.find_bone("Head")
		var wr = skel.find_bone("Wrist.R")
		var wl = skel.find_bone("Wrist.L")
		var fr = skel.find_bone("Foot.R")
		var fl = skel.find_bone("Foot.L")
		print("PATH ", path.get_file())
		print("  plant=", m.find_child("LegPlantFix", true, false) != null)
		print("  Head=", skel.get_bone_global_pose(head).origin)
		print("  Wrist.R=", skel.get_bone_global_pose(wr).origin, " Wrist.L=", skel.get_bone_global_pose(wl).origin)
		print("  Foot.L=", skel.get_bone_global_pose(fl).origin, " Foot.R=", skel.get_bone_global_pose(fr).origin)

		var aabb: = AABB()
		var first = true
		for n in m.find_children("*", "MeshInstance3D", true, false):
			var mi: = n as MeshInstance3D
			if mi.mesh == null: continue
			var a = mi.global_transform * mi.get_aabb()
			if first: aabb = a;first = false
			else: aabb = aabb.merge(a)
		print("  AABB size=", aabb.size, " pos=", aabb.position)
		m.queue_free()
		await process_frame
	quit()
