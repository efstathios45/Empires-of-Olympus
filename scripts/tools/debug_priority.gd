extends SceneTree
func _init(): call_deferred("run")
func run():
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	root.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel
	for n in m.find_children("*","Skeleton3D",true,false): skel=n; break
	var fix = skel.get_node("LegPlantFix")
	var anim = m.find_child("AnimationPlayer", true, false)
	if anim == null:
		anim = AnimationPlayer.new(); anim.name="AnimationPlayer"; m.add_child(anim)
	var lib = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres")
	if anim.has_animation_library(""): anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	# Test A: plant 1000, anim -100 (current)
	anim.process_priority = -100
	fix.process_priority = 1000
	anim.play("ual1_Walk")
	for i in 10: await process_frame
	var bi = skel.find_bone("LeftUpperLeg")
	var at_rest = skel.get_bone_pose_rotation(bi).is_equal_approx(skel.get_bone_rest(bi).basis.get_rotation_quaternion())
	var lf = (skel.global_transform*skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
	print("A plant1000 anim-100 at_rest=", at_rest, " LFz=", snapped(lf.z,0.01), " mode_locomotion_active")
	# Test B: plant -1000 (after), anim 100
	anim.process_priority = 100
	fix.process_priority = -1000
	for i in 15: await process_frame
	at_rest = skel.get_bone_pose_rotation(bi).is_equal_approx(skel.get_bone_rest(bi).basis.get_rotation_quaternion())
	lf = (skel.global_transform*skel.get_bone_global_pose(skel.find_bone("LeftFoot"))).origin
	print("B plant-1000 anim100 at_rest=", at_rest, " LFz=", snapped(lf.z,0.01))
	# Force manual swing after everything using call_deferred end of frame
	print("DONE")
	quit(0)
