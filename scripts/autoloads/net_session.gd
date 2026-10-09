extends Node




signal session_changed
signal peer_avatar_spawned(peer_id: int)
signal peer_avatar_removed(peer_id: int)
signal invite_ready(invite: String)

const DEFAULT_PORT: = 7777
const SYNC_HZ: = 12.0
const PUBLIC_IP_URL: = "https://api.ipify.org"

var _avatars: Dictionary = {}
var _sync_accum: float = 0.0
var _status: String = "Solo"
var _host_port: int = DEFAULT_PORT
var _invite: String = ""
var _public_ip: String = ""
var _server_name: String = "Hellas World"
var _join_label: String = ""
var _seen_peer_ips: Dictionary = {}
var _upnp: UPNP
var _upnp_mapped: bool = false
var _http: HTTPRequest

var pending_join_address: String = ""
var pending_join_port: int = DEFAULT_PORT
var pending_join_name: String = ""

## Host-authoritative world mobs (net_id -> Node)
var _world_mobs: Dictionary = {}
var _next_mob_id: int = 1
var _enemy_sync_accum: float = 0.0


func status_text() -> String:
	return _status


func invite_text() -> String:

	if not is_hosting():
		return ""
	return _invite


func server_name() -> String:
	return _server_name


func is_online() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	var peer: = multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_hosting() -> bool:
	return is_online() and multiplayer.is_server()



func parse_address(raw: String, default_port: int = DEFAULT_PORT) -> Dictionary:
	var s: = raw.strip_edges().replace(" ", "")
	if s.is_empty():
		return {"address": "", "port": default_port}
	s = s.trim_prefix("http://").trim_prefix("https://")
	var port: = default_port
	var host: = s
	if s.contains(":"):
		var parts: = s.rsplit(":", true, 1)
		host = parts[0]
		if parts.size() > 1 and String(parts[1]).is_valid_int():
			port = clampi(int(parts[1]), 1, 65535)
	return {"address": host, "port": port}


func set_pending_join(raw: String, display_name: String = "") -> String:
	var parsed: = parse_address(raw)
	if String(parsed.address).is_empty():
		pending_join_address = ""
		pending_join_name = ""
		return "Pick a server from the browser, or add one by name."
	pending_join_address = String(parsed.address)
	pending_join_port = int(parsed.port)
	pending_join_name = display_name.strip_edges()
	var label: = pending_join_name if pending_join_name != "" else "friend's world"
	return "Will join %s after you enter the world." % label


func clear_pending_join() -> void :
	pending_join_address = ""
	pending_join_port = DEFAULT_PORT
	pending_join_name = ""



func try_pending_join() -> String:
	if pending_join_address == "":
		return ""
	var addr: = pending_join_address
	var port: = pending_join_port
	var label: = pending_join_name
	clear_pending_join()
	return join(addr, port, label)


func host(port: int = DEFAULT_PORT, world_name: String = "Hellas World") -> String:
	disconnect_session()
	_host_port = port
	_server_name = world_name.strip_edges()
	if _server_name.is_empty():
		_server_name = "Hellas World"
	var peer: = ENetMultiplayerPeer.new()
	var err: = peer.create_server(port, 8)
	if err != OK:
		_status = "Host failed (%s)" % error_string(err)
		session_changed.emit()
		return _status
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	GameState.ensure_world_host_identity()
	PartyShare.clear()
	PartyShare.ensure_local_member()
	PartyShare.leader_peer = multiplayer.get_unique_id()
	_invite = "0.0.0.0:%d" % port
	_status = "Hosting '%s' — preparing invite (host only)…" % _server_name
	_announce("World '%s' is open. Your save is the host version — friends receive it on join." % _server_name)
	_announce("Internet friends: use Copy Invite (only you see the address), they Add Server by name.")
	## Mid-session host: publish already-spawned mobs under net ids.
	call_deferred("host_register_existing_world")
	if ServerBrowser:
		ServerBrowser.start_advertise(_server_name, port, 1, 8)
	session_changed.emit()
	_begin_invite_discovery(port)
	return _status


