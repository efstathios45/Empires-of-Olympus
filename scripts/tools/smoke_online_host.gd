extends SceneTree
## Smoke: address parsing + sky-gaze dampen + pending join.

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var net := get_root().get_node_or_null("NetSession")
	assert(net != null)
	var p1: Dictionary = net.parse_address("203.0.113.9:7777")
	assert(String(p1.address) == "203.0.113.9")
	assert(int(p1.port) == 7777)
	var p2: Dictionary = net.parse_address("192.168.1.5")
	assert(String(p2.address) == "192.168.1.5")
	assert(int(p2.port) == 7777)
	var p3: Dictionary = net.parse_address("http://10.0.0.2:9000")
	assert(String(p3.address) == "10.0.0.2")
	assert(int(p3.port) == 9000)
	var msg: String = net.set_pending_join("1.2.3.4:7778")
	assert(net.pending_join_address == "1.2.3.4")
	assert(net.pending_join_port == 7778)
	assert(msg.contains("1.2.3.4"))
	net.clear_pending_join()
	assert(net.pending_join_address == "")

	## Sky gaze: idle look-up must collapse with the dampener.
	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		m.add_child(anim)
	var lib := load("res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres") as AnimationLibrary
	if anim.has_animation_library(""):
		anim.remove_animation_library("")
	anim.add_animation_library("", lib)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert(skel != null and skel.has_node("SkyGazeFix"))
	anim.process_priority = -100
	skel.get_node("SkyGazeFix").process_priority = 1000
	anim.play("ual1_Idle")
	for i in 20:
		await process_frame
	var hi := skel.find_bone("Head")
	var chest := skel.find_bone("UpperChest")
	var ht := skel.global_transform * skel.get_bone_global_pose(hi)
	var ct := skel.get_bone_pose(chest)
	var fwd_up: float = (-ht.basis.z).normalized().dot(Vector3.UP)
	var chest_pitch: float = ct.basis.get_euler().x
	print("SMOKE_FWD_UP=", fwd_up, " CHEST_PITCH=", rad_to_deg(chest_pitch))
	assert(absf(fwd_up) < 0.08, "head not level: %s" % fwd_up)
	assert(absf(chest_pitch) < 0.15, "chest still pitched: %s" % chest_pitch)
	print("SMOKE_ONLINE_HOST_OK")
	quit(0)
