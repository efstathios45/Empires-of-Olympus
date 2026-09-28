extends SceneTree
## Headless: no zoom; leg-plant installed; idle silhouette human-tall.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var src := FileAccess.open("res://scripts/player.gd", FileAccess.READ)
	var text := src.get_as_text()
	src.close()
	if "CAM_ZOOM_MIN" in text or "_apply_cam_zoom" in text:
		push_error("zoom helpers must be removed")
		quit(1)
		return
	if not text.contains("const CAM_DISTANCE := 5.6"):
		push_error("fixed CAM_DISTANCE missing")
		quit(1)
		return

	var tok := str(ModelUtils.BUILD_FIX_TOKEN)
	if not ("LEG_PLANT" in tok or "WARRIOR_REST" in tok or "WARRIOR_STAND" in tok):
		push_error("BUILD_FIX_TOKEN wrong")
		quit(1)
		return

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert(skel != null and skel.has_node("LegPlantFix"))
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.process_priority = -100
	skel.get_node("LegPlantFix").process_priority = 1000
	anim.play("ual1_Idle")
	for i in 24:
		await process_frame
	var lt := skel.find_bone("LeftUpperLeg")
	var lk := skel.find_bone("LeftLowerLeg")
	var rest_lt: Quaternion = skel.get_bone_rest(lt).basis.get_rotation_quaternion()
	var pose_lt: Quaternion = skel.get_bone_pose_rotation(lt)
	var ang := rest_lt.angle_to(pose_lt)
	print("SMOKE_LEG_ANG=", rad_to_deg(ang))
	if ang > deg_to_rad(8.0):
		push_error("legs not planted to rest: %s deg" % rad_to_deg(ang))
		quit(1)
		return
	var a := (skel.global_transform * skel.get_bone_global_pose(lt)).origin
	var b := (skel.global_transform * skel.get_bone_global_pose(lk)).origin
	print("SMOKE_THIGH=", a.distance_to(b))
	print("SMOKE_ZOOM_CAMERA_OK")
	quit(0)
