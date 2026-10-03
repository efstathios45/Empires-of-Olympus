extends SceneTree

func _init() -> void :
	call_deferred("run")
func run() -> void :
	var dir: = DirAccess.open("res://assets/props/kaykit")
	if dir == null:
		push_error("no kaykit props")
		quit(1)
		return
	dir.list_dir_begin()
	var name: = dir.get_next()
	var n: = 0
	while name != "":
		if name.ends_with(".gltf"):
			var path: = "res://assets/props/kaykit/" + name
			var scn = load(path)
			if scn is PackedScene:
				var out: = path.get_basename() + ".glb"
				var state: = GLTFDocument.new()
				var gstate: = GLTFState.new()
				var root: Node = scn.instantiate()
				var err: = state.append_from_scene(root, gstate)
				if err == OK:
					err = state.write_to_filesystem(gstate, out)
					print("PACK ", out, " err=", err)
					n += 1
				root.queue_free()
			else:
				print("SKIP not scene ", path, " ", scn)
		name = dir.get_next()
	print("PACKED ", n)
	quit(0)
