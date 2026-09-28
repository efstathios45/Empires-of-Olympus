extends SceneTree
func _init() -> void:
	var scr = load("res://scripts/autoloads/account_system.gd")
	print("LOAD=", scr)
	if scr == null:
		push_error("failed load account_system")
		quit(1)
		return
	var node = scr.new()
	get_root().add_child(node)
	print("NODE=", node)
	# Also see autoloads
	for c in get_root().get_children():
		print("ROOT_CHILD=", c.name)
	var acc = get_root().get_node_or_null("AccountSystem")
	print("AUTOLOAD=", acc)
	quit(0)
