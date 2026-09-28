extends SkeletonModifier3D
## After KayKit AnimationPlayer updates, nudge hips so the lowest sole ≈ ground.


var _model: Node3D


func setup(model: Node3D) -> void:
	_model = model
	active = true


func _ready() -> void:
	active = true
	if _model == null:
		var n: Node = get_skeleton()
		while n != null:
			var p := n.get_parent()
			if p != null and (String(p.name) == "MeshRoot" or p is CharacterBody3D):
				_model = n as Node3D
				break
			n = p


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null or _model == null or not is_instance_valid(_model):
		return
	var parent := _model.get_parent() as Node3D
	if parent == null:
		return
	var ground_y: float = parent.global_position.y
	var min_y := INF
	for bone_name in ["foot.l", "foot.r", "toes.l", "toes.r"]:
		var bi := skel.find_bone(bone_name)
		if bi < 0:
			continue
		min_y = minf(min_y, (skel.global_transform * skel.get_bone_global_pose(bi)).origin.y)
	if min_y == INF:
		return
	var delta_y := ground_y - min_y
	if absf(delta_y) < 0.002:
		return
	var hips_i := skel.find_bone("hips")
	if hips_i < 0:
		return
	var parent_i := skel.get_bone_parent(hips_i)
	var parent_g: Transform3D = skel.global_transform
	if parent_i >= 0:
		parent_g = skel.global_transform * skel.get_bone_global_pose(parent_i)
	var local_up := parent_g.basis.inverse() * Vector3.UP
	var pos := skel.get_bone_pose_position(hips_i)
	pos += local_up * delta_y
	skel.set_bone_pose_position(hips_i, pos)
