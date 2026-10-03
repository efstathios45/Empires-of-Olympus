extends SceneTree
func _init() -> void :
	call_deferred("run")
func run() -> void :
	var Browser = load("res://scripts/ui/panel_server_browser.gd")
	assert (Browser != null)
	var panel: Control = Browser.new()
	get_root().add_child(panel)
	await process_frame
	await process_frame
	assert (panel.get_child_count() > 0)
	print("SMOKE_BROWSER_UI_OK")
	quit(0)
