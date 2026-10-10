extends Node
## Video + performance. Defaults favor uncapped FPS and Vulkan Forward+.


signal settings_changed

const CFG_PATH: = "user://display_settings.cfg"
const SECTION: = "video"

const RESOLUTIONS: Array = [
	{"id": "1280x720", "label": "1280 × 720", "size": Vector2i(1280, 720)},
	{"id": "1600x900", "label": "1600 × 900", "size": Vector2i(1600, 900)},
	{"id": "1920x1080", "label": "1920 × 1080", "size": Vector2i(1920, 1080)},
	{"id": "2560x1440", "label": "2560 × 1440", "size": Vector2i(2560, 1440)},
	{"id": "native", "label": "Desktop native", "size": Vector2i.ZERO},
]

## Quality presets drive render scale, grass, shadows, glow, MSAA.
const QUALITY_PRESETS: Dictionary = {
	"performance": {
		"label": "Performance",
		"render_scale": 1.0,
		"grass": "performance",
		"shadow_dist": 55.0,
		"glow": false,
		"msaa": Viewport.MSAA_DISABLED,
		"grass_half": 72.0,
		"grass_clusters": 55,
	},
	"balanced": {
		"label": "Balanced",
		"render_scale": 1.0,
		"grass": "balanced",
		"shadow_dist": 90.0,
		"glow": true,
		"msaa": Viewport.MSAA_2X,
		"grass_half": 96.0,
		"grass_clusters": 80,
	},
	"quality": {
		"label": "Quality",
		"render_scale": 1.0,
		"grass": "quality",
		"shadow_dist": 130.0,
		"glow": true,
		"msaa": Viewport.MSAA_4X,
		"grass_half": 120.0,
		"grass_clusters": 110,
	},
}

var window_mode: String = "windowed"
var resolution_id: String = "1920x1080"
## Off by default — V-Sync often caps FPS while leaving GPU idle.
var vsync: bool = false
## 0 = uncapped (uses the PC fully when vsync is off).
var max_fps: int = 0
var quality: String = "balanced"
var show_fps: bool = false


func _ready() -> void:
	## Never throttle the main loop — that starves both CPU and GPU.
	OS.low_processor_usage_mode = false
	load_settings()
	call_deferred("apply")


func load_settings() -> void:
	var cfg: = ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	var ver: = int(cfg.get_value(SECTION, "settings_version", 1))
	window_mode = String(cfg.get_value(SECTION, "window_mode", window_mode))
	resolution_id = String(cfg.get_value(SECTION, "resolution_id", resolution_id))
	vsync = bool(cfg.get_value(SECTION, "vsync", vsync))
	max_fps = int(cfg.get_value(SECTION, "max_fps", max_fps))
	quality = String(cfg.get_value(SECTION, "quality", quality))
	show_fps = bool(cfg.get_value(SECTION, "show_fps", show_fps))
	if not QUALITY_PRESETS.has(quality):
		quality = "balanced"
	## v2: old builds defaulted V-Sync on + OpenGL, which left GPUs idle.
	if ver < 2:
		vsync = false
		max_fps = 0
		if quality == "":
			quality = "balanced"


func save_settings() -> void:
	var cfg: = ConfigFile.new()
	cfg.set_value(SECTION, "settings_version", 2)
	cfg.set_value(SECTION, "window_mode", window_mode)
	cfg.set_value(SECTION, "resolution_id", resolution_id)
	cfg.set_value(SECTION, "vsync", vsync)
	cfg.set_value(SECTION, "max_fps", max_fps)
	cfg.set_value(SECTION, "quality", quality)
	cfg.set_value(SECTION, "show_fps", show_fps)
	cfg.save(CFG_PATH)


func resolution_label() -> String:
	for r in RESOLUTIONS:
		if str(r["id"]) == resolution_id:
			return str(r["label"])
	return resolution_id


func resolution_size() -> Vector2i:
	if resolution_id == "native":
		return DisplayServer.screen_get_size()
	for r in RESOLUTIONS:
		if str(r["id"]) == resolution_id:
			return r["size"] as Vector2i
	return Vector2i(1920, 1080)


func quality_preset() -> Dictionary:
	return QUALITY_PRESETS.get(quality, QUALITY_PRESETS["balanced"])


func apply() -> void:
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	## Uncapped when vsync is off so the GPU can actually work.
	Engine.max_fps = 0 if (not vsync and max_fps <= 0) else maxi(0, max_fps)

	match window_mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var sz: = resolution_size()
			if sz.x > 0 and sz.y > 0:
				DisplayServer.window_set_size(sz)
				var screen: = DisplayServer.window_get_current_screen()
				var screen_size: = DisplayServer.screen_get_size(screen)
				var screen_pos: = DisplayServer.screen_get_position(screen)
				var pos: = screen_pos + (screen_size - sz) / 2
				DisplayServer.window_set_position(pos)

	_apply_viewport_quality()
	save_settings()
	settings_changed.emit()


func _apply_viewport_quality() -> void:
	var preset: = quality_preset()
	var tree: = get_tree()
	if tree == null:
		return
	var vp: = tree.root
	if vp == null:
		return
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = float(preset.get("render_scale", 1.0))
	vp.msaa_3d = int(preset.get("msaa", Viewport.MSAA_DISABLED))
	## Ask the active world to retune grass/shadows/glow.
	var world: = tree.get_first_node_in_group("game_world")
	if world != null and world.has_method("apply_display_quality"):
		world.call("apply_display_quality", preset)


func set_window_mode(mode: String) -> void:
	if mode not in ["windowed", "fullscreen", "borderless"]:
		return
	window_mode = mode
	apply()


func set_resolution_id(id: String) -> void:
	resolution_id = id
	if window_mode == "windowed":
		apply()
	else:
		save_settings()
		settings_changed.emit()


func set_vsync(on: bool) -> void:
	vsync = on
	apply()


func set_max_fps(fps: int) -> void:
	max_fps = maxi(0, fps)
	apply()


func set_quality(id: String) -> void:
	if not QUALITY_PRESETS.has(id):
		return
	quality = id
	apply()


func cycle_max_fps() -> void:
	## 0 (uncapped) → 60 → 120 → 144 → 240 → 0
	var opts: Array = [0, 60, 120, 144, 240]
	var idx: = opts.find(max_fps)
	max_fps = int(opts[(idx + 1) % opts.size()]) if idx >= 0 else 0
	apply()


func cycle_quality() -> void:
	var keys: Array = ["performance", "balanced", "quality"]
	var idx: = keys.find(quality)
	quality = String(keys[(idx + 1) % keys.size()]) if idx >= 0 else "balanced"
	apply()


func max_fps_label() -> String:
	if max_fps <= 0:
		return "Uncapped"
	return "%d FPS" % max_fps


func quality_label() -> String:
	return String(quality_preset().get("label", quality.capitalize()))
