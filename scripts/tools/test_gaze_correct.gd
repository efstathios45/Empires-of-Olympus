extends SceneTree
## Trial sky-gaze correction — measure only (no GPU capture in headless).

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	ModelUtils.install_sky_gaze_fix(m)
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

	for clip in ["ual1_Idle", "ual1_Walk", "ual1_Sword_Idle", "ual1_Sprint"]:
		# Raw (temporarily disable fix)
		var fix := skel.get_node_or_null("SkyGazeFix")
		if fix:
			fix.set_process(false)
		anim.play(clip)
		for i in 12:
			await process_frame
		_report(clip + "_raw", skel)
		# Fixed
		if fix:
			fix.set_process(true)
		for i in 8:
			await process_frame
		_report(clip + "_fix", skel)

	print("GAZE_CORRECT_OK")
	quit(0)

func _report(tag: String, skel: Skeleton3D) -> void:
	var hi := skel.find_bone("Head")
	var chest := skel.find_bone("UpperChest")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var ct := skel.global_transform * skel.get_bone_global_pose(chest)
	var fwd := (-ht.basis.z).normalized()
	print("%s fwd_up=%.3f head_ex=%.1f chest_ex=%.1f head_up_dot=%.3f" % [
		tag, fwd.dot(Vector3.UP), rad_to_deg(ht.basis.get_euler().x),
		rad_to_deg(ct.basis.get_euler().x), ht.basis.y.normalized().dot(Vector3.UP)
	])
