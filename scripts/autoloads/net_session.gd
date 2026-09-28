extends Node
## NetSession — lightweight ENet lobby for shared Hellas presence + PvP.
## Host / Join from the Esc rest menu. Each peer keeps a local world copy and
## mirrors remote champions as RemoteAvatar nodes.

signal session_changed
signal peer_avatar_spawned(peer_id: int)
signal peer_avatar_removed(peer_id: int)

const DEFAULT_PORT := 7777
const SYNC_HZ := 12.0

var _avatars: Dictionary = {}  # peer_id -> RemoteAvatar
var _sync_accum: float = 0.0
var _status: String = "Solo"


func status_text() -> String:
	return _status


func is_online() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func host(port: int = DEFAULT_PORT) -> String:
	disconnect_session()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 8)
	if err != OK:
		_status = "Host failed (%s)" % error_string(err)
		session_changed.emit()
		return _status
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	_status = "Hosting on port %d" % port
	_announce("Arena open on port %d — rivals may Join." % port)
	session_changed.emit()
	return _status


func join(address: String, port: int = DEFAULT_PORT) -> String:
	disconnect_session()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), port)
	if err != OK:
		_status = "Join failed (%s)" % error_string(err)
		session_changed.emit()
		return _status
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	_status = "Connecting to %s:%d…" % [address, port]
	session_changed.emit()
	return _status


func disconnect_session() -> void:
	_clear_avatars()
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer != null:
		if multiplayer.peer_connected.is_connected(_on_peer_connected):
			multiplayer.peer_connected.disconnect(_on_peer_connected)
		if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
			multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
		if multiplayer.connected_to_server.is_connected(_on_connected_ok):
			multiplayer.connected_to_server.disconnect(_on_connected_ok)
		if multiplayer.connection_failed.is_connected(_on_connected_fail):
			multiplayer.connection_failed.disconnect(_on_connected_fail)
		if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
			multiplayer.server_disconnected.disconnect(_on_server_disconnected)
		multiplayer.multiplayer_peer = null
	_status = "Solo"
	session_changed.emit()


func _wire_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_ok):
		multiplayer.connected_to_server.connect(_on_connected_ok)
	if not multiplayer.connection_failed.is_connected(_on_connected_fail):
		multiplayer.connection_failed.connect(_on_connected_fail)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_connected_ok() -> void:
	_status = "Joined arena"
	_announce("Joined the arena. Rivals of other empires can be fought.")
	_hello.rpc(_identity())
	session_changed.emit()


func _on_connected_fail() -> void:
	_status = "Join failed"
	disconnect_session()


func _on_server_disconnected() -> void:
	_announce("Host closed the arena.")
	disconnect_session()


func _on_peer_connected(id: int) -> void:
	## Tell the newcomer who we are; they will hello back / host broadcasts.
	_hello.rpc_id(id, _identity())
	if multiplayer.is_server():
		_status = "Hosting — %d rival(s)" % maxi(0, multiplayer.get_peers().size())
		session_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	_remove_avatar(id)
	_announce("A champion left the arena.")
	if multiplayer.is_server():
		_status = "Hosting — %d rival(s)" % multiplayer.get_peers().size()
		session_changed.emit()


func _identity() -> Dictionary:
	return {
		"name": String(GameState.player_name),
		"empire": String(GameState.empire),
		"level": int(GameState.level),
		"hp": _local_hp(),
		"max_hp": float(GameState.max_hp()),
	}


func _local_player() -> Node:
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_in_group("remote_player"):
			continue
		if p.is_multiplayer_authority() or not is_online():
			return p
	return get_tree().get_first_node_in_group("player")


func _local_hp() -> float:
	var p := _local_player()
	if p != null and "hp" in p:
		return float(p.hp)
	return float(GameState.max_hp())


@rpc("any_peer", "reliable")
func _hello(data: Dictionary) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0 or id == multiplayer.get_unique_id():
		return
	_spawn_or_update_avatar(id, data)
	## Reply so the greeter also sees us.
	_hello_ack.rpc_id(id, _identity())


@rpc("any_peer", "reliable")
func _hello_ack(data: Dictionary) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		return
	_spawn_or_update_avatar(id, data)


