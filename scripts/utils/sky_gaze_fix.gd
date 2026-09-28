extends Node
## Child of Skeleton3D. Runs after AnimationPlayer and flattens UAL sky-tilt.

func _ready() -> void:
	## AnimationPlayer must pose bones before we correct them.
	var model := get_parent()
	while model != null and model.find_child("AnimationPlayer", false, false) == null:
		model = model.get_parent()
	if model != null:
		var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim != null:
			anim.process_priority = -100
	process_priority = 1000
	set_process(true)


func _process(_delta: float) -> void:
	var skel := get_parent() as Skeleton3D
	if skel == null:
		return
	ModelUtils.correct_sky_gaze(skel, 1.0)