func join(address: String, port: int = DEFAULT_PORT, display_name: String = "") -> String:
	disconnect_session()
	var parsed: = parse_address(address, port)
	var host_addr: = String(parsed.address)
	var host_port: = int(parsed.port)
	if host_addr.is_empty():
		_status = "Join failed — empty address"
		session_changed.emit()
		return _status
	_join_label = display_name.strip_edges()
	var peer: = ENetMultiplayerPeer.new()
	var err: = peer.create_client(host_addr, host_port)
	if err != OK:
		_status = "Join failed (%s)" % error_string(err)
		session_changed.emit()
		return _status
	multiplayer.multiplayer_peer = peer
	_wire_signals()
	var label: = _join_label if _join_label != "" else "world"
	_status = "Connecting to %s…" % label
	session_changed.emit()
	return _status


func disconnect_session() -> void :
	_clear_avatars()
	_release_upnp()
	_invite = ""
	_join_label = ""
	_seen_peer_ips.clear()
	if ServerBrowser:
		ServerBrowser.stop_advertise()
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


func _begin_invite_discovery(port: int) -> void :
	_try_upnp(port)
	_fetch_public_ip()


func _try_upnp(port: int) -> void :
	_upnp = UPNP.new()
	var disc: = _upnp.discover(2000, 2, "InternetGatewayDevice")
	if disc != UPNP.UPNP_RESULT_SUCCESS:
		disc = _upnp.discover(2000, 2, "")
	if disc != UPNP.UPNP_RESULT_SUCCESS:
		return
	if _upnp.get_gateway() == null or not _upnp.get_gateway().is_valid_gateway():
		return
	var map_err: = _upnp.add_port_mapping(port, port, "EmpiresOfOlympus", "UDP")
	if map_err != UPNP.UPNP_RESULT_SUCCESS:
		map_err = _upnp.add_port_mapping(port, port, "", "UDP")
	_upnp_mapped = map_err == UPNP.UPNP_RESULT_SUCCESS
	var ext: = _upnp.query_external_address()
	if ext != "" and not ext.begins_with("0."):
		_public_ip = ext
		_set_invite("%s:%d" % [_public_ip, port])


func _release_upnp() -> void :
	if _upnp != null and _upnp_mapped:
		_upnp.delete_port_mapping(_host_port, "UDP")
	_upnp = null
	_upnp_mapped = false


func _fetch_public_ip() -> void :
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 8.0
		add_child(_http)
		_http.request_completed.connect(_on_public_ip)
	var err: = _http.request(PUBLIC_IP_URL)
	if err != OK and _invite.begins_with("0.0.0.0"):
		_set_invite("localhost:%d" % _host_port)


func _on_public_ip(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	if code != 200:
		if _invite.begins_with("0.0.0.0"):
			_set_invite("localhost:%d" % _host_port)
		return
	var ip: = body.get_string_from_utf8().strip_edges()
	if ip.is_empty() or not ip.contains("."):
		return
	_public_ip = ip
	_set_invite("%s:%d" % [_public_ip, _host_port])


func _set_invite(invite: String) -> void :
	_invite = invite
	var upnp_note: = " · UPnP open" if _upnp_mapped else ""

	_status = "Hosting '%s'%s — Copy Invite to share privately" % [_server_name, upnp_note]
	_announce("Invite ready (host only — use Copy Invite; not shown to other players).")
	invite_ready.emit(_invite)
	session_changed.emit()


func _wire_signals() -> void :
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


func _on_connected_ok() -> void :
	var label: = _join_label if _join_label != "" else "the world"
	_status = "Joined %s" % label
	_announce("Joined %s. Host world + mobs are shared — no conflicts. Press Enter to chat." % label)
	## Drop divergent local spawns; host will send the roster.
	_clear_local_world_mobs()
	_hello.rpc(_identity())
	session_changed.emit()


func _on_connected_fail() -> void :
	_status = "Join failed — is the host online / firewall open?"
	disconnect_session()


func _on_server_disconnected() -> void :
	_announce("Host closed the world.")
	disconnect_session()


func _on_peer_connected(id: int) -> void :
	_hello.rpc_id(id, _identity())
	if multiplayer.is_server():
		_host_note_peer_ip(id)
		var n: = maxi(0, multiplayer.get_peers().size())
		_status = "Hosting '%s' — %d player(s) connected" % [_server_name, n + 1]
		if ServerBrowser:
			ServerBrowser.update_advertise(n + 1, 8)
		session_changed.emit()


func _on_peer_disconnected(id: int) -> void :
	_remove_avatar(id)
	_seen_peer_ips.erase(id)
	PartyShare.remove_member(id)
	GameState.remove_world_peer(id)
	_announce("A champion left the world.")
	if multiplayer.is_server():
		var n: = multiplayer.get_peers().size()
		_status = "Hosting '%s' — %d player(s) connected" % [_server_name, n + 1]
		if ServerBrowser:
			ServerBrowser.update_advertise(n + 1, 8)
		broadcast_world_save()
		session_changed.emit()



func _host_note_peer_ip(peer_id: int) -> void :
	if _seen_peer_ips.get(peer_id, false):
		return
	_seen_peer_ips[peer_id] = true
	var ip: = _peer_remote_address(peer_id)
	if ip == "":
		ip = "(unknown)"
	var ms: = _peer_rtt_ms(peer_id)
	var ms_txt: = ("%d ms" % ms) if ms >= 0 else "… ms"
	if ChatSystem and ChatSystem.has_method("announce_local"):
		ChatSystem.announce_local(
			"[Host only] Peer %d connected from %s · latency %s" % [peer_id, ip, ms_txt])


func _peer_rtt_ms(peer_id: int) -> int:
	var mp: = multiplayer.multiplayer_peer
	if mp == null or not (mp is ENetMultiplayerPeer):
		return -1
	var enet: = mp as ENetMultiplayerPeer
	var ep: = enet.get_peer(peer_id)
	if ep == null:
		return -1
	## ENetPeer round-trip time in milliseconds (Godot 4).
	if ep.has_method("get_statistic"):
		var rtt: = float(ep.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))
		return int(rtt)
	return -1


