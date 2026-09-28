extends SceneTree
## Capture REST vs IDLE vs IDLE+fix from BEHIND (player view) and SIDE.
## Goal: find which state actually looks upright to a player.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var root := get_root()
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 800)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.65)
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, 30, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(14, 14)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.4, 0.22)
	floor.material_override = fm
	stage.add_child(floor)

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.scale_to_height(m, 1.85)
	ModelUtils.ground_model(m)
	## Remove gaze fix for controlled tests
	for n in m.find_children("*", "Skeleton3D", true, false):
		var fix = n.get_node_or_null("SkyGazeFix")
		if fix:
			fix.free()
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	## Metin2-ish: behind and above, looking down
	cam.position = Vector3(0, 2.8, -5.5)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	## REST
	anim.stop()
	skel.reset_bone_poses()
	for i in 12:
		await process_frame
	_snap(vp, "view_REST_behind")

	## IDLE raw
	anim.play("ual1_Idle")
	for i in 30:
		await process_frame
	_snap(vp, "view_IDLE_raw_behind")

	## IDLE + our correct_sky_gaze once
	ModelUtils.correct_sky_gaze(skel, 1.0)
	skel.force_update_all_bone_transforms()
	for i in 4:
		await process_frame
	_snap(vp, "view_IDLE_fix_behind")

	## Side ortho of same three
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	cam.position = Vector3(3.6, 1.05, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	anim.stop()
	skel.reset_bone_poses()
	for i in 10:
		await process_frame
	_snap(vp, "view_REST_side")

	anim.play("ual1_Idle")
	for i in 30:
		await process_frame
	_snap(vp, "view_IDLE_raw_side")

	## Install live modifier and capture
	ModelUtils.install_sky_gaze_fix(m)
	for i in 30:
		await process_frame
	_snap(vp, "view_IDLE_mod_side")

	## Counter-pitch whole model +15 and +25 on top of raw idle (no modifier)
	for n in m.find_children("*", "Skeleton3D", true, false):
		var fix2 = n.get_node_or_null("SkyGazeFix")
		if fix2:
			fix2.free()
	for deg in [15, 25, 35, -15]:
		m.rotation.x = deg_to_rad(float(deg))
		anim.play("ual1_Idle")
		for i in 20:
			await process_frame
		_snap(vp, "view_IDLE_pitch%d_side" % deg)

	print("VIEW_COMPARE_OK")
	quit(0)


func _snap(vp: SubViewport, name: String) -> void:
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/%s.png" % name)
	print("SAVED ", name)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
