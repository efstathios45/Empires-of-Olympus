extends SceneTree


func _init() -> void :
	call_deferred("run")


func run() -> void :
	var browser: = get_root().get_node_or_null("ServerBrowser")
	var net: = get_root().get_node_or_null("NetSession")
	var chat: = get_root().get_node_or_null("ChatSystem")
	assert (browser != null, "ServerBrowser autoload missing")
	assert (net != null, "NetSession autoload missing")
	assert (chat != null, "ChatSystem autoload missing")


	var msg: String = browser.add_saved_server("Alex World", "203.0.113.50:7777")
	assert (msg.contains("Alex World"))
	var rows: Array = browser.list_rows()
	var found: = false
	for row in rows:
		if String(row.get("name", "")) != "Alex World":
			continue
		found = true
		var detail: = String(row.get("detail", ""))
		assert ( not detail.contains("203.0.113"), "list detail leaked IP: %s" % detail)

		assert (String(row.get("address", "")) == "203.0.113.50")
		assert (int(row.get("port", 0)) == 7777)

		var label: = "%s\n%s" % [String(row.get("name", "")), detail]
		assert ( not label.contains("203.0.113"))
		assert ( not label.contains(":7777"))
	assert (found, "saved server row missing")


	var pending: String = net.set_pending_join("198.51.100.9:9001", "Forge Arena")
	assert (net.pending_join_address == "198.51.100.9")
	assert (net.pending_join_port == 9001)
	assert (pending.contains("Forge Arena"))
	assert ( not pending.contains("198.51.100"))
	net.clear_pending_join()


	assert (String(net.invite_text()) == "")


	assert (chat.has_method("announce_local"))
	chat.announce_local("Player connected from 127.0.0.1 (peer 2) — host notice only.")
	assert (chat.history.size() > 0)
	var last: Dictionary = chat.history[chat.history.size() - 1]
	assert (String(last.get("sender", "")) == "Herald")
	assert (String(last.get("text", "")).contains("127.0.0.1"))

	browser.remove_saved_server("Alex World")
	print("SMOKE_SERVER_BROWSER_OK")
	quit(0)
