extends SceneTree
func _init() -> void :
	call_deferred("run")
func run() -> void :
	var m: Node3D = load("res://assets/characters/kaykit_knight/Knight.glb").instantiate()
	root.add_child(m)
	print("raw_scale=", m.scale, " name=", m.name)
	var min_y: = INF
	var max_y: = - INF
	for mi0 in m.find_children("*", "MeshInstance3D", true, false):
		var mi: = mi0 as MeshInstance3D
		var aabb: AABB = mi.get_aabb()
		for i in 8:
			var y: = mi.to_global(aabb.get_endpoint(i)).y
			min_y = minf(min_y, y)
			max_y = maxf(max_y, y)
	print("raw_height=", snapped(max_y - min_y, 0.01), " min_y=", snapped(min_y, 0.01), " max_y=", snapped(max_y, 0.01))
	ModelUtils.setup_character_for_movement(m, 1.85)
	print("after_scale=", m.scale)
	min_y = INF
	max_y = - INF
	for mi0 in m.find_children("*", "MeshInstance3D", true, false):
		var mi: = mi0 as MeshInstance3D
		var aabb: AABB = mi.get_aabb()
		for i in 8:
			var y: = mi.to_global(aabb.get_endpoint(i)).y
			min_y = minf(min_y, y)
			max_y = maxf(max_y, y)
	print("after_height=", snapped(max_y - min_y, 0.01), " min_y=", snapped(min_y, 0.01), " max_y=", snapped(max_y, 0.01))
	var skel: Skeleton3D = m.find_child("Skeleton3D", true, false)
	for bn in ["foot.l", "foot.r", "hips", "root", "hand.r"]:
		var bi: = skel.find_bone(bn)
		var p: Vector3 = (skel.global_transform * skel.get_bone_global_pose(bi)).origin
		print("bone ", bn, " y=", snapped(p.y, 0.01))
	var sw: Node3D = load("res://assets/props/kaykit/sword_1handed.glb").instantiate()
	root.add_child(sw)
	min_y = INF
	max_y = - INF
	var min_x: = INF
	var max_x: = - INF
	for mi0 in sw.find_children("*", "MeshInstance3D", true, false):
		var mi: = mi0 as MeshInstance3D
		print("sword_mesh=", mi.name, " mat=", mi.get_active_material(0))
		var aabb: AABB = mi.get_aabb()
		for i in 8:
			var g: Vector3 = mi.to_global(aabb.get_endpoint(i))
			min_y = minf(min_y, g.y)
			max_y = maxf(max_y, g.y)
			min_x = minf(min_x, g.x)
			max_x = maxf(max_x, g.x)
	print("sword_extent=", snapped(max_x - min_x, 0.01), "x", snapped(max_y - min_y, 0.01))
	quit(0)
