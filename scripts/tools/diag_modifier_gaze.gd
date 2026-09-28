extends SceneTree
## Compare Node-style correction vs SkeletonModifier3D correction.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.scale_to_height(m, 1.85)
	ModelUtils.ground_model(m)
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break

	anim.play("ual1_Idle")
	for i in 20:
		await process_frame
	_rep("RAW", skel)

	## Manual correct in _process style (no modifier installed).
	ModelUtils.correct_sky_gaze(skel, 1.0)
	skel.force_update_all_bone_transforms()
	_rep("MANUAL", skel)

	## Fresh instance with modifier install.
	m.queue_free()
	await process_frame
	m = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var fix = skel.get_node("SkyGazeFix")
	print("FIX=", fix, " class=", fix.get_class(), " script=", fix.get_script(), " active=", fix.get("active"))
	anim.play("ual1_Idle")
	for i in 30:
		await process_frame
	_rep("MODIFIER", skel)

	## Force one manual pass on top of modifier result.
	ModelUtils.correct_sky_gaze(skel, 1.0)
	skel.force_update_all_bone_transforms()
	_rep("MODIFIER_PLUS_MANUAL", skel)
	quit(0)


func _rep(tag: String, skel: Skeleton3D) -> void:
	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	print(
		"%s upright=%.4f fwd_up=%.4f head_ex=%.1f" % [
			tag,
			(ht.origin - hp.origin).normalized().dot(Vector3.UP),
			(-ht.basis.z).normalized().dot(Vector3.UP),
			rad_to_deg(ht.basis.get_euler().x),
		]
	)
