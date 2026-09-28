extends Node
## Tripo warrior mesh (hoplite/guard) melts under UAL.
## Always pin hips/torso/legs to rest. Outside combat, also pin shoulders/arms
## and drop upper-arms so idle/walk is a standing human, not T-pose or Z-legs.


const CORE_BONES := [
	"Hips", "Spine", "Chest", "UpperChest", "Neck", "Head",
	"LeftUpperLeg", "RightUpperLeg",
	"LeftLowerLeg", "RightLowerLeg",
	"LeftFoot", "RightFoot",
	"LeftToes", "RightToes",
]

const ARM_BONES := [
	"LeftShoulder", "RightShoulder",
	"LeftUpperArm", "RightUpperArm",
	"LeftLowerArm", "RightLowerArm",
	"LeftHand", "RightHand",
]

const ARM_DROP := 1.25  # ~72° local-X, opposite signs per side

var _anim: AnimationPlayer


func _ready() -> void:
	var model := get_parent()
	while model != null and model.find_child("AnimationPlayer", false, false) == null:
		model = model.get_parent()
	if model != null:
		_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _anim != null:
			_anim.process_priority = -100
	process_priority = 1000
	set_process(true)


func _process(_delta: float) -> void:
	var skel := get_parent() as Skeleton3D
	if skel == null:
		return
	for bone_name in CORE_BONES:
		_reset_bone(skel, bone_name)
	if _is_combat_clip():
		return
	for bone_name in ARM_BONES:
		_reset_bone(skel, bone_name)
	_drop_arm(skel, "LeftUpperArm", 1.0)
	_drop_arm(skel, "RightUpperArm", -1.0)


func _is_combat_clip() -> bool:
	if _anim == null or not _anim.is_playing():
		return false
	var clip := String(_anim.current_animation)
	for key in ["Attack", "Sword", "Block", "Hit", "Dodge", "Roll", "Jump", "Heavy", "Light"]:
		if key in clip:
			return true
	return false


func _reset_bone(skel: Skeleton3D, bone_name: String) -> void:
	var bone_i := skel.find_bone(bone_name)
	if bone_i < 0:
		return
	var rest: Transform3D = skel.get_bone_rest(bone_i)
	skel.set_bone_pose_rotation(bone_i, rest.basis.get_rotation_quaternion())
	skel.set_bone_pose_position(bone_i, rest.origin)
	skel.set_bone_pose_scale(bone_i, rest.basis.get_scale())


func _drop_arm(skel: Skeleton3D, bone_name: String, sign: float) -> void:
	var bone_i := skel.find_bone(bone_name)
	if bone_i < 0:
		return
	var rest_q: Quaternion = skel.get_bone_rest(bone_i).basis.get_rotation_quaternion()
	var drop := Quaternion(Vector3(1, 0, 0), sign * ARM_DROP)
	skel.set_bone_pose_rotation(bone_i, rest_q * drop)
