extends SceneTree
## Proof: facing, crimson sleeves, Corinthian, spear/shield after facing+paint fix.
func _init(): call_deferred("run")

func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")

	var vp := SubViewport.new()
	vp.size = Vector2i(900, 1100)
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
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 0.95
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, 32, 0)
	light.light_energy = 1.35
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14, 14)
	floor_mi.mesh = plane
	stage.add_child(floor_mi)
	## Green stripe along MODEL_FRONT (−Z)
	var stripe := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.025, 7.0)
	stripe.mesh = box
	stripe.position = Vector3(0, 0.015, -3.5)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.12, 0.85, 0.28)
	stripe.material_override = sm
	stage.add_child(stripe)

	var wrap := Node3D.new()
	wrap.name = "MeshRoot"
	stage.add_child(wrap)
	var hero: Node3D = load("res://assets/characters/quaternius_hero_king/hero_king.glb").instantiate()
	wrap.add_child(hero)
	ModelUtils.setup_character_for_movement(hero, 1.85)
	print("quat_facing_meta=", hero.has_meta("eoo_quat_facing"))
	var arm = hero.find_child("CharacterArmature", true, false)
	print("armature.yaw=", arm.rotation.y if arm else "null")
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")

	## Orient like player mesh_root for move toward −Z
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 32

	## FACE cam: stand at −Z looking +Z — must show FACE (nose/crest forward)
	anim.play("Idle_Neutral")
	cam.position = Vector3(0.9, 1.45, -3.3)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 28: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_face.png")
	print("PROOF_face saved")

	## BACK cam: at +Z — must show BACK
	cam.position = Vector3(0.9, 1.45, 3.3)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 16: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_back.png")

	## Walk face + side
	anim.play("Walk")
	cam.position = Vector3(0.9, 1.45, -3.3)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 24: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_walk_face.png")
	cam.position = Vector3(3.2, 1.35, -0.4)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 16: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_walk_side.png")

	## Attack
	anim.play("Sword_Slash")
	anim.seek(0.35, true)
	cam.position = Vector3(1.2, 1.4, -3.0)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 16: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/PROOF_slash.png")

	## Wrist heights (arms raised = good)
	var skel: Skeleton3D = hero.find_child("Skeleton3D", true, false)
	var wr = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.R"))
	var wl = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Wrist.L"))
	print("wrists R=", wr.origin, " L=", wl.origin)
	print("PROOF_OK")
	quit()
