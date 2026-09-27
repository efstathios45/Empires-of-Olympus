class_name GameCursor
## Visible in-game mouse cursor (Metin2-style). Call apply() when entering play.

const CURSOR_PATH := "res://assets/ui/cursor_pointer.png"
const HOTSPOT := Vector2(2, 2)


static func apply() -> void:
	if ResourceLoader.exists(CURSOR_PATH):
		var tex: Texture2D = load(CURSOR_PATH)
		if tex != null:
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, HOTSPOT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func show_system() -> void:
	## Menus can keep the custom arrow too — same apply.
	apply()
