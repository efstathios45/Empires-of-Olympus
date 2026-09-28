extends SceneTree
## Prove KayKit hero: grounded walk, slash, and F-block shield raise.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var vp := _stage(640, 800)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/kaykit_knight/Knight.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	assert(not m.find_child("LegPlantFix", true, false), "KayKit must not get LegPlantFix")
	var grounder = m.find_child("KaykitFootGround", true, false)
	print("kaykit_grounder=", grounder, " model_y=", m.global_position.y)
	var skel: Skeleton3D = null
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var anim: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	assert(anim != null and anim.has_animation("Walking_A"))
	ModelUtils.set_animation_loops(anim)

	## Attach sword + shield on KayKit sockets.
	var sword = load("res://scripts/gear_grip.gd").attach_weapon(m, "res://assets/props/kaykit/sword_1handed.glb")
	var shield = load("res://scripts/gear_grip.gd").attach_shield(m, "res://assets/props/kaykit/shield_round.glb")
	print("sword_attach=", sword != null, " shield_attach=", shield != null)

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	cam.position = Vector3(3.5, 1.1, 0.15)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	anim.play("Idle")
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KAYKIT_idle.png")

	anim.play("Walking_A")
	var zmin := 999.0
	var zmax := -999.0
	var ymin := 999.0
	var ymax := -999.0
	for i in 40:
		await process_frame
		var lf: Vector3 = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("foot.l"))).origin
		zmin = minf(zmin, lf.z)
		zmax = maxf(zmax, lf.z)
		ymin = minf(ymin, lf.y)
		ymax = maxf(ymax, lf.y)
		if i % 10 == 0:
			vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KAYKIT_walk_%d.png" % int(i / 10))
	var z_range := zmax - zmin
	print("WALK z_range=", snapped(z_range, 0.01), " foot_y=", snapped(ymin, 0.01), "..", snapped(ymax, 0.01))

	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.2, 1.5, -2.5)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	anim.play("1H_Melee_Attack_Chop")
	for i in 18:
		await process_frame
		if i % 6 == 0:
			vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KAYKIT_attack_%d.png" % int(i / 6))

	anim.play("Blocking")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/KAYKIT_block.png")

	## Allow a little step lift; fail only if the whole body skates high.
	var ok := z_range > 0.15 and ymin < 0.2 and sword != null and shield != null
	print("KAYKIT_HERO_DONE OK=", ok, " z_range=", snapped(z_range, 0.01), " foot_ymin=", snapped(ymin, 0.01))
	vp.queue_free()
	quit(0 if ok else 1)


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
