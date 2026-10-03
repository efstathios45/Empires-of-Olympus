extends SceneTree
func _init(): call_deferred("run")
func run():
	for bone in ["LeftUpperLeg", "RightUpperLeg"]:
		for tag_axis in [["z", Vector3(0, 0, 1)], ["nz", Vector3(0, 0, -1)]]:
			await _one(bone, String(tag_axis[0]), tag_axis[1])
	print("DONE")
	quit(0)
func _one(bone, tag, axis):
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	root.add_child(m)
	ModelUtils.scale_to_height(m, 1.85);ModelUtils.ground_model(m)
	var skel
	for n in m.find_children("*", "Skeleton3D", true, false): skel = n;break
	skel.reset_bone_poses()
	var bi = skel.find_bone(bone)
	var q = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
	skel.set_bone_pose_rotation(bi, q * Quaternion(axis.normalized(), 0.9))
	var foot_name = "LeftFoot" if "Left" in bone else "RightFoot"
	var foot = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone(foot_name))).origin
	print(bone, " ", tag, " footZ=", snapped(foot.z, 0.01), " footY=", snapped(foot.y, 0.01), " footX=", snapped(foot.x, 0.01))
	m.queue_free(); await process_frame
