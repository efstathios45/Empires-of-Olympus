class_name GameCursor
## Visible in-game mouse cursor (Metin2-style). Call apply() when entering play.

const CURSOR_PATH := "res://assets/ui/cursor_pointer.png"
const HOTSPOT := Vector2(1, 1)


static func apply() -> void:
	if ResourceLoader.exists(CURSOR_PATH):
		var tex: Texture2D = load(CURSOR_PATH)
		if tex != null:
			## Also set drag / point / busy shapes so DnD keeps the bronze arrow.
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, HOTSPOT)
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_DRAG, HOTSPOT)
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_POINTING_HAND, HOTSPOT)
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_CAN_DROP, HOTSPOT)
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_FORBIDDEN, HOTSPOT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func show_system() -> void:
	## Menus can keep the custom arrow too — same apply.
	apply()
