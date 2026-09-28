extends SceneTree
## Headless: zoom removed; fixed distance; no bone gaze twist.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	var text := src.get_as_text()
	src.close()
	if "CAM_ZOOM_MIN" in text or "_apply_cam_zoom" in text:
		push_error("zoom helpers must be removed")
		quit(1)
		return
	if not text.contains("const CAM_DISTANCE := 5.6"):
		push_error("fixed CAM_DISTANCE missing")
		quit(1)
		return
	if not text.contains("MOUSE_BUTTON_WHEEL_UP"):
		push_error("wheel should be swallowed")
		quit(1)
		return

	if not str(ModelUtils.BUILD_FIX_TOKEN).contains("NO_ZOOM_RAW_IDLE"):
		push_error("BUILD_FIX_TOKEN wrong")
		quit(1)
		return

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert(skel != null)
	## Must NOT install a live SkyGazeFix that mutates bones.
	if skel.has_node("SkyGazeFix"):
		push_error("SkyGazeFix must not be installed")
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
	## Raw idle is near-vertical (upright≈0.99). Slope includes authored lateral rest.
	if upright < 0.95 or slope > 0.20:
		push_error("idle not upright: upright=%s slope=%s" % [upright, slope])
		quit(1)
		return
	print("SMOKE_ZOOM_CAMERA_OK")
	quit(0)
