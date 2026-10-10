extends SceneTree
## Open Video Settings from the main menu and capture it.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	for _i in 90:
		await process_frame

	var menu = get_first_node_in_group("main_menu")
	if menu == null:
		## Fallback: find MainMenu script.
		for n in root.find_children("*", "Control", true, false):
			var scr = n.get_script()
			if scr and String(scr.resource_path).ends_with("main_menu.gd"):
				menu = n
				break
	if menu == null:
		print("FAIL no main menu")
		quit(1)
		return

	if menu.has_method("_open_settings"):
		menu._open_settings()
	else:
		print("FAIL no _open_settings")
		quit(1)
		return
	for _j in 40:
		await process_frame

	var path: = "/opt/cursor/artifacts/video_settings_panel.png"
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SHOT settings -> ", path)
	print("CAPTURE_VIDEO_SETTINGS_OK")
	quit(0)