func _peer_remote_address(peer_id: int) -> String:
	var mp: = multiplayer.multiplayer_peer
	if mp == null or not (mp is ENetMultiplayerPeer):
		return ""
	var enet: = mp as ENetMultiplayerPeer
	var ep: = enet.get_peer(peer_id)
	if ep == null:
		return ""
	return String(ep.get_remote_address())


func _identity() -> Dictionary:
	return {
		"name": String(GameState.player_name),
		"empire": String(GameState.empire),
		"level": int(GameState.level),
		"hp": _local_hp(),
		"max_hp": float(GameState.max_hp()),
		"account": String(AccountSystem.username) if AccountSystem else "",
		"class": String(GameState.player_class),
	}


func avatar_for_peer(peer_id: int) -> Node:
	return _avatars.get(peer_id)


func _host_announce_latencies() -> void:
	if not is_hosting() or ChatSystem == null:
		return
	for pid in multiplayer.get_peers():
		var ip: = _peer_remote_address(int(pid))
		var ms: = _peer_rtt_ms(int(pid))
		var av: Node = _avatars.get(int(pid))
		var nm: = String(av.get("display_name")) if av != null and "display_name" in av else ("peer %d" % int(pid))
		var ms_txt: = ("%d ms" % ms) if ms >= 0 else "? ms"
		ChatSystem.announce_local("[Host only] %s · %s · %s" % [nm, ip if ip != "" else "?", ms_txt])


func _local_player() -> Node:
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_in_group("remote_player"):
			continue
		if p.is_multiplayer_authority() or not is_online():
			return p
	return get_tree().get_first_node_in_group("player")


func _local_hp() -> float:
	var p: = _local_player()
	if p != null and "hp" in p:
		return float(p.hp)
	return float(GameState.max_hp())


@rpc("any_peer", "reliable")
func _hello(data: Dictionary) -> void :
	var id: = multiplayer.get_remote_sender_id()
	if id == 0 or id == multiplayer.get_unique_id():
		return
	_spawn_or_update_avatar(id, data)
	_hello_ack.rpc_id(id, _identity())
	if multiplayer.is_server():
		_host_admit_peer(id, data)


@rpc("any_peer", "reliable")
func _hello_ack(data: Dictionary) -> void :
	var id: = multiplayer.get_remote_sender_id()
	if id == 0:
		return
	_spawn_or_update_avatar(id, data)


func _host_admit_peer(peer_id: int, data: Dictionary) -> void :
	## Host world is canonical. Add joiner to roster/party and push host save.
	GameState.ensure_world_host_identity()
	GameState.add_world_peer(peer_id, data)
	PartyShare.ensure_local_member()
	PartyShare.upsert_member(peer_id, data)
	if PartyShare.leader_peer == 0:
		PartyShare.leader_peer = multiplayer.get_unique_id()
	var snap: = GameState.to_world_sync_dict()
	snap["party"] = {
		"leader": PartyShare.leader_peer,
		"roster": PartyShare._roster_payload(),
	}
	_rpc_world_snapshot.rpc_id(peer_id, snap)
	## Same mob instances on every client.
	push_mob_roster_to(peer_id)
	_announce("%s was added to the host save (shared world — no conflicts)." % String(data.get("name", "Champion")))
	if AccountSystem.is_logged_in():
		AccountSystem.save_game()


