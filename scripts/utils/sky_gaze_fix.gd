extends SkeletonModifier3D
## Runs in the Skeleton modification stack AFTER AnimationPlayer poses bones.
## Flattens UAL sky-tilt so hero/NPCs stand Metin2-upright.
## Also runs a late _process fallback in case the modifier stack is skipped.

func _ready() -> void:
	active = true
	process_priority = 1000
	set_process(true)
	var model: Node = get_parent()
	while model != null and model.find_child("AnimationPlayer", false, false) == null:
		model = model.get_parent()
	if model != null:
		var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim != null:
			anim.process_priority = -100


func _process_modification() -> void:
	_apply()


func _process(_delta: float) -> void:
	## Fallback if the modifier callback did not run this frame.
	_apply()


func _apply() -> void:
	var skel := get_skeleton()
	if skel == null:
		skel = get_parent() as Skeleton3D
	if skel == null:
		return
	ModelUtils.correct_sky_gaze(skel, 1.0)
