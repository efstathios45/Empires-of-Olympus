extends SceneTree
func _init():
	call_deferred("r")
func r():
	for p in ["res://scripts/autoloads/chat_system.gd","res://scripts/ui/chat_overlay.gd","res://scripts/ui/hud.gd"]:
		var s=load(p)
		print("LOAD ", p, " ", s!=null)
	print("OK")
	quit(0)
