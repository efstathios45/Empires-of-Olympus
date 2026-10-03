extends SceneTree
func _init(): call_deferred("run")
func run():
	for path_tag in [
		["res://assets/characters/greek_hoplite/greek_hoplite.glb", "cur_hoplite"], 
		["res://assets/characters/greek_spartan/greek_spartan.glb", "cur_spartan"], 
	]:
		await shot(path_tag[0], path_tag[1])
	print("CUR_OK")
	quit()
func shot(path, tag) -> void :
	var vp: = SubViewport.new()
	vp.size = Vector2i(700, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.58, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.35
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)
	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load(path).instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)

	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Idle_Neutral" if anim.has_animation("Idle_Neutral") else "Idle")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.0, 1.4, -3.0)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 24: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOP_%s_idle.png" % tag)
	anim.play("Walk")
	for i in 20: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOP_%s_walk.png" % tag)
	cam.position = Vector3(2.9, 1.3, -0.2)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOP_%s_side.png" % tag)
	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var wr = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))).origin
	var ua = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("UpperArm.R"))).origin
	print(tag, " Wrist.R=", wr, " UpperArm.R=", ua, " facing_meta=", hero.has_meta("eoo_quat_facing"))
	vp.queue_free()
	await process_frame
