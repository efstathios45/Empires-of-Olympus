extends Node

# The shared ual1_* animation clips used by the plaza townsfolk lean the chest
# and neck backward, which cumulatively tips the head up toward the sky. This
# runs after the AnimationPlayer has posed the skeleton each frame (the player
# is forced to a lower process priority) and blends the pitch of the
# upper-torso / neck / head bones back toward their rest pose, so the NPCs
# stand and look naturally forward. Bones the rig does not expose are skipped.

const DAMPEN: = {
	"Chest": 0.8, 
	"UpperChest": 0.85, 
	"Neck": 0.7, 
	"Head": 0.6, 
}

var _anim: AnimationPlayer
var _logged: bool = false


func _ready() -> void :
	process_priority = 1200
	set_process(true)


func bind_anim(a: AnimationPlayer) -> void :
	_anim = a
	if a != null and is_instance_valid(a):
		a.process_priority = -200


func _process(_delta: float) -> void :
	var skel: = get_parent() as Skeleton3D
	if skel == null:
		return
	if not _logged:
		_logged = true
		var f: = FileAccess.open("/tmp/cap_steps.log", FileAccess.READ_WRITE)
		if f:
			f.seek_end()
			f.store_line("POSTURE_FIX running on %s" % skel.name)
			f.close()
	for bone_name in DAMPEN:
		_dampen_pitch(skel, bone_name, float(DAMPEN[bone_name]))


func _dampen_pitch(skel: Skeleton3D, bone_name: String, strength: float) -> void :
	var bi: = skel.find_bone(bone_name)
	if bi < 0:
		return
	var rest_x: = skel.get_bone_rest(bi).basis.get_euler().x
	var e: = skel.get_bone_pose_rotation(bi).get_euler()
	e.x = lerpf(e.x, rest_x, clampf(strength, 0.0, 1.0))
	skel.set_bone_pose_rotation(bi, Quaternion.from_euler(e))
