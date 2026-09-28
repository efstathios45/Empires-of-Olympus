extends SceneTree
## Measure silhouette aspect for several anims on hoplite (nosil import).


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var clips := ["ual1_Idle", "ual1_Sword_Idle", "ual1_Walk", "ual1_Sprint", "ual1_Sword_Attack_Standing"]
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

	## REST baseline
	anim.stop()
	skel.reset_bone_poses()
	for i in 10:
		await process_frame
	_report("REST", skel, vp)

	for clip in clips:
		if not lib.has_animation(clip):
			print("MISSING ", clip)
			continue
		anim.play(clip)
		for i in 24:
			await process_frame
		_report(clip, skel, vp)
		vp.get_texture().get_image().save_png("/opt/cursor/artifacts/ANIM_%s_side.png" % clip)
	print("ANIM_ASPECTS_OK")
	quit(0)


func _report(tag: String, skel: Skeleton3D, vp: SubViewport) -> void:
	var hi := skel.find_bone("Head")
	var hips := skel.find_bone("Hips")
	var lt := skel.find_bone("LeftUpperLeg")
	var lk := skel.find_bone("LeftLowerLeg")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var hp := skel.global_transform * skel.get_bone_global_pose(hips)
	var col := (ht.origin - hp.origin).normalized()
	var thigh := 0.0
	if lt >= 0 and lk >= 0:
		var a := (skel.global_transform * skel.get_bone_global_pose(lt)).origin
		var b := (skel.global_transform * skel.get_bone_global_pose(lk)).origin
		thigh = a.distance_to(b)
	print("CLIP=", tag, " UPRIGHT=", col.dot(Vector3.UP), " THIGH=", thigh, " HIPS_Y=", hp.origin.y)
