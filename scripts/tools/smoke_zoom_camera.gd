extends SceneTree
## Headless: close zoom must keep the lens above ~0.95m (no worm's-eye sky-look).
## Run: godot --headless --path . -s res://scripts/tools/smoke_zoom_camera.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	## Exercise the same pitch budget math as player.gd without full world boot.
	const CAM_PIVOT_HEIGHT := 1.55
	const CAM_MIN_HEIGHT := 0.95
	const CAM_ZOOM_MIN := 3.8
	const CAM_ZOOM_MAX := 9.5
	const CAM_PITCH_MAX_FAR := 0.42

	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	if src == null:
		push_error("cannot read player.gd")
		quit(1)
		return
	var text := src.get_as_text()
	src.close()
	if not text.contains("const CAM_ZOOM_MIN := 3.8"):
		push_error("CAM_ZOOM_MIN not raised to 3.8")
		quit(1)
		return
	if not text.contains("const CAM_MIN_HEIGHT := 0.95"):
		push_error("CAM_MIN_HEIGHT missing")
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

	var max_pitch_close := _max_pitch(CAM_ZOOM_MIN, CAM_ZOOM_MIN, CAM_ZOOM_MAX, CAM_PIVOT_HEIGHT, CAM_MIN_HEIGHT, CAM_PITCH_MAX_FAR)
	var y_close := CAM_PIVOT_HEIGHT - CAM_ZOOM_MIN * sin(max_pitch_close)
	var max_pitch_far := _max_pitch(CAM_ZOOM_MAX, CAM_ZOOM_MIN, CAM_ZOOM_MAX, CAM_PIVOT_HEIGHT, CAM_MIN_HEIGHT, CAM_PITCH_MAX_FAR)
	## Old bug: zoom 2.4 + pitch 0.55 → cam_y ≈ 0.30
	var old_bug_y := 1.55 - 2.4 * sin(0.55)
	print("SMOKE_OLD_BUG_Y=", old_bug_y)
	print("SMOKE_CLOSE_Y=", y_close, " PITCH=", rad_to_deg(max_pitch_close))
	print("SMOKE_FAR_PITCH=", rad_to_deg(max_pitch_far))
	assert(old_bug_y < 0.5, "sanity: old worm's-eye still reproduces in math")
	assert(y_close >= CAM_MIN_HEIGHT - 0.01, "close zoom worm's-eye: %s" % y_close)
	assert(max_pitch_close < 0.25, "close look-up still too steep")
	assert(max_pitch_far >= 0.35, "far look-up overly restricted")
	print("SMOKE_ZOOM_CAMERA_OK")
	quit(0)


func _max_pitch(
	zoom: float, zmin: float, zmax: float, pivot_y: float, min_h: float, pitch_far: float
) -> float:
	var drop_budget: float = pivot_y - min_h
	var close_max: float = asin(clampf(drop_budget / maxf(zmin, 0.1), 0.0, 0.95))
	var t: float = inverse_lerp(zmin, zmax, clampf(zoom, zmin, zmax))
	return lerpf(close_max, pitch_far, t)
