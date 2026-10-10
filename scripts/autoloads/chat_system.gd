extends Node


signal message_received(sender: String, text: String, stamp: float, peer_id: int)
signal history_cleared

const MAX_HISTORY: = 80
const MAX_CHARS: = 120

var history: Array = []


func _ready() -> void:
	_push_system("Press Enter to chat. Browse Servers → Join → create/login, then enter the world.")


func display_name() -> String:
	var acc: = get_node_or_null("/root/AccountSystem")
	if acc != null and acc.has_method("is_logged_in") and bool(acc.call("is_logged_in")):
		var n: = String(acc.get("display_name"))
		if n != "":
			return n
	var gs: = get_node_or_null("/root/GameState")
	if gs != null:
		var pn: = String(gs.get("player_name"))
		if pn != "":
			return pn
	return "Champion"


func is_networked() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	var peer: = multiplayer.multiplayer_peer
	if peer == null:
		return false
	if peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func send_say(text: String) -> bool:
	text = _sanitize(text)
	if text == "":
		return false
	var who: = display_name()
	var pid: = multiplayer.get_unique_id() if is_networked() else 1
	if is_networked():
		_rpc_chat.rpc(who, text, pid)
	else:
		_deliver(who, text, pid)
	return true


func _sanitize(text: String) -> String:
	text = text.strip_edges()
	text = text.replace("\n", " ").replace("\r", " ")
	if text.length() > MAX_CHARS:
		text = text.substr(0, MAX_CHARS)
	return text


@rpc("any_peer", "reliable", "call_local")
func _rpc_chat(sender: String, text: String, peer_id: int = 0) -> void:
	var pid: = peer_id
	if pid == 0:
		pid = multiplayer.get_remote_sender_id()
	_deliver(String(sender), _sanitize(text), pid)


func _push_system(text: String) -> void:
	_deliver("Herald", text, 0)


func announce_local(text: String) -> void:
	## Host-only / local notices — never RPC'd to other peers.
	_push_system(text)


func _deliver(sender: String, text: String, peer_id: int = 0) -> void:
	if text == "":
		return
	var stamp: = Time.get_unix_time_from_system()
	history.append({"sender": sender, "text": text, "t": stamp, "peer": peer_id})
	while history.size() > MAX_HISTORY:
		history.pop_front()
	message_received.emit(sender, text, stamp, peer_id)


func clear_history() -> void:
	history.clear()
	history_cleared.emit()
	_push_system("Chat cleared.")
