extends SceneTree



func _init() -> void :
	call_deferred("_run")


func _run() -> void :
	var tok: = str(ModelUtils.BUILD_FIX_TOKEN)
	if not ("LEG_PLANT" in tok or "WARRIOR_REST" in tok or "WARRIOR_STAND" in tok):
		push_error("BUILD_FIX_TOKEN missing")
		quit(1)
		return

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	if skel == null or not skel.has_node("LegPlantFix"):
		push_error("LegPlantFix missing")
		quit(1)
		return

	var anim: = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib: = load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.process_priority = -100
	skel.get_node("LegPlantFix").process_priority = 1000
	anim.play("ual1_Idle")
	for i in 24:
		await process_frame
	var rt: = skel.find_bone("RightUpperLeg")
	var rest_q: Quaternion = skel.get_bone_rest(rt).basis.get_rotation_quaternion()
	var pose_q: Quaternion = skel.get_bone_pose_rotation(rt)
	if rest_q.angle_to(pose_q) > deg_to_rad(8.0):
		push_error("right leg not planted")
		quit(1)
		return
	print("SMOKE_UPRIGHT_GAZE_OK")
	quit(0)
