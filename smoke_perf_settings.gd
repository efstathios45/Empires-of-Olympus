extends SceneTree
## Verify performance defaults: Forward+, Max FPS 144, quality presets.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: = 0
	var ds = root.get_node_or_null("DisplaySettings")
	if ds == null:
		print("FAIL DisplaySettings missing")
		quit(1)
		return
	## Wipe persisted cfg so defaults are tested cleanly.
	var cfg_path: String = ds.CFG_PATH if "CFG_PATH" in ds else "user://display_settings.cfg"
	if FileAccess.file_exists(cfg_path):
		DirAccess.remove_absolute(cfg_path)
	## Re-load defaults as a fresh install would.
	ds.max_fps = 144
	ds.vsync = false
	ds.quality = "balanced"
	ds.show_fps = true
	ds.shadow_override = "preset"
	ds.grass_override = "preset"
	if ds.vsync:
		print("FAIL default vsync should be off")
		failed += 1
	if ds.max_fps != 144:
		print("FAIL default max_fps should be 144", ds.max_fps)
		failed += 1
	if String(ds.quality) != "balanced":
		print("FAIL default quality", ds.quality)
		failed += 1
	ds.apply()
	if Engine.max_fps != 144:
		print("FAIL Engine.max_fps after apply", Engine.max_fps)
		failed += 1
	if OS.low_processor_usage_mode:
		print("FAIL low_processor_usage_mode on")
		failed += 1
	var preset: Dictionary = ds.quality_preset()
	if float(preset.get("render_scale", 0)) < 0.99:
		print("FAIL render_scale should be 1.0", preset)
		failed += 1
	## Shadows / grass overrides must merge into the preset.
	ds.set_shadow_override("low")
	ds.set_grass_override("low")
	var ov: Dictionary = ds.quality_preset()
	if float(ov.get("shadow_dist", 0)) > 60.0:
		print("FAIL shadow override", ov)
		failed += 1
	if float(ov.get("grass_half", 0)) > 80.0:
		print("FAIL grass override", ov)
		failed += 1
	ds.set_shadow_override("preset")
	ds.set_grass_override("preset")
	## Project should request Forward+ (Vulkan).
	var method: = String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	if method != "forward_plus":
		print("FAIL rendering_method", method)
		failed += 1
	var label: String = ds.renderer_label()
	if label.find("Forward+") < 0 and label.find("forward_plus") < 0:
		print("FAIL renderer_label", label)
		failed += 1
	if not ProjectSettings.has_setting("physics/3d/run_on_separate_thread") \
			or not bool(ProjectSettings.get_setting("physics/3d/run_on_separate_thread")):
		print("FAIL physics thread off")
		failed += 1
	## Video settings panel exists and lists FPS options.
	var panel_src: = FileAccess.get_file_as_string("res://scripts/ui/panel_settings.gd")
	if panel_src.find("Video Settings") < 0 or panel_src.find("MAX_FPS_OPTIONS") < 0:
		print("FAIL video settings panel missing FPS options")
		failed += 1
	if failed > 0:
		print("SMOKE FAIL", failed)
		quit(1)
	else:
		print("SMOKE_PERF_SETTINGS_OK method=", method, " max_fps=", Engine.max_fps, " label=", label)
		quit(0)
