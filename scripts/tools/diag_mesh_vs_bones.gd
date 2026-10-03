extends SceneTree


func _init() -> void :
	call_deferred("run")

func run() -> void :
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var fix: = skel.get_node_or_null("SkyGazeFix")
	if fix:
		fix.set_process(false)
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)

	for mode in ["REST", "IDLE"]:
		if mode == "REST":
			anim.stop()
			skel.reset_bone_poses()
		else:
			anim.play("ual1_Idle")
		for i in 15:
			await process_frame
		_report(mode, m, skel)

	if fix:
		fix.set_process(true)
	for i in 8:
		await process_frame
	_report("IDLE_FIX", m, skel)
	quit(0)

func _report(tag: String, m: Node3D, skel: Skeleton3D) -> void :
	var hi: = skel.find_bone("Head")
	var hips: = skel.find_bone("Hips")
	var ht: = skel.global_transform * skel.get_bone_global_pose(hi)
	var hp: = skel.global_transform * skel.get_bone_global_pose(hips)

	var min_v: = Vector3(INF, INF, INF)
	var max_v: = Vector3( - INF, - INF, - INF)
	for child in m.find_children("*", "MeshInstance3D", true, false):
		var mi: = child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var aabb: = mi.get_aabb()
		for i in 8:
			var w: Vector3 = mi.to_global(aabb.get_endpoint(i))
			min_v = min_v.min(w)
			max_v = max_v.max(w)
	var mesh_c: = (min_v + max_v) * 0.5
	var mesh_top: = Vector3(mesh_c.x, max_v.y, mesh_c.z)

	print("%s bone_head=%s bone_hips=%s mesh_center=%s mesh_topY=%s mesh_size=%s" % [
		tag, ht.origin, hp.origin, mesh_c, max_v.y, max_v - min_v
	])
	print("  head_vs_hips_dz=%.3f mesh_center_vs_hips_dz=%.3f head_fwd_up=%.3f" % [
		ht.origin.z - hp.origin.z, mesh_c.z - hp.origin.z, 
		( - ht.basis.z).normalized().dot(Vector3.UP)
	])
