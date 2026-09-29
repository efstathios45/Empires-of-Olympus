extends SkeletonModifier3D
## Keep Achilles hang-rest arm poses while leg/spine clips play (arm tracks stripped).

var _poses: Dictionary = {}


func setup_poses(poses: Dictionary) -> void:
	_poses = poses
	active = true


func _process_modification() -> void:
	var skel := get_skeleton()
	if skel == null or _poses.is_empty():
		return
	for bi in _poses.keys():
		var p: Dictionary = _poses[bi]
		skel.set_bone_pose_position(int(bi), p.get("pos", Vector3.ZERO))
		skel.set_bone_pose_rotation(int(bi), p.get("rot", Quaternion.IDENTITY))
		skel.set_bone_pose_scale(int(bi), p.get("scale", Vector3.ONE))
