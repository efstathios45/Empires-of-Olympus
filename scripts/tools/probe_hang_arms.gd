extends SceneTree

func _init() -> void:
	call_deferred("run")


func run() -> void:
	var path := "res://assets/characters/greek_hoplite/greek_hoplite.glb"
	var m: Node3D = load(path).instantiate()
	root.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D = m.find_child("Skeleton3D", true, true) as Skeleton3D
	var hold := skel.find_child("HangArmHold", true, false) if skel else null
	print("HangArmHold=", hold != null, " poses=", hold.get("_poses").size() if hold else 0)
	var ap := m.find_child("AnimationPlayer", true) as AnimationPlayer
	for clip in ["Idle_Neutral", "Walk"]:
		if ap.has_animation(clip):
			print(clip, " tracks=", ap.get_animation(clip).get_track_count())
	if ap.has_animation("Walk"):
		ap.play("Walk")
		ap.advance(0.15)
		await process_frame
		var uarm := skel.find_bone("UpperArm.R")
		if uarm >= 0:
			print("Walk t=0.15 UpperArm.R rot=", skel.get_bone_pose_rotation(uarm))
	m.queue_free()
	print("PROBE_HANG_OK")
	quit()
