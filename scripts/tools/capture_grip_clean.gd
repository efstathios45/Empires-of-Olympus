extends SceneTree
## Clean final captures — spear + shield + sword, no debug markers.
func _init(): call_deferred("run")

func run():
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	await _cap("dory", "res://assets/props/weapons/dory_spear.glb", GearGrip, GearPaint)
	await _cap("xiphos", "res://assets/props/gear/xiphos_sword.glb", GearGrip, GearPaint)
	print("CLEAN_OK")
	quit()


func _cap(tag: String, weapon: String, GearGrip, GearPaint) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1000, 1200)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.48, 0.56, 0.64)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.88, 0.88, 0.88)
	e.ambient_light_energy = 1.05
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, 28, 0)
	light.light_energy = 1.45
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)

	var wrap := Node3D.new()
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	var anim := hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	ModelUtils.strip_arm_animation_tracks(anim)
	var wp = GearGrip.attach_weapon(hero, weapon)
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, weapon)
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Idle_Neutral")
	for i in 18:
		await process_frame

	var mi: MeshInstance3D
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		mi = n
		if mi and mi.mesh: break
	var hand := Vector3.ZERO
	var maxx := -999.0
	for si in mi.mesh.get_surface_count():
		for v in mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
			var g: Vector3 = mi.global_transform * v
			if g.x > maxx:
				maxx = g.x
				hand = g

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.05, 1.4, -3.15)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 22:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOLD_%s_idle_face.png" % tag)

	cam.position = Vector3(hand.x + 0.95, hand.y + 0.2, hand.z - 1.2)
	cam.look_at(hand + Vector3(-0.05, 0.05, 0), Vector3.UP)
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOLD_%s_hand.png" % tag)

	cam.position = Vector3(3.05, 1.2, -0.05)
	cam.look_at(Vector3(0.1, 0.95, 0), Vector3.UP)
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOLD_%s_side.png" % tag)

	anim.play("Walk")
	cam.position = Vector3(1.1, 1.35, -3.0)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 24:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HOLD_%s_walk.png" % tag)

	if wp:
		var g: Node3D = wp.get_node("Grip") as Node3D
		print(tag, " spear/sword grip=", g.global_transform.origin, " hand=", hand, " d=", g.global_transform.origin.distance_to(hand))
	if sh:
		var bat := sh as BoneAttachment3D
		var g2: Node3D = sh.get_node("Grip") as Node3D
		print(tag, " shield bone=", bat.bone_name, " grip=", g2.global_transform.origin)
	vp.queue_free()
	await process_frame
