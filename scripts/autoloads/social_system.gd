extends Node
## Friends, whispers, trade, and duel — peer RPCs + local persistence.


signal friends_changed
signal trade_opened(peer_id: int, their_name: String)
signal trade_updated(offer: Dictionary)
signal trade_closed
signal duel_changed(peer_id: int, active: bool)
signal whisper_received(from_name: String, text: String)

## account/name keys
var friends: Array = [] ## [{account, name}]
var duel_peer: int = 0
var _trade_peer: int = 0
var _my_offer: Array = [] ## item ids offered
var _their_offer: Array = []
var _trade_locked: bool = false


func _ready() -> void:
	_load_friends()


func _load_friends() -> void:
	friends.clear()
	if AccountSystem == null or not AccountSystem.is_logged_in():
		return
	var save: Dictionary = AccountSystem.read_local_save()
	var raw = save.get("friends", [])
	if typeof(raw) == TYPE_ARRAY:
		for e in raw:
			if typeof(e) == TYPE_DICTIONARY:
				friends.append({
					"account": String(e.get("account", "")),
					"name": String(e.get("name", "Champion")),
				})


func _persist_friends() -> void:
	if AccountSystem == null or not AccountSystem.is_logged_in():
		return
	AccountSystem.save_game({"friends": friends})


func is_friend(account: String, name: String = "") -> bool:
	for f in friends:
		if account != "" and String(f.get("account", "")) == account:
			return true
		if name != "" and String(f.get("name", "")) == name:
			return true
	return false


func send_friend_request(peer_id: int) -> String:
	if not NetSession.is_online():
		return "Go online first."
	_rpc_friend_req.rpc_id(peer_id, {
		"from_peer": multiplayer.get_unique_id(),
		"account": String(AccountSystem.username) if AccountSystem else "",
		"name": String(GameState.player_name),
	})
	return "Friend request sent."


@rpc("any_peer", "reliable")
func _rpc_friend_req(payload: Dictionary) -> void:
	var from_peer: = int(payload.get("from_peer", 0))
	var acct: = String(payload.get("account", ""))
	var nm: = String(payload.get("name", "Champion"))
	if ChatSystem:
		ChatSystem.announce_local("%s wants to be your friend. Accepting…" % nm)
	_add_friend(acct, nm)
	_rpc_friend_accept.rpc_id(from_peer, {
		"account": String(AccountSystem.username) if AccountSystem else "",
		"name": String(GameState.player_name),
	})


@rpc("any_peer", "reliable")
func _rpc_friend_accept(payload: Dictionary) -> void:
	_add_friend(String(payload.get("account", "")), String(payload.get("name", "Champion")))
	if ChatSystem:
		ChatSystem.announce_local("%s is now your friend." % String(payload.get("name", "Champion")))


func _add_friend(account: String, name: String) -> void:
	if is_friend(account, name):
		return
	friends.append({"account": account, "name": name})
	_persist_friends()
	friends_changed.emit()


func send_whisper(peer_id: int, text: String) -> String:
	text = text.strip_edges()
	if text == "" or not NetSession.is_online():
		return "Cannot whisper."
	var who: = String(GameState.player_name)
	_rpc_whisper.rpc_id(peer_id, who, text, multiplayer.get_unique_id())
	if ChatSystem:
		ChatSystem.announce_local("[Whisper →] %s" % text)
	return "Whisper sent."


@rpc("any_peer", "reliable")
func _rpc_whisper(from_name: String, text: String, from_peer: int) -> void:
	whisper_received.emit(from_name, text)
	if ChatSystem:
		ChatSystem.announce_local("[Whisper %s] %s" % [from_name, text])
	## Bubble on their avatar for local view of whisper? skip — private.


func request_trade(peer_id: int) -> String:
	if not NetSession.is_online():
		return "Go online first."
	_rpc_trade_invite.rpc_id(peer_id, multiplayer.get_unique_id(), String(GameState.player_name))
	return "Trade invite sent."


@rpc("any_peer", "reliable")
func _rpc_trade_invite(from_peer: int, from_name: String) -> void:
	_trade_peer = from_peer
	_my_offer.clear()
	_their_offer.clear()
	_trade_locked = false
	trade_opened.emit(from_peer, from_name)
	_rpc_trade_accept.rpc_id(from_peer, multiplayer.get_unique_id(), String(GameState.player_name))


@rpc("any_peer", "reliable")
func _rpc_trade_accept(from_peer: int, from_name: String) -> void:
	_trade_peer = from_peer
	_my_offer.clear()
	_their_offer.clear()
	_trade_locked = false
	trade_opened.emit(from_peer, from_name)