func broadcast_world_save() -> void :
	if not is_hosting():
		return
	GameState.ensure_world_host_identity()
	var snap: = GameState.to_world_sync_dict()
	snap["party"] = {
		"leader": PartyShare.leader_peer,
		"roster": PartyShare._roster_payload(),
	}
	_rpc_world_snapshot.rpc(snap)
	if AccountSystem.is_logged_in():
		AccountSystem.save_game()


@rpc("authority", "reliable")
func _rpc_world_snapshot(payload: Dictionary) -> void :
	## Guests receive host world version and save it locally (personal gear kept).
	if multiplayer.is_server():
		return
	if payload.is_empty():
		return
	GameState.apply_world_sync_dict(payload)
	var party = payload.get("party", {})
	if typeof(party) == TYPE_DICTIONARY:
		var roster = party.get("roster", {})
		if typeof(roster) == TYPE_DICTIONARY:
			PartyShare.members.clear()
			for k in roster.keys():
				var row = roster[k]
				if typeof(row) == TYPE_DICTIONARY:
					PartyShare._set_member(int(k), row)
			PartyShare.leader_peer = int(party.get("leader", 1))
			PartyShare.ensure_local_member()
			PartyShare.party_changed.emit()
	var world: = get_tree().get_first_node_in_group("game_world")
	if world != null and world.has_method("apply_player_mosaic"):
		world.apply_player_mosaic()
	var hud: = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("_refresh_quest"):
		hud._refresh_quest()
	if AccountSystem.is_logged_in():
		AccountSystem.save_game()
	_announce("Host world loaded onto your save (quests, mosaic, progress). Your gear stays yours.")


func request_skill_fx(skill_id: String, origin: Vector3, yaw: float) -> void :
	if not is_online():
		return
	_rpc_skill_fx.rpc(skill_id, origin, yaw, String(GameState.player_class))


@rpc("any_peer", "unreliable")
func _rpc_skill_fx(skill_id: String, origin: Vector3, yaw: float, p_class: String) -> void :
	var id: = multiplayer.get_remote_sender_id()
	if id == 0:
		return
	var av: Node = _avatars.get(id)
	if av != null and is_instance_valid(av) and av.has_method("play_skill_fx"):
		av.call("play_skill_fx", skill_id, origin, yaw, p_class)


func _spawn_or_update_avatar(id: int, data: Dictionary) -> void :
	var world: = get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var p_class: = String(data.get("class", data.get("player_class", "hoplite")))
	var av: Node = _avatars.get(id)
	if av == null or not is_instance_valid(av):
		var RemoteAvatar: = load("res://scripts/remote_avatar.gd")
		av = CharacterBody3D.new()
		av.set_script(RemoteAvatar)
		av.call("setup", id,
			String(data.get("name", "Champion")),
			String(data.get("empire", "sparta")),
			int(data.get("level", 1)),
			p_class)
		world.add_child(av)
		var anchor: = Vector3(2.0 * float(id % 5), 0.0, 2.0)
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
			int(data.get("level", 1)),
			p_class)


func _remove_avatar(id: int) -> void :
	var av: Node = _avatars.get(id)
	if av != null and is_instance_valid(av):
		av.queue_free()
	_avatars.erase(id)
	peer_avatar_removed.emit(id)


func _clear_avatars() -> void :
	for id in _avatars.keys():
		_remove_avatar(int(id))
	_avatars.clear()


var _latency_accum: float = 0.0

func _process(delta: float) -> void :
	if not is_online():
		return
	## Host-only: refresh peer latency in chat every ~8s.
	if is_hosting():
		_latency_accum += delta
		if _latency_accum >= 8.0:
			_latency_accum = 0.0
			_host_announce_latencies()
	_sync_accum += delta
	_enemy_sync_accum += delta
	if is_hosting() and _enemy_sync_accum >= 0.35:
		_enemy_sync_accum = 0.0
		_host_pulse_mob_positions()
	if _sync_accum < 1.0 / SYNC_HZ:
		return
	_sync_accum = 0.0
	var p: = _local_player()
	if p == null or not (p is Node3D):
		return
	if p.is_in_group("remote_player"):
		return
	var moving: = Vector2(p.velocity.x, p.velocity.z).length() > 0.2 if "velocity" in p else false
	var yaw: = 0.0
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


