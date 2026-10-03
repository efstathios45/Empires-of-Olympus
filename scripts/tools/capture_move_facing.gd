extends SceneTree

func _init(): call_deferred("run")
func run():
	var PlayerScript = load("res://scripts/player.gd")
	var player = PlayerScript.new()
	root.add_child(player)
	await process_frame
	await process_frame
	var mesh_root: Node3D = player.get("mesh_root")
	var model: Node3D = mesh_root.get_child(0)
	var skel: Skeleton3D = model.find_child("Skeleton3D", true, false)

	mesh_root.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	await process_frame
	var head_i = skel.find_bone("Head")
	var nose_i = skel.find_bone("Head")
	var head_xf = skel.global_transform * skel.get_bone_global_pose(head_i)


	var chest_i = skel.find_bone("Chest")
	var chest_xf = skel.global_transform * skel.get_bone_global_pose(chest_i)
	print("mesh_root.yaw=", mesh_root.rotation.y)
	print("Head world=", head_xf.origin, " Chest=", chest_xf.origin)

	var model_fwd = - mesh_root.global_transform.basis.z
	print("model_fwd=", model_fwd, " expect ~(0,0,-1)")



	var vp: = SubViewport.new()
	vp.size = Vector2i(700, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)

	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.58, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	e.ambient_light_energy = 0.8
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.25
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")

	hero.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Walk")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 34

	cam.position = Vector3(0.8, 1.4, -3.2)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 22: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_face_cam.png")
	print("FACE_CAM saved — should show FACE if facing -Z correctly")

	cam.position = Vector3(0.8, 1.4, 3.2)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 16: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_back_cam.png")
	print("BACK_CAM saved")
	print("MOVE_FACING_OK")
	quit()
