extends SceneTree
## RMB social menu + invite accept/decline wiring.


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var s = get_root().get_node_or_null("SocialSystem")
	var p = get_root().get_node_or_null("PartyShare")
	if s == null or p == null:
		print("FAIL autoloads")
		quit(1)
		return
	for m in ["queue_invite", "respond_invite", "send_friend_request", "request_trade", "request_duel"]:
		if not s.has_method(m):
			print("FAIL missing SocialSystem.", m)
			quit(1)
			return
	if not p.has_method("decline_invite"):
		print("FAIL PartyShare.decline_invite")
		quit(1)
		return
	var Menu = load("res://scripts/ui/panel_player_menu.gd")
	var Inv = load("res://scripts/ui/panel_social_invite.gd")
	var Wh = load("res://scripts/ui/panel_whisper.gd")
	if Menu == null or Inv == null or Wh == null:
		print("FAIL panels")
		quit(1)
		return
	## Invite queues without auto-accept
	var got: = {"n": 0}
	s.invite_received.connect(func(kind, peer, name, data):
		got["n"] = int(got["n"]) + 1
		print("invite kind=", kind, " from=", name)
	)
	s.queue_invite("friend", 2, "Leonidas", {"account": "leo", "name": "Leonidas"})
	s.queue_invite("party", 2, "Leonidas", {"roster": {}, "leader": 2})
	if int(got["n"]) != 2:
		print("FAIL invite signals ", got["n"])
		quit(1)
		return
	## Respond friend accept adds friend
	s.respond_invite("friend", 2, true, {"account": "leo", "name": "Leonidas"})
	if not s.is_friend("leo", "Leonidas"):
		print("FAIL friend not added")
		quit(1)
		return
	print("SMOKE_SOCIAL_MENU_OK")
	quit(0)
