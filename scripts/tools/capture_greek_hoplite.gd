extends SceneTree
func _init():
	call_deferred("run")

func run() -> void:
	var vp := _stage(700, 900)
	var stage: Node3D = vp.get_child(0)
	var m: Node3D = load("res://assets/characters/greek_hoplite/greek_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim := m.find_child("AnimationPlayer", true) as AnimationPlayer
	ModelUtils.set_animation_loops(anim)
	var GearGrip = load("res://scripts/gear_grip.gd")
	GearGrip.attach_weapon(m, "res://assets/props/weapons/dory_spear.glb")
	GearGrip.attach_shield(m, "res://assets/props/gear/aspis_shield.glb")
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 36
	cam.position = Vector3(2.3, 1.4, 3.2)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	anim.play("Idle_Neutral")
	for i in 14: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEK_idle.png")
	anim.play("Walk")
	for i in 20: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEK_walk.png")
	anim.play("Sword_Slash")
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEK_slash.png")
	anim.play("Idle_Sword")
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEK_block.png")
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	cam.position = Vector3(3.5, 1.1, 0.05)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	anim.play("Idle_Neutral")
	for i in 10: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/GREEK_side.png")
	print("GREEK_PROOF plant=", m.find_child("LegPlantFix", true, false) != null)
	print("GREEK_PROOF_OK")
	quit()

func _stage(w, h) -> SubViewport:
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
	e.background_color = Color(0.5, 0.56, 0.62)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65, 0.66, 0.7)
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.25
	stage.add_child(light)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.4, 0.34)
	floor_mi.material_override = mat
	stage.add_child(floor_mi)
	return vp
