extends SceneTree
## Headless: raw UAL idle stays upright WITHOUT SkyGazeFix (which made lean worse).
## Metin2 camera must stay look-down.
## Run: godot --headless --path . -s res://scripts/tools/smoke_upright_gaze.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not str(ModelUtils.BUILD_FIX_TOKEN).contains("NO_GAZE_TWIST"):
		push_error("BUILD_FIX_TOKEN missing NO_GAZE_TWIST")
		quit(1)
		return

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	if skel == null:
		push_error("no skeleton")
		quit(1)
		return
	if skel.has_node("SkyGazeFix"):
		push_error("SkyGazeFix must stay disabled — it twisted hips/legs")
		quit(1)
		return

	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)

	for clip in ["ual1_Idle", "ual1_Walk"]:
		if not anim.has_animation(clip):
			continue
		anim.play(clip)
		for i in 24:
			await process_frame
		var hi := skel.find_bone("Head")
		var hips := skel.find_bone("Hips")
		var ht: Transform3D = skel.global_transform * skel.get_bone_global_pose(hi)
		var hp: Transform3D = skel.global_transform * skel.get_bone_global_pose(hips)
		var upright: float = (ht.origin - hp.origin).normalized().dot(Vector3.UP)
		print("SMOKE_CLIP=", clip, " UPRIGHT=", upright, " NO_FIX=true")
		## Raw UAL idle is already near-upright; do not require perfect 1.0.
		if upright < 0.97:
			push_error("%s unexpectedly leaned: %s" % [clip, upright])
			quit(1)
			return

	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	var text := src.get_as_text()
	src.close()
	if not text.contains("const CAM_PITCH_MAX := -0.32"):
		push_error("Metin2 look-down camera missing")
		quit(1)
		return

	print("SMOKE_UPRIGHT_GAZE_OK")
	quit(0)
