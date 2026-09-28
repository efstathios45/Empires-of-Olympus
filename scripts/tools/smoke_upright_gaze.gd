extends SceneTree
## Headless: no SkyGazeFix; raw idle upright; zoom gone.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not str(ModelUtils.BUILD_FIX_TOKEN).contains("NO_ZOOM_RAW_IDLE"):
		push_error("BUILD_FIX_TOKEN missing")
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
		push_error("SkyGazeFix must not be installed — raw idle only")
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
	anim.play("ual1_Idle")
	for i in 24:
		await process_frame
	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	var col := (ht.origin - hp.origin).normalized()
	var upright := col.dot(Vector3.UP)
	var slope := Vector2(col.x, col.z).length()
	print("SMOKE_UPRIGHT=", upright, " SLOPE=", slope)
	if upright < 0.95 or slope > 0.20:
		push_error("idle lean too high")
		quit(1)
		return
	print("SMOKE_UPRIGHT_GAZE_OK")
	quit(0)
