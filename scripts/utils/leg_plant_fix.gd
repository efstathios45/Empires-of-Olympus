extends Node
## Tripo+UAL melts the bind. Strategy:
##   Idle  — plant rest + A-pose + horizon head + sway (NPCs look alive).
##   Walk  — same plant base, then a procedural step cycle (UAL Walk melts).
##   Combat — let the clip play; only level the head.


const LEG_BONES := [
	"Hips",
	"LeftUpperLeg", "RightUpperLeg",
	"LeftLowerLeg", "RightLowerLeg",
	"LeftFoot", "RightFoot",
	"LeftToes", "RightToes",
]

const TORSO_BONES := [
	"Spine", "Chest", "UpperChest", "Neck", "Head",
]

const ARM_BONES := [
	"LeftShoulder", "RightShoulder",
	"LeftUpperArm", "RightUpperArm",
	"LeftLowerArm", "RightLowerArm",
	"LeftHand", "RightHand",
]

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

const APOSE_OUT := 0.22
const SWAY_HZ := 0.35
const SWAY_ARM := 0.04
const SWAY_SPINE := 0.028
const WALK_HZ := 1.35
const WALK_LEG := 0.55
const WALK_KNEE := 0.45
const WALK_ARM := 0.35
const SPRINT_HZ := 1.85
const SPRINT_LEG := 0.7

var _anim: AnimationPlayer
var _t: float = 0.0
var _rest_foot_y: float = NAN


func _ready() -> void:
	process_priority = 1000
	set_process(true)
	_resolve_anim()
	call_deferred("_cache_rest_foot_y")


func _cache_rest_foot_y() -> void:
	var skel := get_parent() as Skeleton3D
	if skel == null:
		return
	## Measure planted rest foot height (before any sway/walk).
	for bone_name in LEG_BONES:
		_reset_bone(skel, bone_name)
	_rest_foot_y = _lowest_foot_y(skel)


func _resolve_anim() -> void:
	if _anim != null and is_instance_valid(_anim):
		return
	var n: Node = get_parent()
	while n != null:
		var found := _find_anim_player(n)
		if found != null:
			_anim = found
			_anim.process_priority = -100
			return
		n = n.get_parent()


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		if c is AnimationPlayer:
			return c as AnimationPlayer
		var nested := _find_anim_player(c)
		if nested != null:
			return nested
	return null


func _process(delta: float) -> void:
	var skel := get_parent() as Skeleton3D
	if skel == null:
		return
	_t += delta
	_resolve_anim()
	var mode := _clip_mode()

	if mode == "combat":
		_level_head(skel)
		return

	## Idle and locomotion share a planted human base (UAL clips melt Tripo).
	_plant_human_base(skel)
	_level_head(skel)
	if mode == "locomotion":
		var sprint := _is_sprint()
		_procedural_walk(skel, sprint)
		_stabilize_foot_height(skel)
	else:
		_idle_sway(skel)


func _clip_mode() -> String:
	if _anim == null or not _anim.is_playing():
		return "idle"
	var clip := String(_anim.current_animation)
	for key in ["Walk", "Sprint", "Run"]:
		if key in clip:
			return "locomotion"
	for key in ["Jump", "Roll", "Dodge", "Attack", "Sword", "Block", "Hit", "Heavy", "Light", "Punch", "Death"]:
		if key in clip:
			return "combat"
	return "idle"


func _is_sprint() -> bool:
	if _anim == null:
		return false
	var clip := String(_anim.current_animation)
	return "Sprint" in clip or "Run" in clip


func _plant_human_base(skel: Skeleton3D) -> void:
	for bone_name in LEG_BONES:
		_reset_bone(skel, bone_name)
	for bone_name in TORSO_BONES:
		_reset_bone(skel, bone_name)
	for bone_name in ARM_BONES:
		_reset_bone(skel, bone_name)
	for bone_name in FINGER_BONES:
		_reset_bone(skel, bone_name)
	_aim_upper_arm_a_pose(skel, "LeftUpperArm", "LeftHand")
	_aim_upper_arm_a_pose(skel, "RightUpperArm", "RightHand")