func _host_pulse_mob_positions() -> void:
	for nid in _world_mobs.keys():
		var n: Node = _world_mobs[nid]
		if n == null or not is_instance_valid(n) or n.get("dead") == true:
			continue
		if not n.is_in_group("enemies"):
			continue
		sync_mob_hp(int(nid), float(n.get("hp")), float(n.get("max_hp")), (n as Node3D).global_position)


@rpc("any_peer", "unreliable_ordered")
func _state_sync(pos: Vector3, yaw: float, hp: float, max_hp: float, level: int, moving: bool, empire: String, p_name: String) -> void :
	var id: = multiplayer.get_remote_sender_id()
	if id == 0:
		return
	var av: Node = _avatars.get(id)
	if av == null or not is_instance_valid(av):
		_spawn_or_update_avatar(id, {"name": p_name, "empire": empire, "level": level})
		av = _avatars.get(id)
	if av != null and av.has_method("apply_state"):
		av.call("apply_state", pos, yaw, hp, max_hp, level, moving)


func request_damage(target_peer: int, amount: float, from_pos: Vector3) -> void :
	if not is_online():
		return
	_rpc_damage.rpc_id(target_peer, amount, from_pos, multiplayer.get_unique_id())


@rpc("any_peer", "reliable")
func _rpc_damage(amount: float, from_pos: Vector3, attacker_peer: int) -> void :
	var p: = _local_player()
	if p == null or not p.has_method("take_pvp_damage"):
		return
	p.call("take_pvp_damage", amount, from_pos, attacker_peer)


func notify_death_loot(drop_ids: Array, at: Vector3, gold_amt: int = 0) -> void :
	if is_online():
		_rpc_spawn_loot.rpc(drop_ids, at, gold_amt)
	else:
		_spawn_loot_local(drop_ids, at, gold_amt)


@rpc("any_peer", "reliable", "call_local")
func _rpc_spawn_loot(drop_ids: Array, at: Vector3, gold_amt: int = 0) -> void :
	_spawn_loot_local(drop_ids, at, gold_amt)


func _spawn_loot_local(drop_ids: Array, at: Vector3, gold_amt: int = 0) -> void :
	var world: = get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var LootPickup: = load("res://scripts/loot_pickup.gd")
	if LootPickup == null:
		return
	for id in drop_ids:
		var loot_id: = String(id)
		if loot_id == "":
			continue
		var drop: Node = LootPickup.new()
		world.add_child(drop)
		if drop.has_method("setup"):
			drop.call("setup", loot_id, at + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.6, 0.6)), 0)
	if gold_amt > 0:
		var gdrop: Node = LootPickup.new()
		world.add_child(gdrop)
		if gdrop.has_method("setup"):
			gdrop.call("setup", "gold_coin", at + Vector3(randf_range(-0.4, 0.4), 0.2, randf_range(-0.4, 0.4)), gold_amt)


## --- Party equal share -------------------------------------------------------

func distribute_party_rewards(
		peers: Array, xp_parts: Array, gold_parts: Array,
		mat_id: String, mat_count: int, potions: int,
		drop_ids: Array, at: Vector3
	) -> void:
	var n: = peers.size()
	## Materials/potions/gear: equal 1/N split (level-agnostic). Remainder → index 0.
	var mat_parts: = _split_parts(mat_count, n)
	var pot_parts: = _split_parts(potions, n)
	## Round-robin gear drops so each member gets a fair share (not a ground race).
	var loot_by_peer: Dictionary = {}
	for i in n:
		loot_by_peer[int(peers[i])] = []
	for di in drop_ids.size():
		var loot_id: = String(drop_ids[di])
		if loot_id == "":
			continue
		var owner_pid: = int(peers[di % n])
		(loot_by_peer[owner_pid] as Array).append(loot_id)
	for i in n:
		var pid: = int(peers[i])
		var xp: = int(xp_parts[i]) if i < xp_parts.size() else 0
		var gold: = int(gold_parts[i]) if i < gold_parts.size() else 0
		var mc: = int(mat_parts[i]) if i < mat_parts.size() else 0
		var pc: = int(pot_parts[i]) if i < pot_parts.size() else 0
		var my_drops: Array = loot_by_peer.get(pid, [])
		if is_online():
			_rpc_party_reward.rpc_id(pid, xp, gold, mat_id, mc, pc, my_drops)
		else:
			_apply_party_reward(xp, gold, mat_id, mc, pc, my_drops)
	## Visual ground loot for atmosphere (gold already granted via share).
	if not drop_ids.is_empty() and n <= 1:
		notify_death_loot(drop_ids, at, 0)


