extends SceneTree
func _init(): call_deferred("run")
func run():
	var WeaponGrip = load("res://scripts/weapon_grip.gd")
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	root.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")
	for i in 8: await process_frame
	var wp = WeaponGrip.attach(hero, "res://assets/props/weapons/dory_spear.glb", "melee", {
		"bone": "Wrist.R", "position": Vector3(0.02, 0.08, 0.0), 
		"rotation_deg": Vector3(90, 0, 0), "scale": 1.05, 
	})
	for i in 4: await process_frame
	var grip = wp.get_node("Grip")
	var butt = grip.global_transform * Vector3(0, 0, 0)
	var tip = grip.global_transform * Vector3(0, 0, 0.95)
	var mid = grip.global_transform * Vector3(0, 0, 0.47)
	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var wr = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
	print("wrist=", wr.origin)
	print("butt=", butt, " mid=", mid, " tip=", tip)
	print("butt-wrist dist=", butt.distance_to(wr.origin))

	var aabb: = AABB()
	var first = true
	for n in wp.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi.mesh == null: continue
		var a = mi.global_transform * mi.get_aabb()
		if first: aabb = a;first = false
		else: aabb = aabb.merge(a)
	print("weapon AABB center=", aabb.get_center(), " size=", aabb.size)
	print("weapon y range=", aabb.position.y, "..", aabb.position.y + aabb.size.y)
	quit()
