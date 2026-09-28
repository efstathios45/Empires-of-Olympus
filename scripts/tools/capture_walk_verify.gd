extends SceneTree
## Prove walk anim moves legs (not levitate) and idle stays upright/human.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var ok := true
	ok = await _check_walk() and ok
	ok = await _check_idle_npc() and ok
	if not ok:
		push_error("WALK_VERIFY_FAIL")
		quit(1)
		return
	print("WALK_VERIFY_OK")
	quit(0)


func _check_walk() -> bool:
	var vp := _stage(520, 700)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D = _skel(m)
	assert(skel.has_node("LegPlantFix"))
	var anim := _ensure_anim(m, "res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres")
	anim.process_priority = -100
	skel.get_node("LegPlantFix").process_priority = 1000
	anim.play("ual1_Walk")
	var cam := _cam(stage, true)
	## Sample foot Y / step over several frames
	var min_sep := 999.0
	var max_sep := -999.0
	var samples: Array = []
	for i in 40:
		await process_frame
		var lf: Vector3 = _pos(skel, "LeftFoot")
		var rf: Vector3 = _pos(skel, "RightFoot")
		var sep := absf(lf.z - rf.z) + absf(lf.x - rf.x)
		min_sep = minf(min_sep, sep)
		max_sep = maxf(max_sep, sep)
		if i % 8 == 0:
			samples.append(snapped(sep, 0.001))
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/WALK_hero_side.png")
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.0, 1.55, -2.6)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/WALK_hero_front.png")
	var range_sep := max_sep - min_sep
	var foot_y := minf(_pos(skel, "LeftFoot").y, _pos(skel, "RightFoot").y)
	var head_i := skel.find_bone("Head")
	var hg: Transform3D = skel.global_transform * skel.get_bone_global_pose(head_i)
	var fwd := (-hg.basis.z).normalized()
	if absf(hg.basis.z.y) < absf(fwd.y):
		fwd = hg.basis.z.normalized()
	var head_pitch := asin(clampf(fwd.y, -1.0, 1.0))
	print("WALK foot_sep min=", snapped(min_sep, 0.01), " max=", snapped(max_sep, 0.01),
		" range=", snapped(range_sep, 0.01), " foot_y=", snapped(foot_y, 0.01),
		" head_pitch=", snapped(rad_to_deg(head_pitch), 0.1), " samples=", samples)
	var passed := true
	if range_sep <= 0.08:
		print("FAIL walk: feet barely move (levitate) range=", range_sep)
		passed = false
	if foot_y > 0.22:
		print("FAIL walk: floating above ground foot_y=", foot_y)
		passed = false
	if absf(head_pitch) > deg_to_rad(30.0):
		print("FAIL walk: head not near horizon pitch=", rad_to_deg(head_pitch))
		passed = false
	vp.queue_free()
	await process_frame
	return passed


func _check_idle_npc() -> bool:
	var vp := _stage(480, 640)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/citizen_woman/citizen_woman.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.68)
	var skel: Skeleton3D = _skel(m)
	var anim := _ensure_anim(m, "res://assets/characters/citizen_woman/citizen_woman_animations.tres")
	anim.process_priority = -100
	skel.get_node("LegPlantFix").process_priority = 1000
	anim.play("ual1_Idle")
	var cam := _cam(stage, false)
	var head_pitch_sum := 0.0
	var hand_y_var := 0.0
	var prev_hand_y := 0.0
	for i in 36:
		await process_frame
		var head_i := skel.find_bone("Head")
		var g: Transform3D = skel.global_transform * skel.get_bone_global_pose(head_i)
		## Forward from -Z of head; pitch vs horizon
		var fwd: Vector3 = (-g.basis.z).normalized()
		head_pitch_sum += asin(clampf(fwd.y, -1.0, 1.0))
		var hy: float = _pos(skel, "LeftHand").y
		if i > 0:
			hand_y_var += absf(hy - prev_hand_y)
		prev_hand_y = hy
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/IDLE_woman_natural.png")
	var avg_pitch := head_pitch_sum / 36.0
	print("IDLE head_pitch_avg=", snapped(rad_to_deg(avg_pitch), 0.1),
		"deg hand_motion=", snapped(hand_y_var, 0.001))
	var passed := true
	## Looking at sky ≈ large positive pitch; want near horizon (±25°).
	if absf(avg_pitch) > deg_to_rad(28.0):
		print("FAIL idle: looking at sky/ground pitch=", rad_to_deg(avg_pitch))
		passed = false
	## Some in-place motion expected (sway / idle anim).
	if hand_y_var < 0.01:
		print("FAIL idle: completely frozen (no in-place motion)")
		passed = false
	## Still human: hands below shoulders
	var drop := _pos(skel, "LeftUpperArm").y - _pos(skel, "LeftHand").y
	if drop < 0.2:
		print("FAIL idle: arms not down drop=", drop)
		passed = false
	vp.queue_free()
	await process_frame
	return passed


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
		m.add_child(anim)
	var lib := load(lib_path) as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	return anim


func _pos(skel: Skeleton3D, bone: String) -> Vector3:
	return (skel.global_transform * skel.get_bone_global_pose(skel.find_bone(bone))).origin
