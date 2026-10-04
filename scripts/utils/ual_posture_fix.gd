extends Node

## Shared UAL/Mixamo posture corrector.
## The ual1_* clips lean Chest/UpperChest/Neck/Head backward so characters
## stare at the sky once retargeted onto a real Skeleton3D. This runs AFTER
## the AnimationPlayer (higher process_priority) and blends those pitches
## back toward rest so humanoids look forward. Also lightly damps extreme
## shoulder roll that reads as "entangled" arms on some UAL packs.

const DAMPEN_PITCH: Dictionary = {
	"Spine": 0.55,
	"Chest": 0.85,
	"UpperChest": 0.9,
	"Neck": 0.8,
	"Head": 0.75,
}

# No arm/shoulder dampen — that glued hands and read as "entangled".
# Pitch-only correction is enough to stop the UAL sky-stare.
const DAMPEN_ARM: Dictionary = {}

var _anim: AnimationPlayer


func _ready() -> void:
	process_priority = 1200
	set_process(true)


func bind_anim(a: AnimationPlayer) -> void:
	_anim = a
	if a != null and is_instance_valid(a):
		# Animation must pose bones before we correct them.
		a.process_priority = -200


func _process(_delta: float) -> void:
	var skel := get_parent() as Skeleton3D
	if skel == null:
		return
	for bone_name in DAMPEN_PITCH:
		_dampen_pitch(skel, String(bone_name), float(DAMPEN_PITCH[bone_name]))
	for bone_name in DAMPEN_ARM:
		_dampen_roll(skel, String(bone_name), float(DAMPEN_ARM[bone_name]))
	# Keep the head from tipping past horizontal (sky stare).
	_clamp_head_look(skel)


func _dampen_pitch(skel: Skeleton3D, bone_name: String, strength: float) -> void:
	var bi := skel.find_bone(bone_name)
	if bi < 0:
		return
	var rest_x := skel.get_bone_rest(bi).basis.get_euler().x
	var e := skel.get_bone_pose_rotation(bi).get_euler()
	e.x = lerpf(e.x, rest_x, clampf(strength, 0.0, 1.0))
	skel.set_bone_pose_rotation(bi, Quaternion.from_euler(e))


func _dampen_roll(skel: Skeleton3D, bone_name: String, strength: float) -> void:
	var bi := skel.find_bone(bone_name)
	if bi < 0:
		return
	var rest_e := skel.get_bone_rest(bi).basis.get_euler()
	var e := skel.get_bone_pose_rotation(bi).get_euler()
	e.z = lerpf(e.z, rest_e.z, clampf(strength, 0.0, 1.0))
	skel.set_bone_pose_rotation(bi, Quaternion.from_euler(e))


func _clamp_head_look(skel: Skeleton3D) -> void:
	var hi := skel.find_bone("Head")
	if hi < 0:
		return
	skel.force_update_all_bone_transforms()
	var xf := skel.global_transform * skel.get_bone_global_pose(hi)
	var look := -xf.basis.z
	# If looking steeply upward, nod the head local pitch toward rest.
	if look.y > 0.2:
		var rest_x := skel.get_bone_rest(hi).basis.get_euler().x
		var e := skel.get_bone_pose_rotation(hi).get_euler()
		var t := clampf((look.y - 0.2) / 0.6, 0.0, 1.0)
		e.x = lerpf(e.x, rest_x, t)
		skel.set_bone_pose_rotation(hi, Quaternion.from_euler(e))