func _reset_bone(skel: Skeleton3D, bone_name: String) -> void:
	var bone_i := skel.find_bone(bone_name)
	if bone_i < 0:
		return
	var rest: Transform3D = skel.get_bone_rest(bone_i)
	skel.set_bone_pose_rotation(bone_i, rest.basis.get_rotation_quaternion())
	skel.set_bone_pose_position(bone_i, rest.origin)
	skel.set_bone_pose_scale(bone_i, rest.basis.get_scale())


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
	if along.length_squared() < 0.0001 or along.dot(target) > 0.999:
		return
	var q_delta := Quaternion(along, target)
	var parent_i := skel.get_bone_parent(bi)
	var parent_g: Transform3D = skel.global_transform
	if parent_i >= 0:
		parent_g = skel.global_transform * skel.get_bone_global_pose(parent_i)
	var new_basis: Basis = Basis(q_delta) * g.basis
	var local_basis: Basis = parent_g.basis.inverse() * new_basis
	skel.set_bone_pose_rotation(bi, local_basis.get_rotation_quaternion())


## Tripo rest stares upward; local +X negative pitch aims near the horizon.
func _level_head(skel: Skeleton3D) -> void:
	_add_local_rot(skel, "Neck", Vector3(1, 0, 0), -0.12)
	_add_local_rot(skel, "Head", Vector3(1, 0, 0), -0.20)


## Simple in-place walk/sprint on the planted human base.
## Tripo UpperLeg forward swing is local −Z (not X).
func _procedural_walk(skel: Skeleton3D, sprint: bool) -> void:
	var hz := SPRINT_HZ if sprint else WALK_HZ
	var leg_amp := SPRINT_LEG if sprint else WALK_LEG
	var phase := _t * TAU * hz
	var leg_axis := Vector3(0, 0, -1)
	_add_local_rot(skel, "LeftUpperLeg", leg_axis, sin(phase) * leg_amp)
	_add_local_rot(skel, "RightUpperLeg", leg_axis, sin(phase + PI) * leg_amp)
	## Knees bend on the trailing half (same local −Z family).
	var lk := maxf(0.0, -sin(phase)) * WALK_KNEE
	var rk := maxf(0.0, -sin(phase + PI)) * WALK_KNEE
	_add_local_rot(skel, "LeftLowerLeg", leg_axis, lk)
	_add_local_rot(skel, "RightLowerLeg", leg_axis, rk)
	## Opposite arm swing from the planted A-pose (UpperArm forward ≈ local X).
	var arm_amp := WALK_ARM * (1.15 if sprint else 1.0)
	_add_local_rot(skel, "LeftUpperArm", Vector3(1, 0, 0), sin(phase + PI) * arm_amp)
	_add_local_rot(skel, "RightUpperArm", Vector3(1, 0, 0), sin(phase) * arm_amp)
	## Slight hip yaw bob + forward lean.
	_add_local_rot(skel, "Hips", Vector3(0, 1, 0), sin(phase * 2.0) * 0.04)
	_add_local_rot(skel, "Spine", Vector3(1, 0, 0), 0.06 + absf(sin(phase)) * 0.03)


func _add_local_rot(skel: Skeleton3D, bone_name: String, axis: Vector3, angle: float) -> void:
	var bi := skel.find_bone(bone_name)
	if bi < 0 or absf(angle) < 0.0001:
		return
	var q: Quaternion = skel.get_bone_pose_rotation(bi)
	skel.set_bone_pose_rotation(bi, q * Quaternion(axis.normalized(), angle))


func _lowest_foot_y(skel: Skeleton3D) -> float:
	var min_y := 999.0
	for bone_name in ["LeftFoot", "RightFoot", "LeftToes", "RightToes"]:
		var bi := skel.find_bone(bone_name)
		if bi < 0:
			continue
		var y: float = (skel.global_transform * skel.get_bone_global_pose(bi)).origin.y
		min_y = minf(min_y, y)
	return min_y


func _stabilize_foot_height(skel: Skeleton3D) -> void:
	if is_nan(_rest_foot_y):
		return
	var now := _lowest_foot_y(skel)
	var delta_y := _rest_foot_y - now
	if absf(delta_y) < 0.004:
		return
	var hips_i := skel.find_bone("Hips")
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


func _idle_sway(skel: Skeleton3D) -> void:
	var phase := _t * TAU * SWAY_HZ
	_add_local_rot(skel, "Spine", Vector3(0, 0, 1), sin(phase) * SWAY_SPINE)
	_add_local_rot(skel, "Chest", Vector3(1, 0, 0), sin(phase * 2.0) * SWAY_SPINE * 0.6)
	_add_local_rot(skel, "LeftUpperArm", Vector3(0, 0, 1), sin(phase) * SWAY_ARM)
	_add_local_rot(skel, "RightUpperArm", Vector3(0, 0, 1), -sin(phase + 0.4) * SWAY_ARM)