func _split_parts(total: int, n: int) -> Array:
	var parts: Array = []
	if n <= 0:
		return parts
	var base: = int(total / n) if total > 0 else 0
	var rem: = total % n if total > 0 else 0
	for i in n:
		parts.append(base + (1 if i < rem else 0))
	return parts


@rpc("any_peer", "reliable")
func _rpc_party_reward(xp: int, gold: int, mat_id: String, mat_count: int, potions: int, drops: Array = []) -> void:
	_apply_party_reward(xp, gold, mat_id, mat_count, potions, drops)


func _apply_party_reward(xp: int, gold: int, mat_id: String, mat_count: int, potions: int, drops: Array = []) -> void:
	if xp > 0:
		GameState.add_xp(xp)
	if gold > 0:
		GameState.add_gold(gold)
	if mat_id != "" and mat_count > 0:
		GameState.add_material(mat_id, mat_count)
	if potions > 0:
		GameState.health_potions += potions
		GameState.potions_changed.emit()
	## Direct bag grant — equal loot share, no race to the ground pile.
	var hud: = get_tree().get_first_node_in_group("hud") if get_tree() else null
	for d in drops:
		var loot_id: = String(d)
		if loot_id == "":
			continue
		if GameState.try_add_to_bag(loot_id):
			if hud != null and hud.has_method("show_announcement"):
				hud.show_announcement("Party loot: %s" % GameState.item_name(loot_id))
		elif hud != null and hud.has_method("show_announcement"):
			hud.show_announcement("Bag full — missed party loot: %s" % GameState.item_name(loot_id))


## --- Host-authoritative mobs -------------------------------------------------

func should_spawn_world_mobs_locally() -> bool:
	## Guests never local-spawn; pending/connecting clients wait for host roster.
	if pending_join_address != "":
		return false
	if is_hosting():
		return true
	if is_online():
		return false
	## Connecting client (peer exists, not yet CONNECTION_CONNECTED).
	if multiplayer.has_multiplayer_peer():
		var peer: = multiplayer.multiplayer_peer
		if peer != null and not (peer is OfflineMultiplayerPeer):
			var st: = peer.get_connection_status()
			if st == MultiplayerPeer.CONNECTION_CONNECTING:
				return false
			if st == MultiplayerPeer.CONNECTION_CONNECTED and not multiplayer.is_server():
				return false
	return true


func host_register_enemy(enemy: Node) -> int:
	if enemy == null or not is_hosting():
		return 0
	var nid: = _next_mob_id
	_next_mob_id += 1
	enemy.set("net_id", nid)
	enemy.set("is_proxy", false)
	_world_mobs[nid] = enemy
	_rpc_mob_spawn.rpc(
		nid, "enemy", String(enemy.get("enemy_id")),
		(enemy as Node3D).global_position,
		float(enemy.get("hp")), float(enemy.get("max_hp")),
		0
	)
	return nid


func host_register_stone(stone: Node) -> int:
	if stone == null or not is_hosting():
		return 0
	var nid: = _next_mob_id
	_next_mob_id += 1
	stone.set("net_id", nid)
	stone.set("is_proxy", false)
	_world_mobs[nid] = stone
	_rpc_mob_spawn.rpc(
		nid, "stone", "",
		(stone as Node3D).global_position,
		float(stone.get("hp")), float(stone.get("max_hp")),
		int(stone.get("stone_tier"))
	)
	return nid


func host_register_existing_world() -> void:
	## Call when hosting starts mid-session so guests get live mobs.
	if not is_hosting():
		return
	_world_mobs.clear()
	_next_mob_id = 1
	var tree: = get_tree()
	if tree == null:
		return
	for e in tree.get_nodes_in_group("enemies"):
		if e == null or not is_instance_valid(e) or e.get("dead") == true:
			continue
		if e.is_in_group("oracle_stones"):
			continue
		host_register_enemy(e)
	for s in tree.get_nodes_in_group("oracle_stones"):
		if s != null and is_instance_valid(s) and s.get("dead") != true:
			host_register_stone(s)


