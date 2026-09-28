extends SceneTree
## Headless: Metin2 zoom — distance only; pitch always look-down.
## Run: godot --headless --path . -s res://scripts/tools/smoke_zoom_camera.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	if src == null:
		push_error("cannot read player.gd")
		quit(1)
		return
	var text := src.get_as_text()
	src.close()
	for needle in [
		"const CAM_ZOOM_MIN := 3.6",
		"const CAM_PITCH_MAX := -0.32",
		"const CAM_PITCH_MIN := -0.95",
		"spring_arm.collision_mask = 1",
	]:
		if not text.contains(needle):
			push_error("missing camera const/setup: " + needle)
			quit(1)
			return
	## Old worm's-eye: zoom 2.4 + pitch +0.55 → cam_y ≈ 0.30
	var old_bug_y := 1.55 - 2.4 * sin(0.55)
	## New: min zoom + shallowest look-down still keeps lens above shoulders.
	var new_y := 1.45 - 3.6 * sin(-0.32)  ## sin(-0.32)<0 → raises lens
	print("SMOKE_OLD_BUG_Y=", old_bug_y, " NEW_MIN_CAM_Y=", new_y)
	if old_bug_y >= 0.5:
		push_error("old bug sanity failed")
		quit(1)
		return
	if new_y < 1.3:
		push_error("metin2 min framing too low: %s" % new_y)
		quit(1)
		return
	print("SMOKE_ZOOM_CAMERA_OK")
	quit(0)
