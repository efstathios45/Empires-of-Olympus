extends SceneTree
## Capture current hoplite import variant (tag via env or default).


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var tag := "nosil"
	if OS.get_environment("HOPLITE_TAG") != "":
		tag = OS.get_environment("HOPLITE_TAG")
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

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
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
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/FIX_%s_REST_side.png" % tag)
	print("SAVED REST tag=", tag)

	anim.play("ual1_Idle")
	for i in 28:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/FIX_%s_IDLE_side.png" % tag)
	print("SAVED IDLE tag=", tag)

	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 40
	cam.position = Vector3(-2.0, 1.55, -2.6)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/FIX_%s_IDLE_front.png" % tag)

	## Metin2 behind
	cam.position = Vector3(0.0, 2.5, 5.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	for i in 8:
		await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/FIX_%s_IDLE_behind.png" % tag)

	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var lt := skel.find_bone("LeftUpperLeg")
	var rt := skel.find_bone("RightUpperLeg")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	var col := (ht.origin - hp.origin).normalized()
	print("UPRIGHT=", col.dot(Vector3.UP), " SLOPE=", Vector2(col.x, col.z).length())
	if lt >= 0 and rt >= 0:
		var lto := (skel.global_transform * skel.get_bone_global_pose(lt)).origin
		var rto := (skel.global_transform * skel.get_bone_global_pose(rt)).origin
		print("LEG_SPREAD=", lto.distance_to(rto), " LEG_Y=", lto.y, rto.y)
	## thigh lengths
	var lk := skel.find_bone("LeftLowerLeg")
	if lt >= 0 and lk >= 0:
		var a := (skel.global_transform * skel.get_bone_global_pose(lt)).origin
		var b := (skel.global_transform * skel.get_bone_global_pose(lk)).origin
		print("THIGH_LEN=", a.distance_to(b))
	print("VARIANT_OK tag=", tag)
	quit(0)
