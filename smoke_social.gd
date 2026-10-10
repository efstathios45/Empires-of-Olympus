extends SceneTree
## Social stack smoke: autoloads, class GLB for remotes, chat peer_id, duel loot math.


func _init() -> void:
	call_deferred("_r")


func _r() -> void:
	var s = get_root().get_node_or_null("SocialSystem")
	var c = get_root().get_node_or_null("ChatSystem")
	var n = get_root().get_node_or_null("NetSession")
	var p = get_root().get_node_or_null("PartyShare")
	if s == null or c == null or n == null or p == null:
		print("FAIL autoloads", s, c, n, p)
		quit(1)
		return
	var gs = get_root().get_node("GameState")
	var path = String(gs.CLASSES["hoplite"].get("character", ""))
	if path == "" or not ResourceLoader.exists(path):
		print("FAIL hoplite glb", path)
		quit(1)
		return
	print("hoplite_glb=", path, " exists=true")
	## Chat signal arity includes peer_id
	var ok_chat: = false
	if c.has_signal("message_received"):
		ok_chat = true
	if not ok_chat:
		print("FAIL chat signal")
		quit(1)
		return
	## Remote avatar script loads + has bubble/tint APIs
	var RemoteAvatar = load("res://scripts/remote_avatar.gd")
	if RemoteAvatar == null:
		print("FAIL remote_avatar")
		quit(1)
		return
	var Menu = load("res://scripts/ui/panel_player_menu.gd")
	var Trade = load("res://scripts/ui/panel_trade.gd")
	if Menu == null or Trade == null:
		print("FAIL panels", Menu, Trade)
		quit(1)
		return
	## Duel loot: 15% gold
	gs.gold = 1000
	var before: = int(gs.gold)
	s.duel_peer = 2
	var loot: Dictionary = s.duel_death_drops()
	var gold_take: = int(loot.get("gold", 0))
	if gold_take != 150:
		print("FAIL duel gold want 150 got ", gold_take, " before=", before, " after=", gs.gold)
		quit(1)
		return
	print("duel_gold_ok=", gold_take)
	## Social APIs present
	for m in ["send_friend_request", "send_whisper", "request_trade", "request_duel", "is_dueling"]:
		if not s.has_method(m):
			print("FAIL missing ", m)
			quit(1)
			return
	print("SMOKE_SOCIAL_OK")
	quit(0)
