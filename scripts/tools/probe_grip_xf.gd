extends SceneTree
func _init(): call_deferred("run")
func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	root.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")
	for i in 10: await process_frame
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	for i in 5: await process_frame
	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	print("skel global=\n", skel.global_transform)
	for b in ["Wrist.R", "Wrist.L", "LowerArm.R", "LowerArm.L"]:
		var bi = skel.find_bone(b)
		var xf = skel.global_transform * skel.get_bone_global_pose(bi)
		print(b, " origin=", xf.origin, " basis_x=", xf.basis.x, " y=", xf.basis.y, " z=", xf.basis.z)
	if wp:
		print("weapon mount bone=", wp.bone_name, " global_origin=", wp.global_transform.origin)
		print("  basis_x=", wp.global_transform.basis.x, " y=", wp.global_transform.basis.y, " z=", wp.global_transform.basis.z)
		var grip = wp.get_node_or_null("Grip")
		if grip:
			print("  grip local=", grip.transform)
			print("  grip global_o=", grip.global_transform.origin)

			var tip = grip.global_transform * Vector3(0, 0, 0.95)
			var butt = grip.global_transform * Vector3(0, 0, 0)
			print("  spear grip→tip ", butt, " → ", tip)
	if sh:
		print("shield mount bone=", sh.bone_name, " global_origin=", sh.global_transform.origin)
		var grip = sh.get_node_or_null("Grip")
		if grip:
			print("  grip local=", grip.transform)
			print("  grip global_o=", grip.global_transform.origin)

	quit()
