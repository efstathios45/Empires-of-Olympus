extends SceneTree

func _init() -> void :
	call_deferred("_run")
func _run() -> void :
	var PanelInv = load("res://scripts/ui/panel_inventory.gd")
	var p = PanelInv.new()
	get_root().add_child(p)
	await process_frame
	await process_frame
	await process_frame

	for b in p.find_children("*", "Button", true, false):
		var n: StyleBox = b.get_theme_stylebox("normal")
		if n is StyleBoxTexture:
			var tex: Texture2D = (n as StyleBoxTexture).texture
			if tex != null and str(tex.resource_path).find("btn_secondary") >= 0:
				push_error("inventory still uses BACK plaque: " + b.text)
				quit(1)
				return
	print("SMOKE_INV_CTX_OK")
	quit(0)
