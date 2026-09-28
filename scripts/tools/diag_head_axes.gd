extends SceneTree
## Figure out which Head bone axis is the face / up direction.

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	# Remove gaze fix for raw analysis
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var fix := skel.get_node_or_null("SkyGazeFix")
	if fix:
		fix.set_process(false)
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)

	anim.stop()
	skel.reset_bone_poses()
	for i in 5:
		await process_frame
	_dump("REST", skel, m)

	anim.play("ual1_Idle")
	for i in 15:
		await process_frame
	_dump("IDLE_RAW", skel, m)

	# With fix
	if fix:
		fix.set_process(true)
	for i in 8:
		await process_frame
	_dump("IDLE_FIX", skel, m)
	quit(0)

func _dump(tag: String, skel: Skeleton3D, m: Node3D) -> void:
	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var chest := skel.find_bone("UpperChest")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	var ct := skel.global_transform * skel.get_bone_global_pose(chest)
	print("--- ", tag, " model_y=", m.rotation.y)
	print("  head_o=", ht.origin, " hips_o=", hp.origin)
	print("  head_basis X=", ht.basis.x, " Y=", ht.basis.y, " Z=", ht.basis.z)
	print("  -Z.up=", (-ht.basis.z).dot(Vector3.UP), " +Z.up=", ht.basis.z.dot(Vector3.UP))
	print("  -Y.up=", (-ht.basis.y).dot(Vector3.UP), " +Y.up=", ht.basis.y.dot(Vector3.UP))
	print("  -X.up=", (-ht.basis.x).dot(Vector3.UP), " +X.up=", ht.basis.x.dot(Vector3.UP))
	# Which axis is most aligned with world forward of the character?
	# Character faces MODEL_FRONT after orient = local -Z of model root.
	var model_fwd := (-m.global_transform.basis.z).normalized()
	print("  model_fwd=", model_fwd)
	for axis_name in ["+X", "-X", "+Y", "-Y", "+Z", "-Z"]:
		var v: Vector3
		match axis_name:
			"+X": v = ht.basis.x
			"-X": v = -ht.basis.x
			"+Y": v = ht.basis.y
			"-Y": v = -ht.basis.y
			"+Z": v = ht.basis.z
			"-Z": v = -ht.basis.z
		print("  head%s dot model_fwd=%.3f dot UP=%.3f" % [axis_name, v.normalized().dot(model_fwd), v.normalized().dot(Vector3.UP)])
	# Spine lean: vector hips->head vs UP
	var spine := (ht.origin - hp.origin).normalized()
	print("  spine_dir=", spine, " spine_dot_up=", spine.dot(Vector3.UP), " lean_from_vertical_deg=", rad_to_deg(acos(clampf(spine.dot(Vector3.UP), -1, 1))))
	print("  chest_o=", ct.origin, " chest_Y=", ct.basis.y)
