extends Node
## NetSession — internet-ready ENet lobby for shared Hellas presence + PvP.
## Host opens UDP (UPnP when possible); friends Join with IP:port invite.
## Each peer keeps a local world copy and mirrors remote champions.

signal session_changed
signal peer_avatar_spawned(peer_id: int)
signal peer_avatar_removed(peer_id: int)
signal invite_ready(invite: String)

const DEFAULT_PORT := 7777
const SYNC_HZ := 12.0
const PUBLIC_IP_URL := "https://api.ipify.org"

var _avatars: Dictionary = {}  # peer_id -> RemoteAvatar
var _sync_accum: float = 0.0
var _status: String = "Solo"
var _host_port: int = DEFAULT_PORT
var _invite: String = ""
var _public_ip: String = ""
var _upnp: UPNP
var _upnp_mapped: bool = false
var _http: HTTPRequest
## Set before loading game_world to auto-join after spawn.
var pending_join_address: String = ""
var pending_join_port: int = DEFAULT_PORT


func status_text() -> String:
	return _status


func invite_text() -> String:
	return _invite


func is_online() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_hosting() -> bool:
	return is_online() and multiplayer.is_server()


## Parse "host", "host:port" → {address, port}.
func parse_address(raw: String, default_port: int = DEFAULT_PORT) -> Dictionary:
	var s := raw.strip_edges().replace(" ", "")
	if s.is_empty():
		return {"address": "", "port": default_port}
	s = s.trim_prefix("http://").trim_prefix("https://")
	var port := default_port
	var host := s
	if s.contains(":"):
		var parts := s.rsplit(":", true, 1)
		host = parts[0]
		if parts.size() > 1 and String(parts[1]).is_valid_int():
			port = clampi(int(parts[1]), 1, 65535)
	return {"address": host, "port": port}


func set_pending_join(raw: String) -> String:
	var parsed := parse_address(raw)
	if String(parsed.address).is_empty():
		pending_join_address = ""
		return "Enter a host IP or invite (ip:port)."
	pending_join_address = String(parsed.address)
	pending_join_port = int(parsed.port)
	return "Will join %s:%d after you enter the world." % [pending_join_address, pending_join_port]


func clear_pending_join() -> void:
	pending_join_address = ""
	pending_join_port = DEFAULT_PORT


## Call from game_world after the local player exists.
func try_pending_join() -> String:
	if pending_join_address == "":
		return ""
	var addr := pending_join_address
	var port := pending_join_port
	clear_pending_join()
	return join(addr, port)


func host(port: int = DEFAULT_PORT) -> String:
	disconnect_session()
	_host_port = port
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 8)
	if err != OK:
		_status = "Host failed (%s)" % error_string(err)
		session_changed.emit()
		return _status
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	_invite = "0.0.0.0:%d" % port
	_status = "Hosting on port %d — fetching public IP…" % port
	_announce("World open on port %d — share your invite with friends." % port)
	session_changed.emit()
	_begin_invite_discovery(port)
	return _status


func join(address: String, port: int = DEFAULT_PORT) -> String:
	disconnect_session()
	var parsed := parse_address(address, port)
	var host_addr := String(parsed.address)
	var host_port := int(parsed.port)
	if host_addr.is_empty():
		_status = "Join failed — empty address"
		session_changed.emit()
		return _status
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host_addr, host_port)
	if err != OK:
		_status = "Join failed (%s)" % error_string(err)
		session_changed.emit()
		return _status
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	_status = "Connecting to %s:%d…" % [host_addr, host_port]
	session_changed.emit()
	return _status


func disconnect_session() -> void:
	_clear_avatars()
	_release_upnp()
	_invite = ""
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


func _begin_invite_discovery(port: int) -> void:
	_try_upnp(port)
	_fetch_public_ip()


func _try_upnp(port: int) -> void:
	_upnp = UPNP.new()
	var disc := _upnp.discover(2000, 2, "InternetGatewayDevice")
	if disc != UPNP.UPNP_RESULT_SUCCESS:
		disc = _upnp.discover(2000, 2, "")
	if disc != UPNP.UPNP_RESULT_SUCCESS:
		return
	if _upnp.get_gateway() == null or not _upnp.get_gateway().is_valid_gateway():
		return
	var map_err := _upnp.add_port_mapping(port, port, "EmpiresOfOlympus", "UDP")
	if map_err != UPNP.UPNP_RESULT_SUCCESS:
		map_err = _upnp.add_port_mapping(port, port, "", "UDP")
	_upnp_mapped = map_err == UPNP.UPNP_RESULT_SUCCESS
	var ext := _upnp.query_external_address()
	if ext != "" and not ext.begins_with("0."):
		_public_ip = ext
		_set_invite("%s:%d" % [_public_ip, port])


func _release_upnp() -> void:
	if _upnp != null and _upnp_mapped:
		_upnp.delete_port_mapping(_host_port, "UDP")
	_upnp = null
	_upnp_mapped = false


func _fetch_public_ip() -> void:
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 8.0
		add_child(_http)
		_http.request_completed.connect(_on_public_ip)
	var err := _http.request(PUBLIC_IP_URL)
	if err != OK and _invite.begins_with("0.0.0.0"):
		_set_invite("localhost:%d" % _host_port)


func _on_public_ip(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		if _invite.begins_with("0.0.0.0"):
			_set_invite("localhost:%d" % _host_port)
		return
	var ip := body.get_string_from_utf8().strip_edges()
	if ip.is_empty() or not ip.contains("."):
		return
	_public_ip = ip
	_set_invite("%s:%d" % [_public_ip, _host_port])


func _set_invite(invite: String) -> void:
	_invite = invite
	var upnp_note := " (UPnP open)" if _upnp_mapped else ""
	_status = "Hosting — invite %s%s" % [_invite, upnp_note]
	_announce("Invite friends with: %s" % _invite)
	invite_ready.emit(_invite)
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
	_status = "Joined %s" % (_invite if _invite != "" else "host")
	_announce("Joined the world. Rivals of other empires can be fought.")
	_hello.rpc(_identity())
	session_changed.emit()


func _on_connected_fail() -> void:
	_status = "Join failed — check IP/port & firewall"
	disconnect_session()


func _on_server_disconnected() -> void:
	_announce("Host closed the world.")
	disconnect_session()


func _on_peer_connected(id: int) -> void:
	_hello.rpc_id(id, _identity())
	if multiplayer.is_server():
		var base := _invite if _invite != "" else ("port %d" % _host_port)
		_status = "Hosting %s — %d rival(s)" % [base, maxi(0, multiplayer.get_peers().size())]
		session_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	_remove_avatar(id)
	_announce("A champion left the world.")
	if multiplayer.is_server():
		var base := _invite if _invite != "" else ("port %d" % _host_port)
		_status = "Hosting %s — %d rival(s)" % [base, multiplayer.get_peers().size()]
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
