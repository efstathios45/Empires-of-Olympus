extends Node






const LEG_BONES: = [
	"Hips", 
	"LeftUpperLeg", "RightUpperLeg", 
	"LeftLowerLeg", "RightLowerLeg", 
	"LeftFoot", "RightFoot", 
	"LeftToes", "RightToes", 
]

const TORSO_BONES: = [
	"Spine", "Chest", "UpperChest", "Neck", "Head", 
]

const ARM_BONES: = [
	"LeftShoulder", "RightShoulder", 
	"LeftUpperArm", "RightUpperArm", 
	"LeftLowerArm", "RightLowerArm", 
	"LeftHand", "RightHand", 
]

const FINGER_BONES: = [
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

const APOSE_OUT: = 0.18
const SWAY_HZ: = 0.28
const SWAY_ARM: = 0.03
const SWAY_SPINE: = 0.022

const WALK_HZ: = 1.15
const WALK_LEG: = 0.72
const WALK_KNEE: = 0.62
const WALK_ARM: = 0.42
const SPRINT_HZ: = 1.65
const SPRINT_LEG: = 0.88

var _anim: AnimationPlayer
var _t: float = 0.0
var _rest_foot_y: float = NAN


func _ready() -> void :
	process_priority = 1000
	set_process(true)
	_resolve_anim()
	call_deferred("_cache_rest_foot_y")


func _cache_rest_foot_y() -> void :
	var skel: = get_parent() as Skeleton3D
	if skel == null:
		return

	for bone_name in LEG_BONES:
		_reset_bone(skel, bone_name)
	_rest_foot_y = _lowest_foot_y(skel)



func bind_anim(anim: AnimationPlayer) -> void :
	if anim == null or not is_instance_valid(anim):
		return
	_anim = anim
	_anim.process_priority = -100


func _resolve_anim() -> void :
	if _anim != null and is_instance_valid(_anim):
		return
	var skel: = get_parent()
	if skel == null:
		return



	var root: = _character_root(skel)
	var found: = _find_anim_player(root)
	if found != null:
		bind_anim(found)


func _character_root(from: Node) -> Node:
	var n: Node = from
	while n != null:
		if n is CharacterBody3D or n is StaticBody3D:
			return n
		if String(n.name) == "MeshRoot":
			return n
		var p: = n.get_parent()
		if p == null:
			return n

		var pname: = String(p.name)
		var tree: = get_tree()
		if pname == "GameWorld" or pname == "root" or (tree != null and p == tree.root):
			return n
		n = p
	return from


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n == null:
		return null
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		if c is AnimationPlayer:
			return c as AnimationPlayer

		if c is CharacterBody3D or c is StaticBody3D:
			continue
		var nested: = _find_anim_player(c)
		if nested != null:
			return nested
	return null


func _process(delta: float) -> void :
	var skel: = get_parent() as Skeleton3D
	if skel == null:
		return
	_t += delta
	_resolve_anim()
	var mode: = _clip_mode()


	_plant_human_base(skel)
	_level_head(skel)
	if mode == "locomotion":
		var sprint: = _is_sprint()
		_procedural_walk(skel, sprint)

	elif mode == "combat":
		_procedural_combat(skel)
	else:
		_idle_sway(skel)


func _clip_mode() -> String:
	if _anim == null or not _anim.is_playing():
		return "idle"
	var clip: = String(_anim.current_animation)
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
	var clip: = String(_anim.current_animation)
	return "Sprint" in clip or "Run" in clip


func _plant_human_base(skel: Skeleton3D) -> void :
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


func _reset_bone(skel: Skeleton3D, bone_name: String) -> void :
	var bone_i: = skel.find_bone(bone_name)
	if bone_i < 0:
		return
	var rest: Transform3D = skel.get_bone_rest(bone_i)
	skel.set_bone_pose_rotation(bone_i, rest.basis.get_rotation_quaternion())
	skel.set_bone_pose_position(bone_i, rest.origin)
	skel.set_bone_pose_scale(bone_i, rest.basis.get_scale())


func _aim_upper_arm_a_pose(skel: Skeleton3D, arm_bone: String, hand_bone: String) -> void :
	var bi: = skel.find_bone(arm_bone)
	var hi: = skel.find_bone(hand_bone)
	if bi < 0 or hi < 0:
		return
	var g: Transform3D = skel.global_transform * skel.get_bone_global_pose(bi)
	var along: = g.basis.y.normalized()
	var shoulder: Vector3 = g.origin
	var hand: Vector3 = (skel.global_transform * skel.get_bone_global_pose(hi)).origin
	var out: = hand - shoulder
	out.y = 0.0
	if out.length_squared() < 0.0001:
		out = Vector3.ZERO
	else:
		out = out.normalized()
	var target: = (out * APOSE_OUT + Vector3.DOWN).normalized()
	if along.length_squared() < 0.0001 or along.dot(target) > 0.999:
		return
	var q_delta: = Quaternion(along, target)
	var parent_i: = skel.get_bone_parent(bi)
	var parent_g: Transform3D = skel.global_transform
	if parent_i >= 0:
		parent_g = skel.global_transform * skel.get_bone_global_pose(parent_i)
	var new_basis: Basis = Basis(q_delta) * g.basis
	var local_basis: Basis = parent_g.basis.inverse() * new_basis
	skel.set_bone_pose_rotation(bi, local_basis.get_rotation_quaternion())



func _level_head(skel: Skeleton3D) -> void :
	_add_local_rot(skel, "Neck", Vector3(1, 0, 0), -0.12)
	_add_local_rot(skel, "Head", Vector3(1, 0, 0), -0.2)




func _procedural_walk(skel: Skeleton3D, sprint: bool) -> void :
	var hz: = SPRINT_HZ if sprint else WALK_HZ
	var leg_amp: = SPRINT_LEG if sprint else WALK_LEG
	var phase: = _t * TAU * hz
	var leg_axis: = Vector3(0, 0, -1)
	_add_local_rot(skel, "LeftUpperLeg", leg_axis, sin(phase) * leg_amp)
	_add_local_rot(skel, "RightUpperLeg", leg_axis, sin(phase + PI) * leg_amp)

	var lk: = maxf(0.0, - sin(phase)) * WALK_KNEE
	var rk: = maxf(0.0, - sin(phase + PI)) * WALK_KNEE
	_add_local_rot(skel, "LeftLowerLeg", leg_axis, lk)
	_add_local_rot(skel, "RightLowerLeg", leg_axis, rk)

	var arm_amp: = WALK_ARM * (1.15 if sprint else 1.0)
	_add_local_rot(skel, "LeftUpperArm", Vector3(1, 0, 0), sin(phase + PI) * arm_amp)
	_add_local_rot(skel, "RightUpperArm", Vector3(1, 0, 0), sin(phase) * arm_amp)

	_add_local_rot(skel, "Hips", Vector3(0, 1, 0), sin(phase * 2.0) * 0.04)
	_add_local_rot(skel, "Spine", Vector3(1, 0, 0), 0.06 + absf(sin(phase)) * 0.03)


func _add_local_rot(skel: Skeleton3D, bone_name: String, axis: Vector3, angle: float) -> void :
	var bi: = skel.find_bone(bone_name)
	if bi < 0 or absf(angle) < 0.0001:
		return
	var q: Quaternion = skel.get_bone_pose_rotation(bi)
	skel.set_bone_pose_rotation(bi, q * Quaternion(axis.normalized(), angle))


func _lowest_foot_y(skel: Skeleton3D) -> float:
	var min_y: = 999.0
	for bone_name in ["LeftFoot", "RightFoot", "LeftToes", "RightToes"]:
		var bi: = skel.find_bone(bone_name)
		if bi < 0:
			continue
		var y: float = (skel.global_transform * skel.get_bone_global_pose(bi)).origin.y
		min_y = minf(min_y, y)
	return min_y


func _stabilize_foot_height(skel: Skeleton3D) -> void :
	if is_nan(_rest_foot_y):
		return
	var now: = _lowest_foot_y(skel)
	var delta_y: = _rest_foot_y - now
	if absf(delta_y) < 0.004:
		return
	var hips_i: = skel.find_bone("Hips")
	if hips_i < 0:
		return
	var parent_i: = skel.get_bone_parent(hips_i)
	var parent_g: Transform3D = skel.global_transform
	if parent_i >= 0:
		parent_g = skel.global_transform * skel.get_bone_global_pose(parent_i)
	var local_up: = parent_g.basis.inverse() * Vector3.UP
	var pos: = skel.get_bone_pose_position(hips_i)
	pos += local_up * delta_y
	skel.set_bone_pose_position(hips_i, pos)


func _idle_sway(skel: Skeleton3D) -> void :
	var phase: = _t * TAU * SWAY_HZ
	_add_local_rot(skel, "Spine", Vector3(0, 0, 1), sin(phase) * SWAY_SPINE)
	_add_local_rot(skel, "Chest", Vector3(1, 0, 0), sin(phase * 2.0) * SWAY_SPINE * 0.6)
	_add_local_rot(skel, "LeftUpperArm", Vector3(0, 0, 1), sin(phase) * SWAY_ARM)
	_add_local_rot(skel, "RightUpperArm", Vector3(0, 0, 1), - sin(phase + 0.4) * SWAY_ARM)



func _procedural_combat(skel: Skeleton3D) -> void :
	var clip: = String(_anim.current_animation) if _anim else ""
	var u: = _clip_progress()

	var env: = sin(clampf(u, 0.0, 1.0) * PI)
	if "Block" in clip:
		_add_local_rot(skel, "LeftUpperArm", Vector3(1, 0, 0), -0.95)
		_add_local_rot(skel, "LeftLowerArm", Vector3(1, 0, 0), -1.1)
		_add_local_rot(skel, "RightUpperArm", Vector3(1, 0, 0), -0.35)
		_add_local_rot(skel, "Spine", Vector3(1, 0, 0), 0.08)
		return
	if "Jump" in clip or "Roll" in clip or "Dodge" in clip:
		_add_local_rot(skel, "LeftUpperLeg", Vector3(0, 0, -1), 0.25 * env)
		_add_local_rot(skel, "RightUpperLeg", Vector3(0, 0, -1), 0.25 * env)
		_add_local_rot(skel, "LeftLowerLeg", Vector3(0, 0, -1), 0.35 * env)
		_add_local_rot(skel, "RightLowerLeg", Vector3(0, 0, -1), 0.35 * env)
		_add_local_rot(skel, "LeftUpperArm", Vector3(1, 0, 0), -0.4 * env)
		_add_local_rot(skel, "RightUpperArm", Vector3(1, 0, 0), -0.4 * env)
		return

	var heavy: = "Heavy" in clip
	var wind: = sin(clampf(u * 2.4, 0.0, 1.0) * PI)
	var chop: = sin(clampf((u - 0.12) * 1.7, 0.0, 1.0) * PI)
	var twist: = (0.5 if heavy else 0.36) * chop
	var lift: = (1.7 if heavy else 1.45) * wind

	_add_local_rot(skel, "RightUpperArm", Vector3(1, 0, 0), - lift)
	_add_local_rot(skel, "RightUpperArm", Vector3(1, 0, 0), 1.8 * chop)
	_add_local_rot(skel, "RightLowerArm", Vector3(1, 0, 0), -0.85 * wind - 1.35 * chop)
	_add_local_rot(skel, "RightHand", Vector3(1, 0, 0), -0.55 * chop)
	_add_local_rot(skel, "RightUpperArm", Vector3(0, 0, 1), 0.18 * env)

	_add_local_rot(skel, "LeftUpperArm", Vector3(1, 0, 0), -0.7 * env)
	_add_local_rot(skel, "LeftLowerArm", Vector3(1, 0, 0), -0.95 * env)
	_add_local_rot(skel, "Spine", Vector3(0, 1, 0), twist)
	_add_local_rot(skel, "Chest", Vector3(0, 1, 0), twist * 0.55)
	_add_local_rot(skel, "Hips", Vector3(0, 1, 0), - twist * 0.3)
	_add_local_rot(skel, "RightUpperLeg", Vector3(0, 0, -1), 0.28 * chop)
	_add_local_rot(skel, "LeftUpperLeg", Vector3(0, 0, -1), -0.14 * chop)


func _clip_progress() -> float:
	if _anim == null or not _anim.is_playing():
		return 0.0
	var length: = _anim.current_animation_length
	if length <= 0.001:
		return 0.0
	return clampf(_anim.current_animation_position / length, 0.0, 1.0)
