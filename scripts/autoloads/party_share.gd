extends Node
## Party roster + equal XP/gold/loot share (level-agnostic 1/N).


signal share_announced(message: String)
signal party_changed
signal invite_pending(from_peer: int, from_name: String, payload: Dictionary)
signal invite_declined(from_name: String)

## peer_id (int) -> {name, empire, level, account}
var members: Dictionary = {}
var leader_peer: int = 0
const SHARE_RADIUS: = 18.0


func clear() -> void:
	members.clear()
	leader_peer = 0
	party_changed.emit()


func local_peer_id() -> int:
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer != null:
		var st: = multiplayer.multiplayer_peer.get_connection_status()
		if st == MultiplayerPeer.CONNECTION_CONNECTED:
			return multiplayer.get_unique_id()
	return 1


func is_in_party() -> bool:
	return members.size() > 1


func member_list() -> Array:
	var out: Array = []
	for pid in members.keys():
		var row: Dictionary = members[pid]
		out.append({
			"peer_id": int(pid),
			"name": String(row.get("name", "Champion")),
			"empire": String(row.get("empire", "sparta")),
			"level": int(row.get("level", 1)),
			"account": String(row.get("account", "")),
			"leader": int(pid) == leader_peer,
		})
	out.sort_custom(func(a, b): return int(a["peer_id"]) < int(b["peer_id"]))
	return out


func ensure_local_member() -> void:
	var id: = local_peer_id()
	_set_member(id, {
		"name": String(GameState.player_name),
		"empire": String(GameState.empire),
		"level": int(GameState.level),
		"account": String(AccountSystem.username) if AccountSystem else "",
	})
	if leader_peer == 0:
		leader_peer = id


func _set_member(peer_id: int, data: Dictionary) -> void:
	members[peer_id] = {
		"name": String(data.get("name", "Champion")),
		"empire": String(data.get("empire", "sparta")),
		"level": int(data.get("level", 1)),
		"account": String(data.get("account", "")),
	}


func upsert_member(peer_id: int, data: Dictionary) -> void:
	_set_member(peer_id, data)
	party_changed.emit()


func remove_member(peer_id: int) -> void:
	if not members.has(peer_id):
		return
	members.erase(peer_id)
	if leader_peer == peer_id:
		leader_peer = 0
		for k in members.keys():
			leader_peer = int(k)
			break
	party_changed.emit()


func invite_peer(peer_id: int) -> String:
	if peer_id == local_peer_id():
		return "You are already in the party."
	if not NetSession.is_online():
		return "Host or join a world first."
	ensure_local_member()
	_rpc_party_invite.rpc_id(peer_id, {
		"from": local_peer_id(),
		"leader": leader_peer if leader_peer != 0 else local_peer_id(),
		"roster": _roster_payload(),
	})
	return "Invite sent."


func accept_invite(from_peer: int, roster: Dictionary, leader: int) -> void:
	members.clear()
	for k in roster.keys():
		var row = roster[k]
		if typeof(row) == TYPE_DICTIONARY:
			_set_member(int(k), row)
	leader_peer = leader if leader != 0 else from_peer
	ensure_local_member()
	_rpc_party_join.rpc({
		"peer_id": local_peer_id(),
		"name": String(GameState.player_name),
		"empire": String(GameState.empire),
		"level": int(GameState.level),
		"account": String(AccountSystem.username) if AccountSystem else "",
		"leader": leader_peer,
		"roster": _roster_payload(),
	})
	party_changed.emit()
	_announce("%s joined the party." % GameState.player_name)


func leave_party() -> String:
	if members.is_empty():
		return "No party to leave."
	var me: = local_peer_id()
	if NetSession.is_online():
		_rpc_party_leave.rpc(me)
	remove_member(me)
	if members.size() <= 1:
		clear()
	else:
		party_changed.emit()
	_announce("You left the party.")
	return "Left the party."


