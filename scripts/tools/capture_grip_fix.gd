extends SceneTree

func _init(): call_deferred("run")

func run():
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")

	await _shot("spear_shield", func(hero):
		var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
		var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
		if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
		if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
		return [wp, sh]
	)
	await _shot("xiphos_shield", func(hero):
		var wp = GearGrip.attach_weapon(hero, "res://assets/props/gear/xiphos_sword.glb")
		var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
		if wp: GearPaint.paint_attached(wp, "res://assets/props/gear/xiphos_sword.glb")
		if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
		return [wp, sh]
	)
	print("GRIPFIX_OK")
	quit()


func _shot(tag: String, attach: Callable) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(900, 1100)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.48, 0.56, 0.64)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, 28, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim: = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	ModelUtils.strip_arm_animation_tracks(anim)
	var mounts: Array = attach.call(hero)
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))

	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30

	anim.play("Idle_Neutral")
	cam.position = Vector3(1.05, 1.4, -3.1)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 28:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GRIPFIX_%s_idle_face.png" % tag)

	cam.position = Vector3(3.0, 1.3, -0.2)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GRIPFIX_%s_idle_side.png" % tag)


	var wr: = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))).origin
	cam.fov = 28
	cam.position = Vector3(wr.x + 0.85, wr.y + 0.15, wr.z - 1.1)
	cam.look_at(wr + Vector3(0.15, 0.05, 0), Vector3.UP)
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GRIPFIX_%s_hand_close.png" % tag)

	anim.play("Walk")
	cam.fov = 30
	cam.position = Vector3(1.1, 1.35, -3.0)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 24:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GRIPFIX_%s_walk_face.png" % tag)

	if mounts.size() > 0 and mounts[0]:
		var wp: Node3D = mounts[0]
		var grip: = wp.get_node_or_null("Grip")
		if grip:
			print(tag, " weapon bone=", wp.bone_name, " grip_global=", grip.global_transform.origin)
	if mounts.size() > 1 and mounts[1]:
		var sh: Node3D = mounts[1]
		var grip: = sh.get_node_or_null("Grip")
		if grip:
			print(tag, " shield bone=", sh.bone_name, " grip_global=", grip.global_transform.origin)

	vp.queue_free()
	await process_frame
