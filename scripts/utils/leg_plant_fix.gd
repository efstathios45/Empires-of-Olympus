extends Node
## Tripo humanoids melt under UAL idle. After AnimationPlayer, pin core+arms to
## rest, then aim UpperArm bone-Y toward a slight world A-pose (down + out).
## Combat clips keep animated arms.


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

## UAL finger tracks spike Tripo hands when the rest of the arm is planted.
const FINGER_BONES := [
	"LeftThumbMetacarpal", "LeftThumbProximal", "LeftThumbDistal",
	"LeftIndexProximal", "LeftIndexIntermediate", "LeftIndexDistal",
	"LeftMiddleProximal", "LeftMiddleIntermediate", "LeftMiddleDistal",
	"LeftRingProximal", "LeftRingIntermediate", "LeftRingDistal",
	"LeftLittleProximal", "LeftLittleIntermediate", "LeftLittleDistal",
	"RightThumbMetacarpal", "RightThumbProximal", "RightThumbDistal",
	"RightIndexProximal", "RightIndexIntermediate", "RightIndexDistal",
	"RightMiddleProximal", "RightMiddleIntermediate", "RightMiddleDistal",
	"RightRingProximal", "RightRingIntermediate", "RightRingDistal",
	"RightLittleProximal", "RightLittleIntermediate", "RightLittleDistal",
]

## Outward bias so hands hang beside hips (not through the torso).
const APOSE_OUT := 0.22

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
	for bone_name in FINGER_BONES:
		_reset_bone(skel, bone_name)
	## Hang each arm down while keeping a bit of its rest (T-pose) outward.
	_aim_upper_arm_a_pose(skel, "LeftUpperArm", "LeftHand")
	_aim_upper_arm_a_pose(skel, "RightUpperArm", "RightHand")


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


## Aim UpperArm +Y toward down + a bit of the rest-pose outward (hand−shoulder).
## Uses rest globals so it stays correct at any character yaw.
func _aim_upper_arm_a_pose(skel: Skeleton3D, arm_bone: String, hand_bone: String) -> void:
	var bi := skel.find_bone(arm_bone)
	var hi := skel.find_bone(hand_bone)
	if bi < 0 or hi < 0:
		return
	var g: Transform3D = skel.global_transform * skel.get_bone_global_pose(bi)
	var along := g.basis.y.normalized()
	var shoulder: Vector3 = g.origin
	var hand: Vector3 = (skel.global_transform * skel.get_bone_global_pose(hi)).origin
	var out := hand - shoulder
	out.y = 0.0
	if out.length_squared() < 0.0001:
		out = Vector3.ZERO
	else:
		out = out.normalized()
	var target := (out * APOSE_OUT + Vector3.DOWN).normalized()
	if along.length_squared() < 0.0001:
		return
	if along.dot(target) > 0.999:
		return
	var q_delta := Quaternion(along, target)
	var parent_i := skel.get_bone_parent(bi)
	var parent_g: Transform3D
	if parent_i >= 0:
		parent_g = skel.global_transform * skel.get_bone_global_pose(parent_i)
	else:
		parent_g = skel.global_transform
	var new_basis: Basis = Basis(q_delta) * g.basis
	var local_basis: Basis = parent_g.basis.inverse() * new_basis
	skel.set_bone_pose_rotation(bi, local_basis.get_rotation_quaternion())
