extends SceneTree
func _init(): call_deferred("run")
func run():
	var m: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	root.add_child(m)
	_dump(m, 0)
	quit()
func _dump(n: Node, depth: int) -> void :
	var pad = "  ".repeat(depth)
	var extra = ""
	if n is MeshInstance3D:
		var mi: = n as MeshInstance3D
		extra = " MESH surfaces=%d vis=%s" % [mi.mesh.get_surface_count() if mi.mesh else 0, mi.visible]
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var mat = mi.mesh.surface_get_material(s)
				extra += "\n%s    surf%d mat=%s" % [pad, s, mat.resource_name if mat else "?"]
	print(pad, n.name, " [", n.get_class(), "]", extra)
	for c in n.get_children():
		_dump(c, depth + 1)