func set_trade_offer(item_ids: Array) -> void:
	_my_offer = item_ids.duplicate()
	if _trade_peer > 0 and NetSession.is_online():
		_rpc_trade_offer.rpc_id(_trade_peer, _my_offer)


@rpc("any_peer", "reliable")
func _rpc_trade_offer(items: Array) -> void:
	_their_offer = items.duplicate()
	trade_updated.emit({"theirs": _their_offer, "mine": _my_offer})


func confirm_trade() -> void:
	if _trade_peer <= 0:
		return
	_trade_locked = true
	_rpc_trade_confirm.rpc_id(_trade_peer, _my_offer)


@rpc("any_peer", "reliable")
func _rpc_trade_confirm(their_items: Array) -> void:
	_their_offer = their_items.duplicate()
	if not _trade_locked:
		trade_updated.emit({"theirs": _their_offer, "mine": _my_offer, "they_locked": true})
		return
	## Both locked — each side removes own offer and gains the other's.
	_finish_trade_local(_my_offer, _their_offer)
	_rpc_trade_finish.rpc_id(_trade_peer, _their_offer, _my_offer)
	close_trade()


@rpc("any_peer", "reliable")
func _rpc_trade_finish(i_give: Array, i_receive: Array) -> void:
	_finish_trade_local(i_give, i_receive)
	close_trade()


func _finish_trade_local(i_give: Array, i_receive: Array) -> void:
	for id in i_give:
		GameState.remove_one_from_bag(String(id))
	for id in i_receive:
		GameState.try_add_to_bag(String(id), 1)
	if ChatSystem:
		ChatSystem.announce_local("Trade complete.")
	if AccountSystem.is_logged_in():
		AccountSystem.save_game()


func close_trade() -> void:
	_trade_peer = 0
	_my_offer.clear()
	_their_offer.clear()
	_trade_locked = false
	trade_closed.emit()


func request_duel(peer_id: int) -> String:
	if not NetSession.is_online():
		return "Go online first."
	_rpc_duel_invite.rpc_id(peer_id, multiplayer.get_unique_id(), String(GameState.player_name))
	return "Duel challenge sent."


@rpc("any_peer", "reliable")
func _rpc_duel_invite(from_peer: int, from_name: String) -> void:
	## Auto-accept for playability (no modal stack); announce.
	if ChatSystem:
		ChatSystem.announce_local("%s challenged you to a duel — accepted!" % from_name)
	_begin_duel(from_peer)
	_rpc_duel_start.rpc_id(from_peer, multiplayer.get_unique_id())


@rpc("any_peer", "reliable")
func _rpc_duel_start(from_peer: int) -> void:
	_begin_duel(from_peer)


func _begin_duel(peer_id: int) -> void:
	duel_peer = peer_id
	duel_changed.emit(peer_id, true)
	var av = NetSession._avatars.get(peer_id) if NetSession else null
	if av != null and av.has_method("set_duel_active"):
		av.call("set_duel_active", true)
	if ChatSystem:
		ChatSystem.announce_local("Duel started! Winner takes a random item and 15%% gold.")


func end_duel() -> void:
	if duel_peer > 0:
		var av = NetSession._avatars.get(duel_peer) if NetSession else null
		if av != null and av.has_method("set_duel_active"):
			av.call("set_duel_active", false)
		if NetSession.is_online():
			_rpc_duel_end.rpc_id(duel_peer)
	duel_peer = 0
	duel_changed.emit(0, false)


@rpc("any_peer", "reliable")
func _rpc_duel_end() -> void:
	duel_peer = 0
	duel_changed.emit(0, false)
	for av in NetSession._avatars.values() if NetSession else []:
		if av != null and av.has_method("set_duel_active"):
			av.call("set_duel_active", false)


func is_dueling(peer_id: int) -> bool:
	return duel_peer != 0 and duel_peer == peer_id


func duel_death_drops() -> Dictionary:
	## 15% gold + one random bag item.
	var drops: Array = []
	var gold_take: = int(floor(float(GameState.gold) * 0.15))
	if gold_take > 0:
		GameState.spend_gold(gold_take)
	var bag_ids: Array = []
	for e in GameState.bag:
		if typeof(e) == TYPE_DICTIONARY:
			var id: = String(e.get("id", ""))
			if id != "" and id != "gold_coin":
				bag_ids.append(id)
	if not bag_ids.is_empty():
		bag_ids.shuffle()
		var pick: = String(bag_ids[0])
		if GameState.remove_one_from_bag(pick):
			drops.append(pick)
	return {"drops": drops, "gold": gold_take}
