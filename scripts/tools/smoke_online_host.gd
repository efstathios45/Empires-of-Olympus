extends SceneTree
## Smoke: address parsing + leg plant + pending join.

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
	var msg: String = net.set_pending_join("1.2.3.4:7778", "Friend World")
	assert(net.pending_join_address == "1.2.3.4")
	assert(net.pending_join_port == 7778)
	assert(msg.contains("Friend World"))
	assert(not msg.contains("1.2.3.4"), "pending join message must not show raw IP")
	net.clear_pending_join()
	assert(net.pending_join_address == "")

	var m: Node3D = load("res://assets/characters/spartan_hoplite/spartan_hoplite.glb").instantiate()
	get_root().add_child(m)
	ModelUtils.setup_character_for_movement(m, 1.85)
	var skel: Skeleton3D
	for n in m.find_children("*", "Skeleton3D", true, false):
		skel = n
		break
	assert(skel != null and skel.has_node("LegPlantFix"))
	print("SMOKE_ONLINE_HOST_OK")
	quit(0)
