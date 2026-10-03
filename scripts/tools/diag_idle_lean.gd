extends SceneTree
func _init(): call_deferred("r")
func r():
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""): anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n;break
	print("NO_ANIM")
	_dump(skel)
	anim.play("ual1_Idle")
	for i in 20: await process_frame
	print("IDLE")
	_dump(skel)
	var hi = skel.find_bone("Head")
	var hips = skel.find_bone("Hips")
	for deg in [0, 10, 20, 30, 40]:
		m.rotation.x = deg_to_rad( - float(deg))
		m.rotation.y = - PI
		for i in 3: await process_frame
		var ht = skel.global_transform * skel.get_bone_global_pose(hi)
		var hp = skel.global_transform * skel.get_bone_global_pose(hips)
		print("COUNTER_X=", - deg, " head_z=", ht.origin.z, " hips_z=", hp.origin.z, " dz=", ht.origin.z - hp.origin.z, " head_y=", ht.origin.y)
	quit(0)

func _dump(skel: Skeleton3D) -> void :
	for name in ["Hips", "Spine", "Chest", "UpperChest", "Neck", "Head"]:
		var i = skel.find_bone(name)
		if i < 0: continue
		var pose = skel.get_bone_pose(i)
		var e = pose.basis.get_euler()
		var g = skel.get_bone_global_pose(i)
		print(name, " pose_ex=", rad_to_deg(e.x), " glob_o=", g.origin)
