extends SceneTree
func _init(): call_deferred("run")
func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var vp: = SubViewport.new()
	vp.size = Vector2i(800, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.0
	env.environment = e
	stage.add_child(env)
	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var floor_mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var stripe: = MeshInstance3D.new()
	var box: = BoxMesh.new()
	box.size = Vector3(0.35, 0.03, 5.0)
	stripe.mesh = box
	stripe.position = Vector3(0, 0.02, -2.5)
	var sm: = StandardMaterial3D.new()
	sm.albedo_color = Color(0.1, 0.9, 0.2)
	stripe.material_override = sm
	stage.add_child(stripe)

	var wrap: = Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	anim.play("Idle_Neutral")

	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var att: = BoneAttachment3D.new()
	att.bone_name = "Head"
	skel.add_child(att)
	var marker: = MeshInstance3D.new()
	var tip: = BoxMesh.new()
	tip.size = Vector3(0.08, 0.08, 0.35)
	marker.mesh = tip
	marker.position = Vector3(0, 0.05, 0.25)
	var mm: = StandardMaterial3D.new()
	mm.albedo_color = Color(1.0, 0.0, 1.0)
	mm.emission_enabled = true
	mm.emission = Color(1.0, 0.0, 1.0)
	mm.emission_energy_multiplier = 2.0
	marker.material_override = mm
	att.add_child(marker)
	print("armature.yaw=", hero.find_child("CharacterArmature", true, false).rotation.y)
	print("head world=", (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Head"))).origin)
	print("marker world=", marker.global_transform.origin)

	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 32

	cam.position = Vector3(0.5, 1.5, -3.2)
	cam.look_at(Vector3(0, 1.2, 0), Vector3.UP)
	for i in 24: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/NOSE_from_minusZ.png")

	cam.position = Vector3(0.5, 1.5, 3.2)
	cam.look_at(Vector3(0, 1.2, 0), Vector3.UP)
	for i in 16: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/NOSE_from_plusZ.png")
	print("NOSE_OK")
	quit()
