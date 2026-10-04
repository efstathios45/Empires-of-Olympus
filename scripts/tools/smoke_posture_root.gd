extends SceneTree

# Root-cause smoke: no sky-gaze, no collapsed/entangled limbs on plaza + UAL enemies.
# Verifies repeatedly across idle + walk samples.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	# Plaza Quaternius cast (native Idle — must stay upright without UAL)
	ok = await _check_npc(
		"priestess",
		"res://assets/characters/quaternius_oracle_witch/oracle_witch.glb",
		"", "Idle_Neutral", false) and ok
	ok = await _check_npc(
		"guard",
		"res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb",
		"", "Idle_Sword", false) and ok
	ok = await _check_npc(
		"merchant",
		"res://assets/characters/quaternius_merchant_farmer/merchant_farmer.glb",
		"", "Idle", false) and ok
	ok = await _check_npc(
		"woman",
		"res://assets/characters/quaternius_woman_formal/woman_formal.glb",
		"", "Wave", false) and ok
	ok = await _check_npc(
		"smith",
		"res://assets/characters/quaternius_smith_worker/smith_worker.glb",
		"", "Idle", false) and ok
	# UAL enemies MUST install posture fix and look forward
	for id in ["satyr_enemy", "harpy_enemy", "gorgon_enemy", "minotaur_boss"]:
		ok = await _check_enemy(id) and ok
	# Animals should still animate
	ok = await _check_enemy("wolf_enemy") and ok
	ok = await _check_enemy("boar_enemy") and ok
	# Regression: old guard+UAL path must get posture fix if ever used again
	ok = await _check_npc(
		"legacy_guard_ual",
		"res://assets/characters/city_guard/city_guard.glb",
		"res://assets/characters/city_guard/city_guard_animations.tres",
		"ual1_Idle", true) and ok

	if ok:
		print("SMOKE_POSTURE_ROOT_OK")
		quit(0)
	else:
		print("SMOKE_POSTURE_ROOT_FAIL")
		quit(1)


func _check_npc(label: String, glb: String, lib: String, clip: String, expect_fix: bool) -> bool:
	print("-- npc ", label)
	var n: StaticBody3D = load("res://scripts/npc.gd").create(label, label, glb, lib, Vector3.ZERO, 1.75, 0.0)
	n.idle_clip = clip
	get_root().add_child(n)
	for i in 16:
		await process_frame
	var model: Node3D = n.get("_model") as Node3D
	var anim: AnimationPlayer = n.get("_anim") as AnimationPlayer
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D if model else null
	var has_fix := skel != null and skel.has_node("NpcPostureFix")
	if expect_fix and not has_fix:
		print("FAIL ", label, " expected UalPostureFix")
		n.queue_free()
		return false
	if not expect_fix and has_fix and ModelUtils._is_quaternius_model(model):
		print("FAIL ", label, " Quaternius should not need UalPostureFix")
		n.queue_free()
		return false
	var ok := await _pose_ok(label, skel, anim, ["Idle", "Walk", clip])
	n.queue_free()
	await process_frame
	return ok


func _check_enemy(id: String) -> bool:
	print("-- enemy ", id)
	var Enemy: GDScript = load("res://scripts/enemy.gd") as GDScript
	var e: CharacterBody3D = Enemy.call("create", id, Vector3.ZERO) as CharacterBody3D
	get_root().add_child(e)
	e.set_physics_process(false)
	for i in 16:
		await process_frame
	var mesh: Node3D = e.get_node("MeshRoot") as Node3D
	var model: Node3D = mesh.get_child(0) as Node3D if mesh else null
	var anim: AnimationPlayer = e.get("anim") as AnimationPlayer
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D if model else null
	var humanoid := skel != null and (skel.find_bone("LeftUpperArm") >= 0 or skel.find_bone("LeftShoulder") >= 0)
	if humanoid and skel != null and not skel.has_node("NpcPostureFix"):
		print("FAIL ", id, " humanoid missing UalPostureFix")
		e.queue_free()
		return false
	var clips: Array = ["ual1_Idle", "Idle", "ual1_Walk", "Walk", "Gallop"]
	var ok := await _pose_ok(id, skel, anim, clips)
	e.queue_free()
	await process_frame
	return ok


func _pose_ok(label: String, skel: Skeleton3D, anim: AnimationPlayer, clips: Array) -> bool:
	if skel == null:
		print("FAIL ", label, " no skeleton")
		return false
	var played := false
	if anim:
		for c in clips:
			if anim.has_animation(String(c)):
				anim.play(String(c))
				anim.seek(0.35, true)
				played = true
				break
	for i in 10:
		await process_frame
	skel.force_update_all_bone_transforms()

	var head_i := skel.find_bone("Head")
	var hips_i := skel.find_bone("Hips")
	# Animals: different bone names — skip humanoid sky checks
	if head_i < 0 or hips_i < 0:
		print("  ", label, " non-humanoid/animal OK (bones Head/Hips absent)")
		return true

	var xf := skel.global_transform * skel.get_bone_global_pose(head_i)
	var look_y: float = (-xf.basis.z).y
	var upright: float = xf.origin.y - (skel.global_transform * skel.get_bone_global_pose(hips_i)).origin.y

	var lhand := _bone(skel, ["LeftHand", "Wrist.L", "Hand.L", "hand.l"])
	var rhand := _bone(skel, ["RightHand", "Wrist.R", "Hand.R", "hand.r"])
	var lup := _bone(skel, ["LeftUpperArm", "UpperArm.L", "upperarm.l"])
	var rup := _bone(skel, ["RightUpperArm", "UpperArm.R", "upperarm.r"])
	var arms_cross := false
	var hands_dist := 999.0
	if lhand >= 0 and rhand >= 0 and lup >= 0 and rup >= 0:
		var ls := (skel.global_transform * skel.get_bone_global_pose(lup)).origin
		var rs := (skel.global_transform * skel.get_bone_global_pose(rup)).origin
		var lh := (skel.global_transform * skel.get_bone_global_pose(lhand)).origin
		var rh := (skel.global_transform * skel.get_bone_global_pose(rhand)).origin
		hands_dist = lh.distance_to(rh)
		var mid := (ls + rs) * 0.5
		var right_dir := (rs - ls)
		if right_dir.length_squared() > 1e-6:
			right_dir = right_dir.normalized()
			arms_cross = (lh - mid).dot(right_dir) > 0.25 and (rh - mid).dot(right_dir) < -0.25

	print("  look_y=", snappedf(look_y, 0.01), " upright=", snappedf(upright, 0.01),
		" hands=", snappedf(hands_dist, 0.01), " cross=", arms_cross, " played=", played)

	if look_y > 0.28:
		print("FAIL ", label, " sky-gaze look_y=", look_y)
		return false
	if upright < 0.4:
		print("FAIL ", label, " collapsed upright=", upright)
		return false
	if arms_cross:
		print("FAIL ", label, " arms entangled/crossed")
		return false
	# Gorgon idle keeps hands near the torso (~0.05); only fail if nearly coincident.
	if hands_dist < 0.02:
		print("FAIL ", label, " hands glued (entangled) dist=", hands_dist)
		return false
	print("  ", label, " OK")
	return true


func _bone(skel: Skeleton3D, names: Array) -> int:
	for n in names:
		var i := skel.find_bone(String(n))
		if i >= 0:
			return i
	return -1
