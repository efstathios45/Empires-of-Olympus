extends SceneTree
## Verify proposed StandPlant (rest core + world A-pose arms) on every plaza humanoid.
## FAIL if hands aren't below shoulders or span is huge (T-pose) / zero (behind-back).


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var meshes := [
		["hoplite", "res://assets/characters/spartan_hoplite/spartan_hoplite.glb",
			"res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres", 1.85],
		["guard", "res://assets/characters/city_guard/city_guard.glb",
			"res://assets/characters/city_guard/city_guard_animations.tres", 1.84],
		["woman", "res://assets/characters/citizen_woman/citizen_woman.glb",
			"res://assets/characters/citizen_woman/citizen_woman_animations.tres", 1.68],
		["merchant", "res://assets/characters/citizen_merchant/citizen_merchant.glb",
			"res://assets/characters/citizen_merchant/citizen_merchant_animations.tres", 1.78],
		["smith", "res://assets/characters/blacksmith_npc/blacksmith_npc.glb",
			"res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres", 1.8],
		["priestess", "res://assets/characters/oracle_priestess/oracle_priestess.glb",
			"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres", 1.75],
	]
	var ok := true
	for m in meshes:
		var passed: bool = await _verify(String(m[0]), String(m[1]), String(m[2]), float(m[3]), 0.0)
		ok = ok and passed
		## Same mesh rotated 180° — arm aim must stay character-local.
		var passed_rot: bool = await _verify(String(m[0]) + "_rot", String(m[1]), String(m[2]), float(m[3]), PI)
		ok = ok and passed_rot
	if not ok:
		push_error("STAND_VERIFY_FAIL")
		quit(1)
		return
	print("STAND_VERIFY_OK")
	quit(0)


func _verify(tag: String, glb: String, lib_path: String, height: float, yaw: float) -> bool:
	var vp := SubViewport.new()
	vp.size = Vector2i(480, 640)
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
	pm.size = Vector2(8, 8)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)

	var model: Node3D = load(glb).instantiate()
	stage.add_child(model)
	## Use the real setup path under test.
	ModelUtils.setup_character_for_movement(model, height)
	model.rotation.y = yaw
	var skel: Skeleton3D
	for n in model.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert(skel != null)
	assert(skel.has_node("LegPlantFix") or skel.has_node("StandPlantFix"),
		"%s missing plant fix" % tag)

	var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		model.add_child(anim)
	var lib := load(lib_path) as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	anim.process_priority = -100
	var fix: Node = skel.get_node_or_null("LegPlantFix")
	if fix == null:
		fix = skel.get_node_or_null("StandPlantFix")
	if fix:
		fix.process_priority = 1000
	anim.play("ual1_Idle" if anim.has_animation("ual1_Idle") else lib.get_animation_list()[0])

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.0, 1.55, -2.6)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 24:
		await process_frame

	var lh: Vector3 = _pos(skel, "LeftHand")
	var rh: Vector3 = _pos(skel, "RightHand")
	var la: Vector3 = _pos(skel, "LeftUpperArm")
	var ra: Vector3 = _pos(skel, "RightUpperArm")
	var head: Vector3 = _pos(skel, "Head")
	var hips: Vector3 = _pos(skel, "Hips")
	var drop_l := la.y - lh.y
	var drop_r := ra.y - rh.y
	var span := absf(lh.x - rh.x)
	var upright := (head - hips).normalized().dot(Vector3.UP)
	var path := "/opt/cursor/artifacts/VERIFY_%s_front.png" % tag
	vp.get_texture().get_image().save_png(path)

	var passed := true
	if upright < 0.92:
		print("FAIL ", tag, " upright=", upright)
		passed = false
	if drop_l < 0.25 or drop_r < 0.25:
		print("FAIL ", tag, " hands not below shoulders dropL=", drop_l, " dropR=", drop_r)
		passed = false
	## T-pose span ~1.5+; behind-back ~0; good A-pose ~0.35–0.9
	if span < 0.25 or span > 1.2:
		print("FAIL ", tag, " bad arm span=", span)
		passed = false
	if passed:
		print("PASS ", tag, " dropL=", snapped(drop_l, 0.01), " dropR=", snapped(drop_r, 0.01),
			" span=", snapped(span, 0.01), " upright=", snapped(upright, 0.001))
	vp.queue_free()
	await process_frame
	return passed


func _pos(skel: Skeleton3D, bone_name: String) -> Vector3:
	var bi := skel.find_bone(bone_name)
	return (skel.global_transform * skel.get_bone_global_pose(bi)).origin
