extends SceneTree

# UAL sky-gaze regression: posture fix must keep look_y down on ual1_Idle.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tok := str(ModelUtils.BUILD_FIX_TOKEN)
	if not ("UAL_POSTURE" in tok or "HELLENIC_NPC_POSE" in tok or "LEG_PLANT" in tok):
		push_error("BUILD_FIX_TOKEN missing UAL_POSTURE marker")
		quit(1)
		return

	# Legacy guard mesh + UAL idle — the known-bad combo when used as hero.
	var m: Node3D = load("res://assets/characters/city_guard/city_guard.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim: AnimationPlayer = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/city_guard/city_guard_animations.tres") as AnimationLibrary
	lib = ModelUtils.retarget_general_skeleton_library(lib, anim, m)
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	ModelUtils.install_ual_posture_fix(m, anim)
	var skel: Skeleton3D = m.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null or not skel.has_node("NpcPostureFix"):
		push_error("UalPostureFix missing")
		quit(1)
		return
	anim.play("ual1_Idle")
	for i in 24:
		await process_frame
	skel.force_update_all_bone_transforms()
	var hi := skel.find_bone("Head")
	var look_y: float = (-(skel.global_transform * skel.get_bone_global_pose(hi)).basis.z).y
	if look_y > 0.28:
		push_error("still sky-gazing look_y=%s" % look_y)
		quit(1)
		return
	print("SMOKE_UPRIGHT_GAZE_OK look_y=", snappedf(look_y, 0.01))
	quit(0)
