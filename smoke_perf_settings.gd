extends SceneTree
## Verify performance defaults: Forward+, Max FPS 144, Performance quality.


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
	ds.quality = "performance"
	ds.show_fps = true
	ds.shadow_override = "preset"
	ds.grass_override = "preset"
	if ds.vsync:
		print("FAIL default vsync should be off")
		failed += 1
	if ds.max_fps != 144:
		print("FAIL default max_fps should be 144", ds.max_fps)
		failed += 1
	if String(ds.quality) != "performance":
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
	if float(preset.get("grass_clusters", 999)) > 40.0:
		print("FAIL performance grass too dense", preset)
		failed += 1
	if bool(preset.get("glow", true)):
		print("FAIL performance should disable glow", preset)
		failed += 1
	if float(preset.get("render_scale", 0)) < 0.8:
		print("FAIL render_scale too low", preset)
		failed += 1
	## Shadows / grass overrides must merge into the preset.
	ds.set_shadow_override("low")
	ds.set_grass_override("low")
	var ov: Dictionary = ds.quality_preset()
	if float(ov.get("shadow_dist", 0)) > 55.0:
		print("FAIL shadow override", ov)
		failed += 1
	if float(ov.get("grass_half", 0)) > 65.0:
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
	var shadow_sz: = int(ProjectSettings.get_setting(
		"rendering/lights_and_shadows/directional_shadow/size", 0))
	if shadow_sz > 2048:
		print("FAIL default shadow atlas too large", shadow_sz)
		failed += 1
	## Video settings panel exists and lists FPS options.
	var panel_src: = FileAccess.get_file_as_string("res://scripts/ui/panel_settings.gd")
	if panel_src.find("Video Settings") < 0 or panel_src.find("MAX_FPS_OPTIONS") < 0:
		print("FAIL video settings panel missing FPS options")
		failed += 1
	## v4 migrates old balanced installs once.
	var cfg: = ConfigFile.new()
	cfg.set_value("video", "settings_version", 3)
	cfg.set_value("video", "quality", "balanced")
	cfg.set_value("video", "max_fps", 144)
	cfg.set_value("video", "vsync", false)
	cfg.save(cfg_path)
	ds.load_settings()
	if String(ds.quality) != "performance":
		print("FAIL v4 migrate balanced→performance", ds.quality)
		failed += 1
	if failed > 0:
		print("SMOKE FAIL", failed)
		quit(1)
	else:
		print("SMOKE_PERF_SETTINGS_OK method=", method, " max_fps=", Engine.max_fps,
			" quality=", ds.quality, " label=", label)
		quit(0)
