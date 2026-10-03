extends SceneTree




func _init() -> void :
	call_deferred("run")

func run() -> void :
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	print("MODEL_ROT=", m.rotation, " SKEL_ROT=", skel.rotation)
	print("SKEL_PARENT=", skel.get_parent().name if skel.get_parent() else "?")
	anim.play("ual1_Idle")
	for i in 20:
		await process_frame
	_report("IDLE", skel, m)

	m.rotation = Vector3.ZERO
	for i in 5:
		await process_frame
	_report("IDLE_Y0", skel, m)
	m.rotation.y = PI
	for i in 5:
		await process_frame
	_report("IDLE_YPI", skel, m)
	quit(0)

func _report(tag: String, skel: Skeleton3D, m: Node3D) -> void :
	var hi: = skel.find_bone("Head")
	var hips: = skel.find_bone("Hips")
	var chest: = skel.find_bone("Chest")
	var ht: = skel.global_transform * skel.get_bone_global_pose(hi)
	var hp: = skel.global_transform * skel.get_bone_global_pose(hips)
	var ct: = skel.global_transform * skel.get_bone_global_pose(chest)

	var head_up: = ht.basis.y.normalized()
	var head_fwd: = ( - ht.basis.z).normalized()
	var lean_xz: = Vector2(ht.origin.x - hp.origin.x, ht.origin.z - hp.origin.z)
	var lean_angle: = rad_to_deg(atan2(lean_xz.length(), ht.origin.y - hp.origin.y))
	print("%s head=%s hips=%s chest=%s lean_deg=%.1f head_up=%s head_fwd=%s up_dot_world=%.3f fwd_dot_world_up=%.3f" % [
		tag, ht.origin, hp.origin, ct.origin, lean_angle, head_up, head_fwd, 
		head_up.dot(Vector3.UP), head_fwd.dot(Vector3.UP)
	])

	for name in ["Hips", "Spine", "Chest", "UpperChest", "Neck", "Head"]:
		var bi: = skel.find_bone(name)
		if bi < 0:
			continue
		var e: = skel.get_bone_pose(bi).basis.get_euler()
		var g: = skel.get_bone_global_pose(bi)
		var ge: = g.basis.get_euler()
		print("  %s pose_e=(%.1f,%.1f,%.1f) glob_e=(%.1f,%.1f,%.1f) o=%s" % [
			name, rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z), 
			rad_to_deg(ge.x), rad_to_deg(ge.y), rad_to_deg(ge.z), g.origin
		])