func push_mob_roster_to(peer_id: int) -> void:
	if not is_hosting():
		return
	var rows: Array = []
	for nid in _world_mobs.keys():
		var n: Node = _world_mobs[nid]
		if n == null or not is_instance_valid(n) or n.get("dead") == true:
			continue
		var kind: = "stone" if n.is_in_group("oracle_stones") else "enemy"
		rows.append({
			"id": int(nid),
			"kind": kind,
			"enemy_id": String(n.get("enemy_id")) if kind == "enemy" else "",
			"tier": int(n.get("stone_tier")) if kind == "stone" else 0,
			"pos": (n as Node3D).global_position,
			"hp": float(n.get("hp")),
			"max_hp": float(n.get("max_hp")),
		})
	_rpc_mob_roster.rpc_id(peer_id, rows)


func request_enemy_damage(net_id: int, amount: float, from_pos: Vector3) -> void:
	if not is_online() or net_id <= 0:
		return
	if is_hosting():
		_host_apply_mob_damage(net_id, amount, from_pos)
	else:
		_rpc_mob_damage.rpc_id(1, net_id, amount, from_pos)


@rpc("any_peer", "reliable")
func _rpc_mob_damage(net_id: int, amount: float, from_pos: Vector3) -> void:
	if not multiplayer.is_server():
		return
	_host_apply_mob_damage(net_id, amount, from_pos)


func _host_apply_mob_damage(net_id: int, amount: float, from_pos: Vector3) -> void:
	var n: Node = _world_mobs.get(net_id)
	if n == null or not is_instance_valid(n):
		return
	if n.has_method("apply_network_damage"):
		n.call("apply_network_damage", amount, from_pos)
	elif n.has_method("take_damage"):
		## Bypass guest-forward path.
		n.set_meta("_net_damage_direct", true)
		n.call("take_damage", amount, from_pos)
		n.remove_meta("_net_damage_direct")


func sync_mob_hp(net_id: int, hp: float, max_hp: float, pos: Vector3) -> void:
	if not is_hosting():
		return
	_rpc_mob_hp.rpc(net_id, hp, max_hp, pos)


func host_mob_died(net_id: int, pos: Vector3) -> void:
	if not is_hosting():
		return
	_world_mobs.erase(net_id)
	_rpc_mob_died.rpc(net_id, pos)


@rpc("authority", "reliable")
func _rpc_mob_spawn(net_id: int, kind: String, enemy_id: String, pos: Vector3, hp: float, max_hp: float, tier: int) -> void:
	if multiplayer.is_server():
		return
	_spawn_proxy_mob(net_id, kind, enemy_id, pos, hp, max_hp, tier)


@rpc("authority", "reliable")
func _rpc_mob_roster(rows: Array) -> void:
	if multiplayer.is_server():
		return
	_clear_local_world_mobs()
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		_spawn_proxy_mob(
			int(row.get("id", 0)),
			String(row.get("kind", "enemy")),
			String(row.get("enemy_id", "wolf_enemy")),
			row.get("pos", Vector3.ZERO),
			float(row.get("hp", 1)),
			float(row.get("max_hp", 1)),
			int(row.get("tier", 1))
		)


@rpc("authority", "unreliable_ordered")
func _rpc_mob_hp(net_id: int, hp: float, max_hp: float, pos: Vector3) -> void:
	if multiplayer.is_server():
		return
	var n: Node = _world_mobs.get(net_id)
	if n == null or not is_instance_valid(n):
		return
	if "hp" in n:
		n.hp = hp
	if "max_hp" in n:
		n.max_hp = max_hp
	if n is Node3D and pos != Vector3.ZERO:
		## Soft follow for stones/enemies that move.
		if n.is_in_group("enemies"):
			(n as Node3D).global_position = (n as Node3D).global_position.lerp(pos, 0.35)
	if n.has_method("_set_bar_fraction") and max_hp > 0.0:
		n.call("_set_bar_fraction", hp / max_hp)


@rpc("authority", "reliable")
func _rpc_mob_died(net_id: int, pos: Vector3) -> void:
	if multiplayer.is_server():
		return
	var n: Node = _world_mobs.get(net_id)
	_world_mobs.erase(net_id)
	if n != null and is_instance_valid(n):
		if n.has_method("mark_proxy_dead"):
			n.call("mark_proxy_dead", pos)
		else:
			n.queue_free()


