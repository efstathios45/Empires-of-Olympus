extends SceneTree
func _init(): call_deferred("run")
func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	root.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")
	for i in 12: await process_frame
	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var hi = skel.find_bone("Head")
	var head_xf = skel.global_transform * skel.get_bone_global_pose(hi)
	print("Head bone idx=", hi, " world=", head_xf.origin)
	var mount = hero.find_child("CorinthianHelmMount", true, false)
	print("mount class=", mount.get_class() if mount else null)
	if mount is BoneAttachment3D:
		var ba: = mount as BoneAttachment3D
		print("bone_name=", ba.bone_name, " bone_idx=", ba.bone_idx)
		print("mount global=", ba.global_transform.origin)
	var helm = hero.find_child("CorinthianHelm", true, false)
	if helm:
		print("helm global=", helm.global_transform.origin)
		for c in helm.get_children():
			if c is Node3D:
				print("  part ", c.name, " world=", (c as Node3D).global_transform.origin)

	for bname in ["Head", "head", "Neck", "Chest", "Hips", "Body"]:
		var bi = skel.find_bone(bname)
		if bi >= 0:
			var p = (skel.global_transform * skel.get_bone_global_pose(bi)).origin
			print("bone ", bname, " idx=", bi, " y=", p.y, " pos=", p)
	quit()
