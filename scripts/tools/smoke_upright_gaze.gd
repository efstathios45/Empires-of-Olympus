extends SceneTree
## Headless: hero idle/walk must stand upright (Metin2) — no sky lean.
## Run: godot --headless --path . -s res://scripts/tools/smoke_upright_gaze.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not str(ModelUtils.BUILD_FIX_TOKEN).contains("METIN2_UPRIGHT"):
		push_error("BUILD_FIX_TOKEN missing METIN2_UPRIGHT")
		quit(1)
		return

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
	if skel == null or not skel.has_node("SkyGazeFix"):
		push_error("SkyGazeFix missing")
		quit(1)
		return
	anim.process_priority = -100
	var fix := skel.get_node("SkyGazeFix")
	if fix is SkeletonModifier3D:
		(fix as SkeletonModifier3D).active = true

	for clip in ["ual1_Idle", "ual1_Walk", "ual1_Sprint"]:
		if not anim.has_animation(clip):
			continue
		anim.play(clip)
		for i in 24:
			await process_frame
		var hi := skel.find_bone("Head")
		var hips := skel.find_bone("Hips")
		var ht: Transform3D = skel.global_transform * skel.get_bone_global_pose(hi)
		var hp: Transform3D = skel.global_transform * skel.get_bone_global_pose(hips)
		var col: Vector3 = (ht.origin - hp.origin).normalized()
		var upright: float = col.dot(Vector3.UP)
		var fwd_up: float = (-ht.basis.z).normalized().dot(Vector3.UP)
		print("SMOKE_CLIP=", clip, " UPRIGHT=", upright, " FWD_UP=", fwd_up)
		if upright < 0.997:
			push_error("%s not upright: %s (need >= 0.997 / ~4°)" % [clip, upright])
			quit(1)
			return
		if absf(fwd_up) > 0.06:
			push_error("%s head not level: %s" % [clip, fwd_up])
			quit(1)
			return

	## Camera constants: Metin2 look-down only.
	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	var text := src.get_as_text()
	src.close()
	if not text.contains("const CAM_PITCH_MAX := -0.32"):
		push_error("camera must stay look-down (CAM_PITCH_MAX)")
		quit(1)
		return
	if text.contains("func _max_pitch_for_zoom"):
		push_error("zoom-linked pitch helper should be removed")
		quit(1)
		return

	print("SMOKE_UPRIGHT_GAZE_OK")
	quit(0)
