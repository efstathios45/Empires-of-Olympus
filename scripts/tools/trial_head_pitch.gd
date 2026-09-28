extends SceneTree
func _init(): call_deferred("run")
func run():
	for tag_axis in [["x", Vector3(1,0,0)],["nx", Vector3(-1,0,0)],["z", Vector3(0,0,1)],["nz", Vector3(0,0,-1)]]:
		var m = load("res://assets/characters/citizen_woman/citizen_woman.glb").instantiate()
		root.add_child(m)
		ModelUtils.setup_character_for_movement(m, 1.68)
		var skel
		for n in m.find_children("*","Skeleton3D",true,false): skel=n; break
		# disable plant process to control manually
		skel.get_node("LegPlantFix").set_process(false)
		skel.reset_bone_poses()
		for b in ["Head","Neck"]:
			var bi = skel.find_bone(b)
			var q = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
			skel.set_bone_pose_rotation(bi, q * Quaternion(tag_axis[1].normalized(), 0.35))
		await process_frame
		var g = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Head"))
		var fwd = (-g.basis.z).normalized()
		var pitch = rad_to_deg(asin(clampf(fwd.y,-1,1)))
		print(tag_axis[0], " pitch=", snapped(pitch,0.1), " fwd=", fwd)
		m.queue_free(); await process_frame
	quit(0)
