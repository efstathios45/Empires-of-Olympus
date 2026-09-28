extends SceneTree
## Prove Walk + Attack with a decoy NPC AnimationPlayer in-tree
## (the bug was LegPlant binding to plaza NPCs).


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var vp := _stage(560, 720)
	var stage: Node3D = vp.get_child(0)

	## Decoy "plaza NPC" higher in the tree — old resolve grabbed this.
	var decoy_body := StaticBody3D.new()
	decoy_body.name = "oracle_priestess_decoy"
	root.add_child(decoy_body)
	var decoy_model := Node3D.new()
	decoy_model.name = "oracle_priestess"
	decoy_body.add_child(decoy_model)
	var decoy_ap := AnimationPlayer.new()
	decoy_ap.name = "AnimationPlayer"
	decoy_model.add_child(decoy_ap)
	var decoy_lib := AnimationLibrary.new()
	var decoy_idle := Animation.new()
	decoy_idle.length = 1.0
	decoy_idle.loop_mode = Animation.LOOP_LINEAR
	decoy_lib.add_animation("ual1_Idle", decoy_idle)
	decoy_ap.add_animation_library("", decoy_lib)
	decoy_ap.play("ual1_Idle")

	## Hero under a CharacterBody3D like game_world.
	var body := CharacterBody3D.new()
	body.name = "HeroBody"
	stage.add_child(body)
	var mesh_root := Node3D.new()
	mesh_root.name = "MeshRoot"
	body.add_child(mesh_root)
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	mesh_root.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D = _skel(m)
	assert(skel != null and skel.has_node("LegPlantFix"))
	var anim := _ensure_anim(m, "res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres")
	ModelUtils.bind_leg_plant_anim(m, anim)
	anim.process_priority = -100
	var fix: Node = skel.get_node("LegPlantFix")
	fix.process_priority = 1000

	var fix_anim: AnimationPlayer = fix.get("_anim") as AnimationPlayer
	print("same_anim=", anim == fix_anim,
		" hero=", anim.get_path(),
		" fix=", fix_anim.get_path() if fix_anim else "NULL",
		" decoy=", decoy_ap.get_path())
	if anim != fix_anim:
		push_error("LIVE_MOTION_FAIL wrong AnimationPlayer binding")
		quit(1)
		return

	var cam := _cam(stage, true)
	anim.play("ual1_Idle")
	for i in 12:
		await process_frame
	var idle_arm := _arm_delta(skel)
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/LIVE_idle.png")

	anim.play("ual1_Walk")
	for i in 6:
		await process_frame
	print("mode_walk=", fix.call("_clip_mode"), " clip=", anim.current_animation)
	var zmin := 999.0
	var zmax := -999.0
	for i in 40:
		await process_frame
		var z: float = _pos(skel, "LeftFoot").z
		zmin = minf(zmin, z)
		zmax = maxf(zmax, z)
		if i % 10 == 0:
			vp.get_texture().get_image().save_png(
				"/opt/cursor/artifacts/LIVE_walk_%d.png" % int(i / 10))
	var z_range := zmax - zmin
	print("WALK z_range=", snapped(z_range, 0.01))

	## Side view for the slash (same angle as walk).
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.35
	cam.position = Vector3(3.4, 1.05, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	anim.play("ual1_Sword_Attack")
	for i in 3:
		await process_frame
	print("mode_attack=", fix.call("_clip_mode"), " clip=", anim.current_animation)
	var amin := 999.0
	var amax := -999.0
	var hand0: Vector3 = _pos(skel, "RightHand")
	var hand_travel := 0.0
	for i in 30:
		await process_frame
		var a := _arm_delta(skel)
		amin = minf(amin, a)
		amax = maxf(amax, a)
		hand_travel = maxf(hand_travel, _pos(skel, "RightHand").distance_to(hand0))
		if i % 7 == 0:
			vp.get_texture().get_image().save_png(
				"/opt/cursor/artifacts/LIVE_attack_%d.png" % int(i / 7))
	var attack_vs_idle := absf(amax - idle_arm)
	print("ATTACK arm_range=", snapped(amax - amin, 0.01),
		" attack_vs_idle=", snapped(attack_vs_idle, 0.01),
		" hand_travel=", snapped(hand_travel, 0.01),
		" idle_arm=", snapped(idle_arm, 0.01))

	var ok := z_range > 0.08 and hand_travel > 0.12
	print("LIVE_MOTION_DONE OK=", ok,
		" z_range=", snapped(z_range, 0.01),
		" attack_vs_idle=", snapped(attack_vs_idle, 0.01),
		" hand_travel=", snapped(hand_travel, 0.01))
	vp.queue_free()
	quit(0 if ok else 1)


func _arm_delta(skel: Skeleton3D) -> float:
	var bi := skel.find_bone("RightUpperArm")
	var q: Quaternion = skel.get_bone_pose_rotation(bi)
	var rest_q: Quaternion = skel.get_bone_rest(bi).basis.get_rotation_quaternion()
	return q.angle_to(rest_q)


func _stage(w: int, h: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.66)
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)
	return vp


func _cam(stage: Node3D, side: bool) -> Camera3D:
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	if side:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 2.35
		cam.position = Vector3(3.4, 1.05, 0)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = 40
		cam.position = Vector3(-2.0, 1.55, -2.6)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	return cam


func _skel(m: Node3D) -> Skeleton3D:
	for n in m.find_children("*", "Skeleton3D", true, false):
		return n
	return null


func _ensure_anim(m: Node3D, lib_path: String) -> AnimationPlayer:
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		m.add_child(anim)
	var lib := load(lib_path) as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	return anim


func _pos(skel: Skeleton3D, bone: String) -> Vector3:
	return (skel.global_transform * skel.get_bone_global_pose(skel.find_bone(bone))).origin
