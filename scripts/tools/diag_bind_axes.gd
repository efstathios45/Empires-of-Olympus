extends SceneTree



func _init() -> void :
	call_deferred("run")


func run() -> void :
	_dump("hoplite", "res://assets/characters/spartan_hoplite/spartan_hoplite.glb", 1.85)
	_dump("woman", "res://assets/characters/citizen_woman/citizen_woman.glb", 1.68)
	_dump("blacksmith", "res://assets/characters/blacksmith_npc/blacksmith_npc.glb", 1.85)
	quit(0)


func _dump(tag: String, path: String, h: float) -> void :
	var m: Node3D = load(path).instantiate()
	root.add_child(m)
	ModelUtils.setup_character_for_movement(m, h)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	print("==== ", tag, " bones=", skel.get_bone_count())
	for bname in ["Hips", "Spine", "Chest", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftUpperArm"]:
		var i: = skel.find_bone(bname)
		if i < 0:
			print("  missing ", bname)
			continue
		var rest: = skel.get_bone_rest(i)
		var e: = rest.basis.get_euler()
		var x: = rest.basis.x.normalized()
		var y: = rest.basis.y.normalized()
		var z: = rest.basis.z.normalized()
		print("  %s rest_e=(%.1f,%.1f,%.1f) YdotUP=%.3f ZdotFWD=%.3f origin=%s" % [
			bname, rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z), 
			y.dot(Vector3.UP), ( - z).dot(Vector3.FORWARD), rest.origin
		])

	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi: = n as MeshInstance3D
		if mi.skin == null:
			continue
		print("  MESH=", mi.name, " binds=", mi.skin.get_bind_count())
		for bi in mini(3, mi.skin.get_bind_count()):
			var bt: = mi.skin.get_bind_pose(bi)
			print("   bind", bi, " name=", mi.skin.get_bind_name(bi), " scale=", bt.basis.get_scale(), " origin=", bt.origin)
		break
	m.queue_free()
