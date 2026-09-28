extends SceneTree
func _init(): call_deferred("r")
func r():
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	_walk(m, 0)
	var anim = m.find_child("AnimationPlayer", true, false)
	var lib = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres")
	if anim.has_animation_library(""): anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.play("ual1_Idle")
	# Force anim to run BEFORE our fix by setting priorities
	anim.process_priority = -50
	var skel
	for n in m.find_children("*","Skeleton3D",true,false): skel=n; break
	var fix = skel.get_node("SkyGazeFix")
	fix.process_priority = 500
	for i in 20: await process_frame
	print("--- AFTER IDLE+FIX ---")
	for name in ["Hips","Spine","Chest","UpperChest","Neck","Head"]:
		var bi = skel.find_bone(name)
		var g = skel.global_transform * skel.get_bone_global_pose(bi)
		var fwd = (-g.basis.z).normalized()
		var up = g.basis.y.normalized()
		print(name, " fwd_up=", fwd.dot(Vector3.UP), " bone_up=", up.dot(Vector3.UP), " o=", g.origin)
	# Mesh AABB lean: top vs bottom center z
	var min_v=Vector3(INF,INF,INF); var max_v=Vector3(-INF,-INF,-INF)
	for c in m.find_children("*","MeshInstance3D",true,false):
		var mi=c as MeshInstance3D
		if mi==null or mi.mesh==null: continue
		var aabb=mi.get_aabb()
		for i in 8:
			var w=mi.to_global(aabb.get_endpoint(i))
			min_v=min_v.min(w); max_v=max_v.max(w)
	print("MESH aabb min=", min_v, " max=", max_v)
	print("MESH top_z=", max_v.z if false else (min_v.z+max_v.z)/2)
	quit(0)
func _walk(n: Node, depth: int):
	if n is Node3D:
		var n3=n as Node3D
		if n3.rotation != Vector3.ZERO or n3.scale != Vector3.ONE:
			print("  ".repeat(depth), n.name, " rot=", n3.rotation_degrees, " scale=", n3.scale, " pos=", n3.position)
	for c in n.get_children():
		_walk(c, depth+1)
