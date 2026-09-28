extends Node
## ChatSystem — say-chat for players.
## Local-only until a multiplayer peer is connected; then messages fan out via RPC.
## Keep the payload tiny ({sender, text, t}) so a future dedicated server can
## relay the same shape without rewriting the HUD.

signal message_received(sender: String, text: String, stamp: float)
signal history_cleared

const MAX_HISTORY := 80
const MAX_CHARS := 120

## Recent lines for late-joining UI (or reconnect).
var history: Array = []  # [{sender, text, t}]


func _ready() -> void:
	## Warm the log so solo testers see the channel is live.
	_push_system("Press Enter to chat. Messages reach other players when multiplayer is online.")


func display_name() -> String:
	var acc := get_node_or_null("/root/AccountSystem")
	if acc != null and acc.has_method("is_logged_in") and bool(acc.call("is_logged_in")):
		var n := String(acc.get("display_name"))
		if n != "":
			return n
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		var pn := String(gs.get("player_name"))
		if pn != "":
			return pn
	return "Champion"


func is_networked() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return false
	## Godot boots with OfflineMultiplayerPeer — treat that as solo.
	if peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Send a public say. Works offline (local echo) and online (RPC to peers).
func send_say(text: String) -> bool:
	text = _sanitize(text)
	if text == "":
		return false
	var who := display_name()
	if is_networked():
		_rpc_chat.rpc(who, text)
	else:
		_deliver(who, text)
	return true


func _sanitize(text: String) -> String:
	text = text.strip_edges()
	text = text.replace("\n", " ").replace("\r", " ")
	if text.length() > MAX_CHARS:
		text = text.substr(0, MAX_CHARS)
	return text


@rpc("any_peer", "reliable", "call_local")
func _rpc_chat(sender: String, text: String) -> void:
	_deliver(String(sender), _sanitize(text))


func _push_system(text: String) -> void:
	_deliver("Herald", text)


## Local-only system line (not RPC'd). Use for host-only notices like joiner IPs.
func announce_local(text: String) -> void:
	_push_system(text)


func _deliver(sender: String, text: String) -> void:
	if text == "":
		return
	var stamp := Time.get_unix_time_from_system()
	history.append({"sender": sender, "text": text, "t": stamp})
	while history.size() > MAX_HISTORY:
		history.pop_front()
	message_received.emit(sender, text, stamp)


func clear_history() -> void:
	history.clear()
	history_cleared.emit()
	_push_system("Chat cleared.")
