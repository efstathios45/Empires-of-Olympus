extends SceneTree
## Measure Achilles mesh palm centroids in Wrist / LowerArm bone space.
func _init(): call_deferred("run")

func run():
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	hero.name = "greek_hoplite"
	root.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim := hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.strip_arm_animation_tracks(anim)
	anim.play("Idle_Neutral")
	for i in 16:
		await process_frame

	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	print("model.scale=", hero.scale)

	var mi: MeshInstance3D = null
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		mi = n as MeshInstance3D
		if mi and mi.mesh:
			break
	if mi == null:
		print("NO_MESH"); quit(); return

	# Gather skinned? Godot MeshInstance gives bind/rest verts via surface arrays —
	# with Skeleton3D skin, visual mesh is deformed. Use RenderingServer / AABB
	# sampling via raycast is hard; instead sample raw verts transformed by
	# skeleton skinning manually via bone weights if available.
	var mesh := mi.mesh
	var skin: Skin = mi.skin
	var has_skin := skin != null
	print("has_skin=", has_skin, " mesh=", mi.name)

	var verts_global: Array[Vector3] = []
	if has_skin and mi.skeleton != NodePath():
		var skel_node := mi.get_node(mi.skeleton) as Skeleton3D
		# Build inverse bind × current pose for each bone used by skin
		var bone_xfs: Array[Transform3D] = []
		bone_xfs.resize(skin.get_bind_count())
		for bi in skin.get_bind_count():
			var bone_name := skin.get_bind_name(bi)
			var bone_idx := skel_node.find_bone(bone_name)
			if bone_idx < 0:
				bone_idx = skin.get_bind_bone(bi)
			var rest_inv := skin.get_bind_pose(bi)
			var pose := skel_node.get_bone_global_pose(bone_idx) if bone_idx >= 0 else Transform3D.IDENTITY
			bone_xfs[bi] = skel_node.global_transform * pose * rest_inv

		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bones_a: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var weights_a: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			var bpp := 4
			if bones_a.is_empty() or weights_a.is_empty():
				for v in vs:
					verts_global.append(mi.global_transform * v)
				continue
			for vi in vs.size():
				var p := Vector3.ZERO
				var wsum := 0.0
				for k in bpp:
					var w := weights_a[vi * bpp + k]
					if w <= 0.0:
						continue
					var b := bones_a[vi * bpp + k]
					if b < 0 or b >= bone_xfs.size():
						continue
					p += bone_xfs[b] * vs[vi] * w
					wsum += w
				if wsum > 0.0:
					verts_global.append(p / wsum)
				else:
					verts_global.append(mi.global_transform * vs[vi])
	else:
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for v in vs:
				verts_global.append(mi.global_transform * v)

	print("skinned_vert_count=", verts_global.size())

	for bname in ["Wrist.R", "Wrist.L", "LowerArm.R", "LowerArm.L", "UpperArm.R", "UpperArm.L"]:
		var bi := skel.find_bone(bname)
		var g := skel.global_transform * skel.get_bone_global_pose(bi)
		print(bname, " origin=", g.origin, " X=", g.basis.x.normalized(), " Y=", g.basis.y.normalized(), " Z=", g.basis.z.normalized())

	# Right palm: outermost verts near wrist height, right side
	var wr_g := skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
	var wl_g := skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.L"))
	var lar_g := skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LowerArm.R"))
	var lal_g := skel.global_transform * skel.get_bone_global_pose(skel.find_bone("LowerArm.L"))

	var r_palm := _palm_centroid(verts_global, true, wr_g.origin.y)
	var l_palm := _palm_centroid(verts_global, false, wl_g.origin.y)
	print("R_palm_global=", r_palm)
	print("L_palm_global=", l_palm)

	var r_local := wr_g.affine_inverse() * r_palm
	var l_local_wrist := wl_g.affine_inverse() * l_palm
	var l_local_fore := lal_g.affine_inverse() * l_palm
	# Mid-forearm strap point: halfway from LowerArm.L origin toward left palm
	var strap_g := lal_g.origin.lerp(l_palm, 0.55)
	var strap_local := lal_g.affine_inverse() * strap_g
	print("R_palm_in_WristR=", r_local)
	print("L_palm_in_WristL=", l_local_wrist)
	print("L_palm_in_LowerArmL=", l_local_fore)
	print("strap_in_LowerArmL=", strap_local)
	print("delta_R_palm_minus_bone=", r_palm - wr_g.origin)
	print("delta_L_palm_minus_LowerArm=", l_palm - lal_g.origin)

	# Also mid-hand toward fingers (slightly further out)
	var r_outer := _outermost(verts_global, true)
	var l_outer := _outermost(verts_global, false)
	print("R_outer=", r_outer, " in_WristR=", wr_g.affine_inverse() * r_outer)
	print("L_outer=", l_outer, " in_LowerArmL=", lal_g.affine_inverse() * l_outer)
	print("PROBE_HANDS_OK")
	quit()


func _palm_centroid(verts: Array[Vector3], right: bool, wrist_y: float) -> Vector3:
	var acc := Vector3.ZERO
	var n := 0
	var y0 := wrist_y - 0.12
	var y1 := wrist_y + 0.18
	for g in verts:
		if g.y < y0 or g.y > y1:
			continue
		if right and g.x < 0.20:
			continue
		if (not right) and g.x > -0.20:
			continue
		# Prefer tip-ward verts (farther from midline)
		var ax := absf(g.x)
		if ax < 0.35:
			continue
		acc += g
		n += 1
	if n == 0:
		return Vector3.ZERO
	return acc / float(n)


func _outermost(verts: Array[Vector3], right: bool) -> Vector3:
	var best := Vector3.ZERO
	var best_ax := -1.0
	for g in verts:
		var ax := g.x if right else -g.x
		if ax > best_ax:
			best_ax = ax
			best = g
	return best
