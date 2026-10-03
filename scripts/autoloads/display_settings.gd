extends Node



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

var window_mode: String = "windowed"
var resolution_id: String = "1920x1080"
var vsync: bool = true


func _ready() -> void :
	load_settings()
	call_deferred("apply")


func load_settings() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	window_mode = String(cfg.get_value(SECTION, "window_mode", window_mode))
	resolution_id = String(cfg.get_value(SECTION, "resolution_id", resolution_id))
	vsync = bool(cfg.get_value(SECTION, "vsync", vsync))


func save_settings() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value(SECTION, "window_mode", window_mode)
	cfg.set_value(SECTION, "resolution_id", resolution_id)
	cfg.set_value(SECTION, "vsync", vsync)
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


func apply() -> void :
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
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
	save_settings()
	settings_changed.emit()


func set_window_mode(mode: String) -> void :
	if mode not in ["windowed", "fullscreen", "borderless"]:
		return
	window_mode = mode
	apply()


func set_resolution_id(id: String) -> void :
	resolution_id = id
	if window_mode == "windowed":
		apply()
	else:
		save_settings()
		settings_changed.emit()


func set_vsync(on: bool) -> void :
	vsync = on
	apply()