func _spawn_proxy_mob(net_id: int, kind: String, enemy_id: String, pos: Vector3, hp: float, max_hp: float, tier: int) -> void:
	if net_id <= 0:
		return
	if _world_mobs.has(net_id) and is_instance_valid(_world_mobs[net_id]):
		return
	var world: = get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var node: Node = null
	if kind == "stone":
		var OracleStoneScript = load("res://scripts/oracle_stone.gd")
		node = OracleStoneScript.create(pos, tier)
	else:
		var EnemyScript = load("res://scripts/enemy.gd")
		node = EnemyScript.create(enemy_id if enemy_id != "" else "wolf_enemy", pos)
	if node == null:
		return
	node.set("net_id", net_id)
	node.set("is_proxy", true)
	world.add_child(node)
	if "hp" in node:
		node.hp = hp
	if "max_hp" in node:
		node.max_hp = max_hp
	_world_mobs[net_id] = node


func _clear_local_world_mobs() -> void:
	var tree: = get_tree()
	if tree:
		for e in tree.get_nodes_in_group("enemies"):
			if e != null and is_instance_valid(e):
				e.queue_free()
		for s in tree.get_nodes_in_group("oracle_stones"):
			if s != null and is_instance_valid(s):
				s.queue_free()
	_world_mobs.clear()


## --- Guest → host world patches (mosaic / plaza / quest) ----------------------

func propose_world_patch(patch: Dictionary) -> void:
	if patch.is_empty():
		return
	if is_hosting() or not is_online():
		GameState.apply_world_patch(patch)
		if is_hosting():
			broadcast_world_save()
		return
	## Guest: optimistic local apply for UI; host save remains superior after RPC.
	GameState.apply_world_patch(patch)
	_rpc_world_patch.rpc_id(1, patch)


@rpc("any_peer", "reliable")
func _rpc_world_patch(patch: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sanitized: = _sanitize_world_patch(patch)
	if sanitized.is_empty():
		## Still push host truth so guest UI reconciles.
		broadcast_world_save()
		return
	GameState.apply_world_patch(sanitized)
	broadcast_world_save()


func _mosaic_stage_rank(stage: String) -> int:
	match stage:
		"complete":
			return 2
		"accepted":
			return 1
		_:
			return 0


func _sanitize_world_patch(patch: Dictionary) -> Dictionary:
	## Host never regresses shared world progress from a guest proposal.
	var out: = {}
	if patch.has("quest_index"):
		var qi: = int(patch["quest_index"])
		if qi >= GameState.quest_index:
			out["quest_index"] = qi
			if patch.has("quest_kills"):
				out["quest_kills"] = patch["quest_kills"]
	elif patch.has("quest_kills") and typeof(patch["quest_kills"]) == TYPE_DICTIONARY:
		## Merge kill counts upward only.
		var merged: = GameState.quest_kills.duplicate()
		var raw = patch["quest_kills"]
		for k in raw:
			var key: = String(k)
			merged[key] = maxi(int(merged.get(key, 0)), int(raw[k]))
		out["quest_kills"] = merged
	if patch.has("omphaloi_destroyed"):
		out["omphaloi_destroyed"] = maxi(GameState.omphaloi_destroyed, int(patch["omphaloi_destroyed"]))
	if patch.has("minotaur_slain") and bool(patch["minotaur_slain"]):
		out["minotaur_slain"] = true
	if patch.has("mosaic_quest_stage"):
		var stage: = String(patch["mosaic_quest_stage"])
		if _mosaic_stage_rank(stage) >= _mosaic_stage_rank(GameState.mosaic_quest_stage):
			out["mosaic_quest_stage"] = stage
	## Accept plaza paint while open, or as part of sealing to complete.
	var sealing: = String(patch.get("mosaic_quest_stage", "")) == "complete" \
			or GameState.mosaic_quest_stage != "complete"
	if patch.has("mosaic_tiles") and sealing:
		out["mosaic_tiles"] = patch["mosaic_tiles"]
	if patch.has("mosaic_rewarded") and bool(patch["mosaic_rewarded"]):
		out["mosaic_rewarded"] = true
	return out


func _announce(msg: String) -> void :
	if ChatSystem:
		ChatSystem.call("_push_system", msg)
