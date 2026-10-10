extends SceneTree
## Verify performance defaults: Forward+, uncapped FPS, quality presets.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	var ds = root.get_node_or_null("DisplaySettings")
	if ds == null:
		print("FAIL DisplaySettings missing")
		quit(1)
		return
	if ds.vsync:
		print("FAIL default vsync should be off")
		failed += 1
	if ds.max_fps != 0:
		print("FAIL default max_fps should be 0 (uncapped)", ds.max_fps)
		failed += 1
	if String(ds.quality) != "balanced":
		print("FAIL default quality", ds.quality)
		failed += 1
	ds.apply()
	if Engine.max_fps != 0:
		print("FAIL Engine.max_fps after apply", Engine.max_fps)
		failed += 1
	if OS.low_processor_usage_mode:
		print("FAIL low_processor_usage_mode on")
		failed += 1
	var preset: Dictionary = ds.quality_preset()
	if float(preset.get("render_scale", 0)) < 0.99:
		print("FAIL render_scale should be 1.0", preset)
		failed += 1
	## Project should request Forward+.
	var method: = String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	if method != "forward_plus":
		print("FAIL rendering_method", method)
		failed += 1
	if not ProjectSettings.has_setting("physics/3d/run_on_separate_thread") \
			or not bool(ProjectSettings.get_setting("physics/3d/run_on_separate_thread")):
		print("FAIL physics thread off")
		failed += 1
	if failed > 0:
		print("SMOKE FAIL", failed)
		quit(1)
	else:
		print("SMOKE_PERF_SETTINGS_OK method=", method, " max_fps=", Engine.max_fps)
		quit(0)
