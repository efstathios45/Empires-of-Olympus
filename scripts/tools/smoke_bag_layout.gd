extends SceneTree
func _init():
	call_deferred("_r")
func _r():
	var gs = get_root().get_node("GameState")
	gs.call("reset_run")
	for e in gs.get("bag"):
		print("BAG ", e.get("id"), " at ", e.get("x"), ",", e.get("y"), " count=", e.get("count"))
		print("  icon=", gs.call("item_icon_path", str(e.get("id"))))
	quit(0)
