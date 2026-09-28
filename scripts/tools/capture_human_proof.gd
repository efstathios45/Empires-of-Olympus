extends SceneTree
## Capture REST (no anim) and IDLE from FRONT and 3/4 elevated — prove human shape.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var root := get_root()
	var vp := SubViewport.new()
	vp.size = Vector2i(720, 900)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.66, 0.70)
	env.environment = e
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 40, 0)
	light.light_energy = 1.45
	stage.add_child(light)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.3, 0.45, 0.28)
	floor.material_override = fm
	stage.add_child(floor)

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	stage.add_child(m)
	print("IMPORT_ROT=", m.rotation, " SCALE=", m.scale)
	ModelUtils.setup_character_for_movement(m, 1.85)
	print("AFTER_SETUP_ROT=", m.rotation, " SCALE=", m.scale)
	## Ensure no SkyGazeFix
	for n in m.find_children("*", "Skeleton3D", true, false):
		var fix = n.get_node_or_null("SkyGazeFix")
		if fix:
			fix.free()
			print("REMOVED_FIX")
		print("SKEL_SCALE=", n.scale, " SKEL_ROT=", n.rotation)
		for c in n.get_children():
			if c is MeshInstance3D:
				print("MESH=", c.name, " scale=", c.scale)

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

	## REST — front eye-level
	anim.stop()
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	skel.reset_bone_poses()
	for i in 15:
		await process_frame
	## Character faces -Z after import PI yaw... import sets +PI so faces -Z.
	## Camera in front: at -Z looking toward origin.
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 35.0
	cam.position = Vector3(0.0, 1.15, -3.2)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	_snap(vp, "HUMAN_rest_front")

	## REST — elevated Metin2 behind
	cam.position = Vector3(0.0, 2.6, 4.8)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	_snap(vp, "HUMAN_rest_metin2")

	## IDLE — same views
	anim.play("ual1_Idle")
	for i in 30:
		await process_frame
	cam.position = Vector3(0.0, 1.15, -3.2)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	_snap(vp, "HUMAN_idle_front")

	cam.position = Vector3(0.0, 2.6, 4.8)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	_snap(vp, "HUMAN_idle_metin2")

	## 3/4 front elevated idle — classic character showcase
	cam.position = Vector3(-2.2, 1.6, -2.8)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	_snap(vp, "HUMAN_idle_threequarter")

	print("HUMAN_CAPTURE_OK")
	quit(0)


func _snap(vp: SubViewport, name: String) -> void:
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	vp.get_texture().get_image().save_png("/opt/cursor/artifacts/%s.png" % name)
	print("SAVED ", name)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
