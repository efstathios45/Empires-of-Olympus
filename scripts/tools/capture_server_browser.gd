extends SceneTree
## Capture Multiplayer Worlds panel (name-only list) for walkthrough evidence.

func _init() -> void:
	call_deferred("run")


func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await process_frame

	var browser := get_root().get_node_or_null("ServerBrowser")
	assert(browser != null)
	browser.add_saved_server("Alex World", "203.0.113.50:7777")

	var Browser := load("res://scripts/ui/panel_server_browser.gd")
	assert(Browser != null)
	var panel: Control = Browser.new()
	get_root().add_child(panel)
	for _i in 10:
		await process_frame

	var img: Image = get_root().get_viewport().get_texture().get_image()
	assert(img != null)
	var path := "/opt/cursor/artifacts/server_browser_named_list.png"
	var err := img.save_png(path)
	assert(err == OK, "save failed %s" % err)

	var rows: Array = browser.list_rows()
	var found := false
	for row in rows:
		if String(row.get("name", "")) == "Alex World":
			found = true
			assert(not String(row.get("detail", "")).contains("203.0.113"))
	assert(found)

	print("CAPTURE_SERVER_BROWSER_OK %s" % path)
	quit(0)