func bootstrap_with_host(host_peer: int, host_data: Dictionary, guest_data: Dictionary) -> void:
	members.clear()
	leader_peer = host_peer
	_set_member(host_peer, host_data)
	if guest_data.is_empty():
		ensure_local_member()
	else:
		_set_member(int(guest_data.get("peer_id", local_peer_id())), guest_data)
		ensure_local_member()
	party_changed.emit()


func _roster_payload() -> Dictionary:
	var out: = {}
	for k in members.keys():
		out[str(k)] = members[k]
	return out


@rpc("any_peer", "reliable")
func _rpc_party_invite(payload: Dictionary) -> void:
	var from_id: = int(payload.get("from", 0))
	var leader: = int(payload.get("leader", from_id))
	var roster = payload.get("roster", {})
	if typeof(roster) != TYPE_DICTIONARY:
		roster = {}
	var from_name: = "A champion"
	var row = roster.get(str(from_id), {})
	if typeof(row) == TYPE_DICTIONARY:
		from_name = String(row.get("name", from_name))
	var data: = {"roster": roster, "leader": leader, "name": from_name}
	invite_pending.emit(from_id, from_name, data)
	if SocialSystem:
		SocialSystem.queue_invite("party", from_id, from_name, data)


func decline_invite(from_peer: int, my_name: String) -> void:
	if NetSession.is_online() and from_peer > 0:
		_rpc_party_decline.rpc_id(from_peer, my_name)


@rpc("any_peer", "reliable")
func _rpc_party_decline(from_name: String) -> void:
	invite_declined.emit(from_name)
	_announce("%s declined the group invite." % from_name)


@rpc("any_peer", "reliable", "call_local")
func _rpc_party_join(payload: Dictionary) -> void:
	var pid: = int(payload.get("peer_id", 0))
	if pid == 0:
		return
	var roster = payload.get("roster", {})
	if typeof(roster) == TYPE_DICTIONARY and not roster.is_empty():
		members.clear()
		for k in roster.keys():
			var row = roster[k]
			if typeof(row) == TYPE_DICTIONARY:
				_set_member(int(k), row)
	else:
		_set_member(pid, payload)
	leader_peer = int(payload.get("leader", leader_peer))
	if leader_peer == 0:
		leader_peer = pid
	party_changed.emit()


@rpc("any_peer", "reliable", "call_local")
func _rpc_party_leave(peer_id: int) -> void:
	remove_member(peer_id)
	if members.size() <= 1:
		clear()


func note(target: Object, contributor: Node) -> void:
	if target == null or contributor == null or not is_instance_valid(contributor):
		return
	if not contributor.is_in_group("player"):
		return
	var bag: Dictionary = target.get_meta("_party_share", {})
	bag[contributor.get_instance_id()] = contributor
	target.set_meta("_party_share", bag)


func note_nearby(target: Object, origin: Vector3, radius: float = SHARE_RADIUS) -> void:
	var tree: = get_tree()
	if tree == null:
		return
	for p in tree.get_nodes_in_group("player"):
		if p is Node3D and (p as Node3D).global_position.distance_to(origin) <= radius:
			note(target, p)


func _split_int(total: int, n: int) -> Array:
	var parts: Array = []
	if n <= 0:
		return parts
	if total <= 0:
		for _i in n:
			parts.append(0)
		return parts
	var base: = int(total / n)
	var rem: = total % n
	for i in n:
		parts.append(base + (1 if i < rem else 0))
	return parts


## Peers in the party within radius of origin (equal share, any level).
func nearby_member_peers(origin: Vector3, radius: float = SHARE_RADIUS) -> Array:
	var out: Array = []
	var me: = local_peer_id()
	if members.size() <= 1:
		## Solo / no formal party — just the local killer.
		out.append(me)
		return out
	var tree: = get_tree()
	for pid in members.keys():
		var id: int = int(pid)
		var pos: Variant = _peer_world_pos(id)
		if pos == null:
			## Offline roster row with no body — still include local.
			if id == me:
				out.append(id)
			continue
		if (pos as Vector3).distance_to(origin) <= radius:
			out.append(id)
	if out.is_empty():
		out.append(me)
	out.sort()
	return out


