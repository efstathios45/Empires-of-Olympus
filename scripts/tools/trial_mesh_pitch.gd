extends SceneTree
## Trial mesh_root / model pitch offsets and capture which looks upright.

func _init(): call_deferred("run")
func run():
	var root=get_root()
	var vp:=SubViewport.new()
	vp.size=Vector2i(480,640)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vp.msaa_3d=Viewport.MSAA_4X
	root.add_child(vp)
	var stage:=Node3D.new(); vp.add_child(stage)
	var env:=WorldEnvironment.new(); var e:=Environment.new()
	e.background_mode=Environment.BG_COLOR; e.background_color=Color(0.42,0.52,0.62)
	env.environment=e; stage.add_child(env)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-45,30,0); light.light_energy=1.4; stage.add_child(light)
	var floor:=MeshInstance3D.new(); var pm:=PlaneMesh.new(); pm.size=Vector2(10,10); floor.mesh=pm
	var fm:=StandardMaterial3D.new(); fm.albedo_color=Color(0.3,0.35,0.25); floor.material_override=fm; stage.add_child(floor)
	var body:=CharacterBody3D.new(); body.set_script(load("res://scripts/player.gd")); stage.add_child(body)
	body.set_physics_process(false)
	for i in 30: await process_frame
	body.set_physics_process(false); body.global_position=Vector3.ZERO
	if body.anim: body.anim.play("ual1_Idle")
	for i in 20: await process_frame
	var cam:=Camera3D.new(); cam.projection=Camera3D.PROJECTION_ORTHOGONAL; cam.size=2.5
	stage.add_child(cam); cam.current=true
	cam.position=Vector3(3.2,1.15,0); cam.look_at(Vector3(0,1,0), Vector3.UP)
	var model=body.mesh_root.get_child(0) as Node3D
	# Disable gaze fix for clean trial of mesh pitch
	var skel=null
	for n in body.mesh_root.find_children("*","Skeleton3D",true,false): skel=n; break
	var fix=skel.get_node_or_null("SkyGazeFix") if skel else null
	if fix: fix.set_process(false)
	for deg in [0, -8, -12, -15, -18, -22]:
		body.mesh_root.rotation.x = 0
		model.rotation.x = deg_to_rad(float(deg))
		# keep authored yaw
		for i in 6: await process_frame
		vp.render_target_update_mode=SubViewport.UPDATE_ONCE
		await process_frame
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/trial_model_x%d.png" % deg)
		print("SAVED trial_model_x", deg)
		vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	# With gaze fix ON + model pitch -12
	if fix: fix.set_process(true)
	model.rotation.x = deg_to_rad(-12.0)
	for i in 8: await process_frame
	vp.render_target_update_mode=SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/trial_fix_and_pitch12.png")
	print("SAVED trial_fix_and_pitch12")
	print("TRIAL_OK")
	quit(0)
