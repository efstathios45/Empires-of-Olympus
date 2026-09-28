extends SceneTree
## Side-by-side REST vs IDLE for candidate hero meshes.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var candidates := [
		["hoplite", "res://assets/characters/spartan_hoplite/spartan_hoplite.glb", "res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres", 1.85],
		["woman", "res://assets/characters/citizen_woman/citizen_woman.glb", "res://assets/characters/citizen_woman/citizen_woman_animations.tres", 1.68],
		["blacksmith", "res://assets/characters/blacksmith_npc/blacksmith_npc.glb", "res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres", 1.85],
		["merchant", "res://assets/characters/citizen_merchant/citizen_merchant.glb", "res://assets/characters/citizen_merchant/citizen_merchant_animations.tres", 1.8],
	]
	for c in candidates:
		await _capture_one(String(c[0]), String(c[1]), String(c[2]), float(c[3]))
	print("MESH_COMPARE_OK")
	quit(0)


func _capture_one(tag: String, glb: String, lib_path: String, height: float) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 800)
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

	var m: Node3D = load(glb).instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, height)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load(lib_path) as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)

	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.35
	cam.position = Vector3(3.4, 1.05, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	anim.stop()
	skel.reset_bone_poses()
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/CMP_%s_REST_side.png" % tag)
	print("SAVED CMP_%s_REST_side.png" % tag)

	var idle := "ual1_Idle"
	if not lib.has_animation(idle):
		idle = lib.get_animation_list()[0]
	anim.play(idle)
	for i in 28:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/CMP_%s_IDLE_side.png" % tag)
	print("SAVED CMP_%s_IDLE_side.png clip=", idle)

	## front 3/4 idle
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.0, 1.55, -2.6)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/CMP_%s_IDLE_front.png" % tag)
	print("SAVED CMP_%s_IDLE_front.png" % tag)

	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	var col := (ht.origin - hp.origin).normalized()
	print("TAG=", tag, " UPRIGHT=", col.dot(Vector3.UP), " SLOPE=", Vector2(col.x, col.z).length())

	vp.queue_free()
	await process_frame
