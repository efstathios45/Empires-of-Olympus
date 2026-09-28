extends SceneTree
## Headless: close zoom must keep the lens above ~0.95m (no worm's-eye sky-look).
## Run: godot --headless --path . -s res://scripts/tools/smoke_zoom_camera.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	## Exercise the same pitch budget math as player.gd without full world boot.
	const CAM_PIVOT_HEIGHT := 1.55
	const CAM_MIN_HEIGHT := 1.15
	const CAM_ZOOM_MIN := 4.2
	const CAM_ZOOM_MAX := 9.5
	const CAM_PITCH_MAX_CLOSE := -0.18
	const CAM_PITCH_MAX_FAR := 0.42

	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	if src == null:
		push_error("cannot read player.gd")
		quit(1)
		return
	var text := src.get_as_text()
	src.close()
	if not text.contains("const CAM_ZOOM_MIN := 4.2"):
		push_error("CAM_ZOOM_MIN not raised to 4.2")
		quit(1)
		return
	if not text.contains("const CAM_PITCH_MAX_CLOSE := -0.18"):
		push_error("CAM_PITCH_MAX_CLOSE missing/wrong")
		quit(1)
		return
	if not text.contains("spring_arm.collision_mask = 1"):
		push_error("spring arm should collide with environment")
		quit(1)
		return
	if not text.contains("func _max_pitch_for_zoom"):
		push_error("_max_pitch_for_zoom missing")
		quit(1)
		return

	var max_pitch_close := _max_pitch(CAM_ZOOM_MIN, CAM_ZOOM_MIN, CAM_ZOOM_MAX, CAM_PITCH_MAX_CLOSE, CAM_PITCH_MAX_FAR)
	## Negative pitch raises the lens (look-down from above).
	var y_close := CAM_PIVOT_HEIGHT - CAM_ZOOM_MIN * sin(max_pitch_close)
	var max_pitch_far := _max_pitch(CAM_ZOOM_MAX, CAM_ZOOM_MIN, CAM_ZOOM_MAX, CAM_PITCH_MAX_CLOSE, CAM_PITCH_MAX_FAR)
	## Old bug: zoom 2.4 + pitch 0.55 → cam_y ≈ 0.30
	var old_bug_y := 1.55 - 2.4 * sin(0.55)
	print("SMOKE_OLD_BUG_Y=", old_bug_y)
	print("SMOKE_CLOSE_Y=", y_close, " PITCH=", rad_to_deg(max_pitch_close))
	print("SMOKE_FAR_PITCH=", rad_to_deg(max_pitch_far))
	if old_bug_y >= 0.5:
		push_error("sanity: old worm's-eye math broken")
		quit(1)
		return
	if y_close < CAM_MIN_HEIGHT - 0.01:
		push_error("close zoom worm's-eye: %s" % y_close)
		quit(1)
		return
	if max_pitch_close > -0.05:
		push_error("close zoom must keep a look-down: %s" % max_pitch_close)
		quit(1)
		return
	if max_pitch_far < 0.35:
		push_error("far look-up overly restricted: %s" % max_pitch_far)
		quit(1)
		return
	print("SMOKE_ZOOM_CAMERA_OK")
	quit(0)


func _max_pitch(zoom: float, zmin: float, zmax: float, pitch_close: float, pitch_far: float) -> float:
	var t: float = inverse_lerp(zmin, zmax, clampf(zoom, zmin, zmax))
	return lerpf(pitch_close, pitch_far, t)
