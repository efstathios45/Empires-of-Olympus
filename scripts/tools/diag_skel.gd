extends SceneTree
func _init():
	call_deferred("r")
func r():
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	await process_frame
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n; break
	print("skel_name=", skel.name, " bones=", skel.get_bone_count())
	print("skel.rot=", skel.rotation, " parent=", skel.get_parent().name if skel.get_parent() else null)
	# print first bones rest origins and basis euler-ish
	for i in mini(12, skel.get_bone_count()):
		var rest = skel.get_bone_rest(i)
		var e = rest.basis.get_euler()
		print("B", i, " ", skel.get_bone_name(i), " origin=", rest.origin, " euler_deg=", Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)))
	# global pose after setup
	ModelUtils.setup_character_for_movement(m, 1.85)
	await process_frame
	print("--- after setup, no anim ---")
	for i in [0,1,2,6]:
		var gp = skel.get_bone_global_pose(i)
		var e = gp.basis.get_euler()
		print("G", i, " ", skel.get_bone_name(i), " o=", gp.origin, " e=", Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)))
	# with idle
	var anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var lib = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.play("ual1_Idle")
	for _i in 10:
		await process_frame
	print("--- after idle ---")
	for i in [0,1,2,6]:
		var gp = skel.get_bone_global_pose(i)
		var e = gp.basis.get_euler()
		print("G", i, " ", skel.get_bone_name(i), " o=", gp.origin, " e=", Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z)))
	# head world direction (bone +Y or -Z?)
	var head_i = skel.find_bone("Head")
	var ht = skel.global_transform * skel.get_bone_global_pose(head_i)
	print("HEAD_WORLD_ORIGIN=", ht.origin)
	print("HEAD_BASIS_X=", ht.basis.x, " Y=", ht.basis.y, " Z=", ht.basis.z)
	quit(0)
