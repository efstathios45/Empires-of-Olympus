extends SceneTree
func _init(): call_deferred("run")
func run():
	var m: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	root.add_child(m)
	var ap: = m.find_child("AnimationPlayer", true) as AnimationPlayer
	var a: Animation = ap.get_animation("Idle_Neutral")
	for ti in a.get_track_count():
		print(a.track_get_path(ti))
	var skel: Skeleton3D = m.find_child("Skeleton3D", true, false)

	var ua = skel.get_bone_rest(skel.find_bone("UpperArm.R"))
	print("UpperArm.R rest rot=", ua.basis.get_euler())
	quit()
