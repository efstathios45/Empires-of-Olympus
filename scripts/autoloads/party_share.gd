extends Node
## Party roster + XP/gold share. Online peers can invite/leave; map HUD reads members.


signal share_announced(message: String)
signal party_changed

## peer_id (int) -> {name, empire, level, account}
var members: Dictionary = {}
var leader_peer: int = 0


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
	return members.size() > 0


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
	## Called when a guest joins a world — host's party becomes the shared party.
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
	accept_invite(from_id, roster, leader)
	_announce("%s invited you to the party." % String((roster.get(str(from_id), {}) as Dictionary).get("name", "A champion")))


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


func contributors(target: Object) -> Array:
	var out: Array = []
	if target == null:
		return out
	var bag: Dictionary = target.get_meta("_party_share", {})
	for k in bag.keys():
		var n: Variant = bag[k]
		if n is Node and is_instance_valid(n) and (n as Node).is_in_group("player"):
			out.append(n)
	if out.is_empty():
		var tree: = get_tree()
		if tree:
			for p in tree.get_nodes_in_group("player"):
				out.append(p)
				break
	return out


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


func award_xp_and_gold(target: Object, xp_total: int, gold_total: int) -> Array:
	var people: Array = contributors(target)
	var n: = maxi(1, people.size())
	var xp_parts: = _split_int(maxi(0, xp_total), n)
	var gold_parts: = _split_int(maxi(0, gold_total), n)
	var local_player: = _local_player()
	var local_idx: = 0
	if local_player != null:
		for i in people.size():
			if people[i] == local_player:
				local_idx = i
				break
	var xp_grant: int = int(xp_parts[local_idx]) if local_idx < xp_parts.size() else xp_total
	var gold_grant: int = int(gold_parts[local_idx]) if local_idx < gold_parts.size() else gold_total
	if xp_grant > 0:
		GameState.add_xp(xp_grant)
	if gold_grant > 0:
		GameState.add_gold(gold_grant)
	if n > 1:
		var msg: = "Shared among %d champions — you received %d XP" % [n, xp_grant]
		if gold_grant > 0:
			msg += " and %d δ" % gold_grant
		msg += "."
		share_announced.emit(msg)
		_announce(msg)
	return people


func _local_player() -> Node:
	var tree: = get_tree()
	if tree == null:
		return null
	var players: = tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	for p in players:
		if p is Node and p.is_multiplayer_authority():
			return p
	return players[0]


func note_nearby(target: Object, origin: Vector3, radius: float = 14.0) -> void:
	var tree: = get_tree()
	if tree == null:
		return
	for p in tree.get_nodes_in_group("player"):
		if p is Node3D and (p as Node3D).global_position.distance_to(origin) <= radius:
			note(target, p)


func _announce(msg: String) -> void:
	var chat: = get_node_or_null("/root/ChatSystem")
	if chat != null and chat.has_method("_push_system"):
		chat.call("_push_system", msg)