func _peer_world_pos(peer_id: int) -> Variant:
	var me: = local_peer_id()
	if peer_id == me:
		var lp: = _local_player()
		if lp is Node3D:
			return (lp as Node3D).global_position
		return null
	if NetSession:
		var av = NetSession._avatars.get(peer_id)
		if av is Node3D and is_instance_valid(av):
			return (av as Node3D).global_position
	return null


## Equal 1/N XP + gold (+ materials/potions). Online: host/killer distributes via NetSession.
func award_xp_and_gold(target: Object, xp_total: int, gold_total: int, origin: Vector3 = Vector3.ZERO, extras: Dictionary = {}) -> Array:
	var at: = origin
	if at == Vector3.ZERO and target is Node3D:
		at = (target as Node3D).global_position
	var peers: Array = nearby_member_peers(at, SHARE_RADIUS)
	var n: = maxi(1, peers.size())
	var xp_parts: = _split_int(maxi(0, xp_total), n)
	var gold_parts: = _split_int(maxi(0, gold_total), n)
	var mat_id: = String(extras.get("material", ""))
	var mat_count: = int(extras.get("material_count", 0))
	var potions: = int(extras.get("potions", 0))
	var drop_ids: Array = extras.get("drops", [])
	if typeof(drop_ids) != TYPE_ARRAY:
		drop_ids = []

	## Online: only the authority (host) or the local killer when solo hostless distributes.
	var should_distribute: = true
	if NetSession and NetSession.is_online():
		should_distribute = NetSession.is_hosting()
	if should_distribute and NetSession and NetSession.has_method("distribute_party_rewards"):
		NetSession.distribute_party_rewards(peers, xp_parts, gold_parts, mat_id, mat_count, potions, drop_ids, at)
	else:
		## Offline / no NetSession helper — grant local slice only.
		var me: = local_peer_id()
		var idx: = peers.find(me)
		if idx < 0:
			idx = 0
		_grant_local(
			int(xp_parts[idx]) if idx < xp_parts.size() else xp_total,
			int(gold_parts[idx]) if idx < gold_parts.size() else gold_total,
			mat_id, mat_count, potions
		)
		if not drop_ids.is_empty() and NetSession:
			NetSession.notify_death_loot(drop_ids, at, 0)

	if n > 1:
		var me2: = local_peer_id()
		var li: = peers.find(me2)
		var xp_you: = int(xp_parts[li]) if li >= 0 and li < xp_parts.size() else 0
		var g_you: = int(gold_parts[li]) if li >= 0 and li < gold_parts.size() else 0
		var msg: = "Party share (%d) — you received %d XP" % [n, xp_you]
		if g_you > 0:
			msg += " and %d δ" % g_you
		msg += " (equal split)."
		share_announced.emit(msg)
		_announce(msg)
	return peers


func _grant_local(xp: int, gold: int, mat_id: String, mat_count: int, potions: int) -> void:
	if xp > 0:
		GameState.add_xp(xp)
	if gold > 0:
		GameState.add_gold(gold)
	if mat_id != "" and mat_count > 0:
		GameState.add_material(mat_id, mat_count)
	if potions > 0:
		GameState.health_potions += potions
		GameState.potions_changed.emit()


func _local_player() -> Node:
	var tree: = get_tree()
	if tree == null:
		return null
	var players: = tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	for p in players:
		if p is Node and not p.is_in_group("remote_player"):
			return p
	return players[0]


func _announce(msg: String) -> void:
	var chat: = get_node_or_null("/root/ChatSystem")
	if chat != null and chat.has_method("_push_system"):
		chat.call("_push_system", msg)
