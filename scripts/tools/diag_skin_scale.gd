extends SceneTree
func _init() -> void :
	call_deferred("run")
func run() -> void :
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	print("BONES=", skel.get_bone_count())
	for mi_n in m.find_children("*", "MeshInstance3D", true, false):
		var mi: = mi_n as MeshInstance3D
		print("MI=", mi.name, " skin_binds=", mi.skin.get_bind_count() if mi.skin else 0)
		print("  skeleton=", mi.skeleton, " valid=", mi.get_node_or_null(mi.skeleton) != null)
	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	var a: = lib.get_animation("ual1_Idle")
	var scale_tracks: = 0
	var pos_tracks: = 0
	var rot_tracks: = 0
	for ti in a.get_track_count():
		var ty: = a.track_get_type(ti)
		if ty == Animation.TYPE_SCALE_3D:
			scale_tracks += 1
			var path: = str(a.track_get_path(ti))
			if ti < 5:
				print("SCALE_TRACK=", path, " k0=", a.scale_track_interpolate(ti, 0.0))
		elif ty == Animation.TYPE_POSITION_3D:
			pos_tracks += 1
		elif ty == Animation.TYPE_ROTATION_3D:
			rot_tracks += 1
	print("TRACKS rot=", rot_tracks, " pos=", pos_tracks, " scale=", scale_tracks)

	anim.play("ual1_Idle")
	for i in 20:
		await process_frame
	for name in ["Hips", "LeftUpperLeg", "RightUpperLeg", "LeftUpperArm", "Head", "Spine"]:
		var bi: = skel.find_bone(name)
		if bi < 0:
			continue
		var ps: = skel.get_bone_pose_scale(bi)
		var po: = skel.get_bone_pose_position(bi)
		print("POSE ", name, " scale=", ps, " pos=", po)
	quit(0)
