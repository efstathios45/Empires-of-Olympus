extends SceneTree



func _init() -> void :
	call_deferred("_run")


func _run() -> void :
	var root: = get_root()
	var world: = Node3D.new()
	root.add_child(world)

	var vp: = SubViewport.new()
	vp.size = Vector2i(640, 640)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage: = Node3D.new()
	vp.add_child(stage)

	var light: = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 35, 0)
	light.light_energy = 1.4
	stage.add_child(light)
	var fill: = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -120, 0)
	fill.light_energy = 0.5
	stage.add_child(fill)

	var cam: = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	stage.add_child(cam)
	await process_frame

	var pivot: = Node3D.new()
	stage.add_child(pivot)


	var glb: = "res://assets/characters/spartan_hoplite/spartan_hoplite.glb"
	var libp: = "res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres"
	var model: Node3D = load(glb).instantiate()
	pivot.add_child(model)
	print("RAW_ROT=", model.rotation, " RAW_SCALE=", model.scale)
	ModelUtils.setup_character_for_movement(model, 1.85)
	print("AFTER_SETUP_ROT=", model.rotation, " SCALE=", model.scale, " POS=", model.position)
	var anim: = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim and ResourceLoader.exists(libp):
		var lib: = load(libp) as AnimationLibrary
		if lib:
			if anim.has_animation_library(""):
				anim.remove_animation_library("")
			anim.add_animation_library("", lib)
		ModelUtils.set_animation_loops(anim)
		if anim.has_animation("ual1_Idle"):
			anim.play("ual1_Idle")
	await process_frame
	await process_frame


	var aabb: = _aabb(model)
	print("AABB_CENTER=", aabb.get_center(), " SIZE=", aabb.size, " MIN_Y=", aabb.position.y)


	cam.position = Vector3(3.2, 1.1, 0.0)
	cam.look_at_from_position(cam.position, Vector3(0, 0.95, 0), Vector3.UP)
	await process_frame
	await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	var img: Image = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/orient_hero_side.png")


	cam.position = Vector3(0.0, 1.1, 3.2)
	cam.look_at_from_position(cam.position, Vector3(0, 0.95, 0), Vector3.UP)
	await process_frame
	await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	img = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/orient_hero_front.png")


	var npc_bad: Node3D = load(glb).instantiate()
	pivot.add_child(npc_bad)
	npc_bad.position = Vector3(2.5, 0, 0)
	ModelUtils.setup_character_for_movement(npc_bad, 1.85)
	npc_bad.rotation.y = 0.0
	print("NPC_BAD_ROT=", npc_bad.rotation)

	var npc_good: Node3D = load(glb).instantiate()
	pivot.add_child(npc_good)
	npc_good.position = Vector3(-2.5, 0, 0)
	var base: = npc_good.rotation.y
	ModelUtils.setup_character_for_movement(npc_good, 1.85)
	npc_good.rotation.y = base + 0.0
	print("NPC_GOOD_ROT=", npc_good.rotation, " base=", base)

	model.visible = false
	cam.position = Vector3(0.0, 1.1, 6.0)
	cam.size = 5.0
	cam.look_at_from_position(cam.position, Vector3(0, 0.95, 0), Vector3.UP)
	await process_frame
	await process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	img = vp.get_texture().get_image()
	img.save_png("/opt/cursor/artifacts/orient_npc_compare.png")

	print("CAPTURE_ORIENT_OK")
	quit(0)


func _aabb(node: Node3D) -> AABB:
	var combined: = AABB()
	var first: = true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi: = child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var a: AABB = mi.global_transform * mi.get_aabb()
		if first:
			combined = a
			first = false
		else:
			combined = combined.merge(a)
	return combined
