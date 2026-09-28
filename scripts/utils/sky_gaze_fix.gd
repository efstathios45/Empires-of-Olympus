extends Node
## Child of Skeleton3D. Runs after AnimationPlayer (process_priority 100)
## and flattens the UAL retarget sky-gaze on UpperChest.

func _process(_delta: float) -> void:
	var skel := get_parent() as Skeleton3D
	if skel == null:
		return
	ModelUtils.correct_sky_gaze(skel, 1.0)
