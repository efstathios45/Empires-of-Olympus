extends SceneTree
func _init(): call_deferred("run")
func run():
	var m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	root.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim = AnimationPlayer.new()
	m.add_child(anim)
	var skel
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var fix = skel.get_node("LegPlantFix")
	print("skel=", skel.get_path(), " parent=", skel.get_parent().get_path())
	print("m children=", m.get_children().map( func(c): return c.name))
	var n = fix.get_parent()
	var i = 0
	while n and i < 8:
		var found = n.find_child("AnimationPlayer", true, false)
		print("level ", i, " node=", n.name, " class=", n.get_class(), " findAP=", found)
		n = n.get_parent()
		i += 1

	fix.call("_resolve_anim")
	print("after resolve _anim=", fix.get("_anim"))
	quit(0)
