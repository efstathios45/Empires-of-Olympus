extends SceneTree
func _init(): call_deferred("run")
func run():
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var GearGrip = load("res://scripts/gear_grip.gd")
	var GearPaint = load("res://scripts/gear_paint.gd")
	for path_tag in [
		["res://assets/characters/quaternius_hero_king/hero_king.glb", "king"], 
		["res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb", "adv"], 
		["res://assets/characters/quaternius_guard_soldier_f/guard_soldier_f.glb", "sol"], 
	]:
		await shot(path_tag[0], path_tag[1], GreekLook, GearGrip, GearPaint)
	print("ADV_OK")
	quit()
func shot(path, tag, GreekLook, GearGrip, GearPaint) -> void :
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
	light.light_energy = 1.3
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
	GreekLook.apply(hero, "hoplite")
	var anim = hero.find_child("AnimationPlayer", true) as AnimationPlayer
	var wp = GearGrip.attach_weapon(hero, "res://assets/props/weapons/dory_spear.glb")
	var sh = GearGrip.attach_shield(hero, "res://assets/props/gear/aspis_shield.glb")
	if wp: GearPaint.paint_attached(wp, "res://assets/props/weapons/dory_spear.glb")
	if sh: GearPaint.paint_attached(sh, "res://assets/props/gear/aspis_shield.glb")
	wrap.rotation.y = ModelUtils.yaw_from_direction(Vector3(0, 0, -1))
	anim.play("Walk")
	var cam: = Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 30
	cam.position = Vector3(1.1, 1.4, -3.0)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	for i in 24: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/CMP_%s_walk.png" % tag)
	cam.position = Vector3(2.9, 1.3, -0.2)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	for i in 12: await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/CMP_%s_side.png" % tag)
	print("saved ", tag)
	vp.queue_free()
	await process_frame
