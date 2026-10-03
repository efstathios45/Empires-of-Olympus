extends SceneTree

func _init(): call_deferred("run")

func run():
	var path: = "res://assets/characters/quaternius_hero_king/hero_king.glb"
	var m: Node3D = load(path).instantiate()
	root.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D = m.find_child("Skeleton3D", true, false)
	var anim: AnimationPlayer = m.find_child("AnimationPlayer", true) as AnimationPlayer
	print("anims=", anim.get_animation_list())
	for clip in ["Idle_Neutral", "Idle", "Walk", "Sword_Slash"]:
		if not anim.has_animation(clip):
			print("missing ", clip)
			continue
		anim.play(clip)
		anim.seek(0.35, true)
		await process_frame
		await process_frame
		_report(skel, m, clip)

	for bname in ["Shoulder.R", "UpperArm.R", "LowerArm.R", "Wrist.R", "Hips"]:
		var bi: = skel.find_bone(bname)
		var pose: = skel.get_bone_pose(bi)
		var rest: = skel.get_bone_rest(bi)
		print("POSE ", bname, " scale=", pose.basis.get_scale(), " rest_scale=", rest.basis.get_scale(), 
			" pose_origin=", pose.origin, " rest_origin=", rest.origin)
	quit()

func _report(skel: Skeleton3D, model: Node3D, clip: String) -> void :
	var ua: = skel.find_bone("UpperArm.R")
	var la: = skel.find_bone("LowerArm.R")
	var wr: = skel.find_bone("Wrist.R")
	var sh: = skel.find_bone("Shoulder.R")
	var ua_xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(ua)
	var la_xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(la)
	var wr_xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(wr)
	var sh_xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(sh)
	print("--- ", clip)
	print("  Shoulder.R=", sh_xf.origin, " UpperArm.R=", ua_xf.origin)
	print("  LowerArm.R=", la_xf.origin, " Wrist.R=", wr_xf.origin)
	print("  UA->LA dist=", ua_xf.origin.distance_to(la_xf.origin), 
		" LA->WR=", la_xf.origin.distance_to(wr_xf.origin))

	var body: MeshInstance3D = null
	for n in model.find_children("*", "MeshInstance3D", true, false):
		if "Body" in String(n.name):
			body = n as MeshInstance3D
			break
	if body == null or body.mesh == null:
		print("  no body mesh")
		return
	var mid: = (ua_xf.origin + la_xf.origin) * 0.5
	var nearest: = 999.0
	var nearest_p: = Vector3.ZERO
	var near_count: = 0
	var st: = body.global_transform

	for s in body.mesh.get_surface_count():
		var arr = body.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for v in verts:
			var wp: Vector3 = st * v
			var d: float = wp.distance_to(mid)
			if d < nearest:
				nearest = d
				nearest_p = wp
			if d < 0.12:
				near_count += 1
	print("  mid_UA_LA=", mid, " nearest_body_vert_dist=", nearest, " at=", nearest_p, " near_count=", near_count)
