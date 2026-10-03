extends SceneTree


func _init() -> void :
	call_deferred("run")


func run() -> void :
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	root.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var fix: Node = skel.get_node("LegPlantFix")
	print("BEFORE_ENSURE fix_anim_null=", fix.get("_anim") == null)
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
		print("CREATED AnimationPlayer after plant")
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.process_priority = -100
	fix.process_priority = 1000
	anim.play("ual1_Walk")
	print("has_Walk=", anim.has_animation("ual1_Walk"), " current=", anim.current_animation)
	for i in 30:
		await process_frame

		var af: Variant = fix.get("_anim")
		var lf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
		var rf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("RightFoot"))).origin
		var li: = skel.find_bone("LeftUpperLeg")
		var at_rest: = skel.get_bone_pose_rotation(li).is_equal_approx(
			skel.get_bone_rest(li).basis.get_rotation_quaternion())
		if i % 6 == 0:
			print("i=", i, " t=", snapped(anim.current_animation_position, 0.01), 
				" fixAnim=", af != null, " playing=", anim.is_playing(), 
				" LFz=", snapped(lf.z, 0.001), " RFz=", snapped(rf.z, 0.001), 
				" legRest=", at_rest)

	fix.set_process(false)
	skel.reset_bone_poses()
	anim.seek(0.0)
	anim.play("ual1_Walk")
	var zs: Array = []
	for i in 20:
		await process_frame
		var lf2: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
		zs.append(snapped(lf2.z, 0.001))
	print("NO_PLANT LFz samples=", zs)
	print("DEBUG_WALK_DONE")
	quit(0)