func _spawn_or_update_avatar(id: int, data: Dictionary) -> void:
	var world := get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var av: Node = _avatars.get(id)
	if av == null or not is_instance_valid(av):
		var RemoteAvatar := load("res://scripts/remote_avatar.gd")
		av = CharacterBody3D.new()
		av.set_script(RemoteAvatar)
		av.call("setup", id,
			String(data.get("name", "Champion")),
			String(data.get("empire", "sparta")),
			int(data.get("level", 1)))
		world.add_child(av)
		var anchor := Vector3(2.0 * float(id % 5), 0.0, 2.0)
		if world.has_method("get_respawn_point"):
			var rp: Vector3 = world.get_respawn_point()
			anchor = rp + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
			anchor.y = world.sample_height(anchor.x, anchor.z) + 1.0 if world.has_method("sample_height") else rp.y
		av.global_position = anchor
		_avatars[id] = av
		peer_avatar_spawned.emit(id)
		_announce("%s of %s entered the field." % [
			String(data.get("name", "Champion")),
			String(data.get("empire", "?")).capitalize()])
	else:
		av.call("setup", id,
			String(data.get("name", "Champion")),
			String(data.get("empire", "sparta")),
			int(data.get("level", 1)))
		if av.has_node("PlayerNameplate") or av.get("_nameplate"):
			var plate = av.get("_nameplate")
			if plate:
				plate.call("set_plate", String(data.get("name", "Champion")),
					int(data.get("level", 1)), String(data.get("empire", "sparta")))


func _remove_avatar(id: int) -> void:
	var av: Node = _avatars.get(id)
	if av != null and is_instance_valid(av):
		av.queue_free()
	_avatars.erase(id)
	peer_avatar_removed.emit(id)


func _clear_avatars() -> void:
	for id in _avatars.keys():
		_remove_avatar(int(id))
	_avatars.clear()


func _process(delta: float) -> void:
	if not is_online():
		return
	_sync_accum += delta
	if _sync_accum < 1.0 / SYNC_HZ:
		return
	_sync_accum = 0.0
	var p := _local_player()
	if p == null or not (p is Node3D):
		return
	if p.is_in_group("remote_player"):
		return
	var moving := Vector2(p.velocity.x, p.velocity.z).length() > 0.2 if "velocity" in p else false
	var yaw := 0.0
	if p.get("mesh_root") != null:
		yaw = float((p.mesh_root as Node3D).rotation.y)
	_state_sync.rpc(
		(p as Node3D).global_position,
		yaw,
		float(p.hp) if "hp" in p else 100.0,
		float(GameState.max_hp()),
		int(GameState.level),
		moving,
		String(GameState.empire),
		String(GameState.player_name)
	)


@rpc("any_peer", "unreliable_ordered")
func _state_sync(pos: Vector3, yaw: float, hp: float, max_hp: float, level: int, moving: bool, empire: String, p_name: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		return
	var av: Node = _avatars.get(id)
	if av == null or not is_instance_valid(av):
		_spawn_or_update_avatar(id, {"name": p_name, "empire": empire, "level": level})
		av = _avatars.get(id)
	if av != null and av.has_method("apply_state"):
		av.call("apply_state", pos, yaw, hp, max_hp, level, moving)


func request_damage(target_peer: int, amount: float, from_pos: Vector3) -> void:
	if not is_online():
		return
	_rpc_damage.rpc_id(target_peer, amount, from_pos, multiplayer.get_unique_id())


@rpc("any_peer", "reliable")
func _rpc_damage(amount: float, from_pos: Vector3, attacker_peer: int) -> void:
	var p := _local_player()
	if p == null or not p.has_method("take_pvp_damage"):
		return
	p.call("take_pvp_damage", amount, from_pos, attacker_peer)


func notify_death_loot(drop_ids: Array, at: Vector3) -> void:
	if is_online():
		_rpc_spawn_loot.rpc(drop_ids, at)
	else:
		_spawn_loot_local(drop_ids, at)


@rpc("any_peer", "reliable", "call_local")
func _rpc_spawn_loot(drop_ids: Array, at: Vector3) -> void:
	_spawn_loot_local(drop_ids, at)


func _spawn_loot_local(drop_ids: Array, at: Vector3) -> void:
	var world := get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var LootPickup := load("res://scripts/loot_pickup.gd")
	if LootPickup == null:
		return
	for id in drop_ids:
		var loot_id := String(id)
		if loot_id == "":
			continue
		var drop: Node = LootPickup.new()
		world.add_child(drop)
		if drop.has_method("setup"):
			drop.call("setup", loot_id, at + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6)), 0)


func _announce(msg: String) -> void:
	if ChatSystem:
		ChatSystem.call("_push_system", msg)
