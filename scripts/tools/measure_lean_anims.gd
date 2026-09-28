extends SceneTree
## Compare head forward-up for several clips to see if lean is global bias.

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	print("CLIPS=", anim.get_animation_list())
	# Rest / no anim
	anim.stop()
	skel.reset_bone_poses()
	for i in 5:
		await process_frame
	_report("REST", skel)
	for clip in ["ual1_Idle", "ual1_Walk", "ual1_Sprint", "ual1_Sword_Idle", "Idle_Loop", "Walk_Loop", "Sword_Idle"]:
		if not anim.has_animation(clip):
			print("MISSING ", clip)
			continue
		anim.play(clip)
		for i in 12:
			await process_frame
		_report(clip, skel)
	quit(0)

func _report(tag: String, skel: Skeleton3D) -> void:
	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	var head_fwd := (-ht.basis.z).normalized()
	var head_up := ht.basis.y.normalized()
	var chest_i := skel.find_bone("UpperChest")
	var ct := skel.get_bone_global_pose(chest_i)
	var ce := ct.basis.get_euler()
	print("%s fwd_up=%.3f up_world=%.3f head_glob_ex=%.1f upperchest_glob_ex=%.1f dz=%.3f" % [
		tag, head_fwd.dot(Vector3.UP), head_up.dot(Vector3.UP),
		rad_to_deg(ht.basis.get_euler().x), rad_to_deg(ce.x),
		ht.origin.z - hp.origin.z
	])
