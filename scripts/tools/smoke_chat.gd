extends SceneTree



func _init() -> void :
	call_deferred("_run")


func _run() -> void :
	var chat: = get_root().get_node_or_null("ChatSystem")
	if chat == null:
		push_error("ChatSystem missing")
		quit(1)
		return
	var got: Array = []
	chat.message_received.connect( func(s: String, t: String, _st: float) -> void :
		got.append("%s:%s" % [s, t])
	)
	if not bool(chat.call("send_say", "  Hail, Hellas!  ")):
		push_error("send_say failed")
		quit(1)
		return

	if bool(chat.call("send_say", "   ")):
		push_error("empty say should fail")
		quit(1)
		return
	var hist: Array = chat.get("history")
	var found: = false
	for e in hist:
		if typeof(e) == TYPE_DICTIONARY and String(e.get("text", "")) == "Hail, Hellas!":
			found = true
			break
	if not found:
		push_error("history missing line")
		quit(1)
		return
	print("SMOKE_CHAT_OK lines=", hist.size(), " networked=", chat.call("is_networked"))
	quit(0)
