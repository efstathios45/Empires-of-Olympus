extends Node
## Video + performance. Vulkan Forward+; default Max FPS 144 for smooth play.


signal settings_changed

const CFG_PATH: = "user://display_settings.cfg"
const SECTION: = "video"
const SETTINGS_VERSION: = 4

const RESOLUTIONS: Array = [
	{"id": "1280x720", "label": "1280 × 720", "size": Vector2i(1280, 720)},
	{"id": "1600x900", "label": "1600 × 900", "size": Vector2i(1600, 900)},
	{"id": "1920x1080", "label": "1920 × 1080", "size": Vector2i(1920, 1080)},
	{"id": "2560x1440", "label": "2560 × 1440", "size": Vector2i(2560, 1440)},
	{"id": "native", "label": "Desktop native", "size": Vector2i.ZERO},
]

const MAX_FPS_OPTIONS: Array = [0, 60, 120, 144, 240]

## Quality presets drive render scale, grass, shadows, glow, MSAA.
## Hellas is large — Balanced used to mean MSAA2 + dense grass + long shadows
## and felt like "the game always lags". Defaults lean leaner; Quality stays pretty.
const QUALITY_PRESETS: Dictionary = {
	"performance": {
		"label": "Performance",
		"render_scale": 0.85,
		"grass": "performance",
		"shadow_dist": 45.0,
		"shadow_size": 1024,
		"glow": false,
		"msaa": Viewport.MSAA_DISABLED,
		"grass_half": 56.0,
		"grass_clusters": 28,
		"grass_view": 85.0,
		"road_detail": false,
	},
	"balanced": {
		"label": "Balanced",
		"render_scale": 1.0,
		"grass": "balanced",
		"shadow_dist": 70.0,
		"shadow_size": 2048,
		"glow": false,
		"msaa": Viewport.MSAA_DISABLED,
		"grass_half": 72.0,
		"grass_clusters": 42,
		"grass_view": 110.0,
		"road_detail": true,
	},
	"quality": {
		"label": "Quality",
		"render_scale": 1.0,
		"grass": "quality",
		"shadow_dist": 110.0,
		"shadow_size": 4096,
		"glow": true,
		"msaa": Viewport.MSAA_2X,
		"grass_half": 96.0,
		"grass_clusters": 70,
		"grass_view": 140.0,
		"road_detail": true,
	},
}

const SHADOW_OVERRIDES: Dictionary = {
	"low": 45.0,
	"med": 70.0,
	"high": 110.0,
}

const GRASS_OVERRIDES: Dictionary = {
	"low": {"grass": "performance", "grass_half": 56.0, "grass_clusters": 28, "grass_view": 85.0},
	"med": {"grass": "balanced", "grass_half": 72.0, "grass_clusters": 42, "grass_view": 110.0},
	"high": {"grass": "quality", "grass_half": 96.0, "grass_clusters": 70, "grass_view": 140.0},
}

var window_mode: String = "windowed"
var resolution_id: String = "1920x1080"
## Off by default — V-Sync often caps FPS while leaving GPU idle.
var vsync: bool = false
## 144 keeps frames smooth without burning the GPU at unlimited FPS.
var max_fps: int = 144
## Performance is the ship default — Hellas dens/roads/grass are heavy.
var quality: String = "performance"
var show_fps: bool = true
## "preset" follows the quality tier; otherwise low/med/high.
var shadow_override: String = "preset"
var grass_override: String = "preset"


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
	shadow_override = String(cfg.get_value(SECTION, "shadow_override", shadow_override))
	grass_override = String(cfg.get_value(SECTION, "grass_override", grass_override))
	if not QUALITY_PRESETS.has(quality):
		quality = "balanced"
	if shadow_override not in ["preset", "low", "med", "high"]:
		shadow_override = "preset"
	if grass_override not in ["preset", "low", "med", "high"]:
		grass_override = "preset"
	## v2: old builds defaulted V-Sync on + OpenGL, which left GPUs idle.
	if ver < 2:
		vsync = false
		max_fps = 144
		if quality == "":
			quality = "balanced"
	## v3: uncapped (0) often feels like lag/heat; prefer a smooth 144 cap.
	if ver < 3 and max_fps == 0 and not vsync:
		max_fps = 144
		show_fps = true
	## v4: old "balanced" was too heavy for the full Hellas map — migrate once.
	if ver < 4 and quality == "balanced":
		quality = "performance"


func save_settings() -> void:
	var cfg: = ConfigFile.new()
	cfg.set_value(SECTION, "settings_version", SETTINGS_VERSION)
	cfg.set_value(SECTION, "window_mode", window_mode)
	cfg.set_value(SECTION, "resolution_id", resolution_id)
	cfg.set_value(SECTION, "vsync", vsync)
	cfg.set_value(SECTION, "max_fps", max_fps)
	cfg.set_value(SECTION, "quality", quality)
	cfg.set_value(SECTION, "show_fps", show_fps)
	cfg.set_value(SECTION, "shadow_override", shadow_override)
	cfg.set_value(SECTION, "grass_override", grass_override)
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
	var preset: Dictionary = QUALITY_PRESETS.get(quality, QUALITY_PRESETS["balanced"]).duplicate()
	if SHADOW_OVERRIDES.has(shadow_override):
		preset["shadow_dist"] = float(SHADOW_OVERRIDES[shadow_override])
	if GRASS_OVERRIDES.has(grass_override):
		var g: Dictionary = GRASS_OVERRIDES[grass_override]
		for k in g:
			preset[k] = g[k]
	return preset


func renderer_label() -> String:
	## Prefer the project setting — runtime driver can fall back (e.g. CI/X11).
	var method: = String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	match method:
		"forward_plus":
			return "Vulkan Forward+"
		"mobile":
			return "Mobile renderer"
		"gl_compatibility":
			return "OpenGL Compatibility"
		_:
			return method


func apply() -> void:
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	## Cap when set; 0 = unlimited (GPU runs flat-out).
	Engine.max_fps = maxi(0, max_fps)

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


func set_shadow_override(id: String) -> void:
	if id not in ["preset", "low", "med", "high"]:
		return
	shadow_override = id
	apply()


func set_grass_override(id: String) -> void:
	if id not in ["preset", "low", "med", "high"]:
		return
	grass_override = id
	apply()


func cycle_max_fps() -> void:
	var opts: Array = MAX_FPS_OPTIONS
	var idx: = opts.find(max_fps)
	max_fps = int(opts[(idx + 1) % opts.size()]) if idx >= 0 else 144
	apply()


func cycle_quality() -> void:
	var keys: Array = ["performance", "balanced", "quality"]
	var idx: = keys.find(quality)
	quality = String(keys[(idx + 1) % keys.size()]) if idx >= 0 else "balanced"
	apply()


func max_fps_label() -> String:
	if max_fps <= 0:
		return "Unlimited"
	return "%d FPS" % max_fps


func quality_label() -> String:
	return String(quality_preset().get("label", quality.capitalize()))


func shadow_label() -> String:
	match shadow_override:
		"low":
			return "Low"
		"med":
			return "Medium"
		"high":
			return "High"
		_:
			return "Follow quality"


func grass_label() -> String:
	match grass_override:
		"low":
			return "Low"
		"med":
			return "Medium"
		"high":
			return "High"
		_:
			return "Follow quality"
