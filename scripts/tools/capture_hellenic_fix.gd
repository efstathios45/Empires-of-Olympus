extends SceneTree
## Proof: Quaternius+GreekLook hero — arms, grips, Walk faces MODEL_FRONT (-Z).


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	var HeroAnim = load("res://scripts/utils/hero_anim.gd")

	var vp := _stage(900, 900)
	var stage: Node3D = vp.get_child(0)

	var hero: Node3D = load("res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb").instantiate()
	hero.name = "guard_adventurer"
	stage.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	GreekLook.apply(hero, "hoplite")
	var anim := hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	assert(hero.find_child("LegPlantFix", true, false) == null)

	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp:
		GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh:
		GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")

	## Marker: red arrow along MODEL_FRONT (-Z) in front of the hero.
	var arrow := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 1.2)
	arrow.mesh = box
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.9, 0.15, 0.1)
	arrow.material_override = amat
	stage.add_child(arrow)
	arrow.position = Vector3(0.0, 1.1, -1.4)

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36

	## Front-ish: see face + spear + shield + forward arrow.
	cam.position = Vector3(2.2, 1.5, 3.4)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	HeroAnim.play(anim, "idle")
	for i in 16:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_idle_front.png")

	## Walk — feet should advance toward the red arrow (-Z), not away.
	HeroAnim.play(anim, "walk")
	for i in 24:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_walk_front.png")

	## Side view of walk (camera from +X): nose toward -Z (left of frame).
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	cam.position = Vector3(3.8, 1.15, 0.0)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 20:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_walk_side.png")

	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 36
	cam.position = Vector3(2.2, 1.5, 3.4)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	HeroAnim.play(anim, "attack_1")
	for i in 14:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_attack.png")

	HeroAnim.play(anim, "block")
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/HELLFIX_block.png")

	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var wr := skel.get_bone_global_pose(skel.find_bone("Wrist.R")).origin
	var wl := skel.get_bone_global_pose(skel.find_bone("Wrist.L")).origin
	print("HELLFIX wrists R=", wr, " L=", wl, " plant=false")
	print("HELLFIX arms_ok=", wr.y > 0.6 and wl.y > 0.6)
	print("HELLFIX_OK")
	quit()


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
	e.background_color = Color(0.55, 0.62, 0.70)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.70, 0.64)
	e.ambient_light_energy = 0.8
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 35, 0)
	light.light_energy = 1.3
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(16, 16)
	floor_mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.64, 0.50)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
