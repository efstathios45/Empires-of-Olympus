extends SceneTree
## Final proof: GearGrip + markers at Grip origin and mesh hand tip.
func _init(): call_deferred("run")

func run():
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
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
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
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
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Idle_Neutral")
	for i in 20:
		await process_frame

	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var wr = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
	var grip_n := wp.get_node_or_null("Grip") as Node3D
	var grip_o := grip_n.global_transform.origin
	# mesh outer
	var mi: MeshInstance3D
	for n in hero.find_children("*", "MeshInstance3D", true, false):
		mi = n as MeshInstance3D
		if mi and mi.mesh: break
	var maxx := -999.0
	var hand := Vector3.ZERO
	for si in mi.mesh.get_surface_count():
		for v in mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
			var g: Vector3 = mi.global_transform * v
			if g.x > maxx:
				maxx = g.x
				hand = g
	_sphere(stage, wr.origin, Color(1, 0, 0), 0.035) ## wrist bone
	_sphere(stage, grip_o, Color(0, 1, 0), 0.04) ## grip mount
	_sphere(stage, hand, Color(1, 0, 1), 0.04) ## mesh hand tip
	print("wrist=", wr.origin, " grip=", grip_o, " hand=", hand, " dist_grip_hand=", grip_o.distance_to(hand))

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.1, 1.35, -3.1)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 24:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_idle_face.png")

	# Aim at HAND not bone
	cam.fov = 32
	cam.position = Vector3(hand.x + 0.9, hand.y + 0.25, hand.z - 1.15)
	cam.look_at(hand, Vector3.UP)
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_hand_close.png")

	cam.fov = 30
	cam.position = Vector3(3.1, 1.2, -0.1)
	cam.look_at(Vector3(0.15, 0.95, 0), Vector3.UP)
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_idle_side.png")

	anim.play("Walk")
	cam.position = Vector3(1.15, 1.35, -3.0)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 26:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_walk_face.png")

	print("PROOF_OK")
	quit()


func _sphere(parent: Node3D, pos: Vector3, col: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos
