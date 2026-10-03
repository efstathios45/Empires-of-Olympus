extends Node




signal share_announced(message: String)


func note(target: Object, contributor: Node) -> void :
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
		var chat: = get_node_or_null("/root/ChatSystem")
		if chat != null and chat.has_method("_push_system"):
			chat.call("_push_system", msg)
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



func note_nearby(target: Object, origin: Vector3, radius: float = 14.0) -> void :
	var tree: = get_tree()
	if tree == null:
		return
	for p in tree.get_nodes_in_group("player"):
		if p is Node3D and (p as Node3D).global_position.distance_to(origin) <= radius:
			note(target, p)
