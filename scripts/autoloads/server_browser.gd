extends Node



signal list_changed

const BEACON_PORT: = 7778
const BEACON_MAGIC: = "EOO1"
const BEACON_HZ: = 1.5
const LAN_STALE_SEC: = 5.0
const SAVE_PATH: = "user://multiplayer_servers.json"


var lan_servers: Dictionary = {}

var saved_servers: Array = []

var _udp: PacketPeerUDP
var _advertise: bool = false
var _adv_name: String = "Hellas World"
var _adv_port: int = 7777
var _adv_players: int = 1
var _adv_max: int = 8
var _beacon_accum: float = 0.0


func _ready() -> void :
	_load_saved()
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	var err: = _udp.bind(BEACON_PORT)
	if err != OK:
		push_warning("ServerBrowser: LAN bind failed (%s) — saved servers still work" % error_string(err))
		_udp = null


func _process(delta: float) -> void :
	_poll_lan()
	_expire_lan(delta)
	if _advertise:
		_beacon_accum += delta
		if _beacon_accum >= BEACON_HZ:
			_beacon_accum = 0.0
			_send_beacon()


func start_advertise(server_name: String, game_port: int, players: int = 1, max_players: int = 8) -> void :
	_adv_name = server_name.strip_edges()
	if _adv_name.is_empty():
		_adv_name = "Hellas World"
	_adv_port = game_port
	_adv_players = players
	_adv_max = max_players
	_advertise = true
	_beacon_accum = BEACON_HZ
	list_changed.emit()


func update_advertise(players: int, max_players: int = 8) -> void :
	_adv_players = players
	_adv_max = max_players


func stop_advertise() -> void :
	_advertise = false
	list_changed.emit()


func is_advertising() -> bool:
	return _advertise


func advertised_name() -> String:
	return _adv_name


func add_saved_server(server_name: String, address: String, port: int = 7777) -> String:
	server_name = server_name.strip_edges()
	address = address.strip_edges()
	if server_name.is_empty():
		return "Enter a server name."
	if address.is_empty():
		return "Enter a join address (host keeps this private in the list)."

	var net: = get_node_or_null("/root/NetSession")
	if net != null and net.has_method("parse_address"):
		var parsed: Dictionary = net.call("parse_address", address, port)
		address = String(parsed.get("address", address))
		port = int(parsed.get("port", port))
	for s in saved_servers:
		if String(s.get("name", "")) == server_name:
			s["address"] = address
			s["port"] = port
			_save_saved()
			list_changed.emit()
			return "Updated saved server '%s'." % server_name
	saved_servers.append({"name": server_name, "address": address, "port": port})
	_save_saved()
	list_changed.emit()
	return "Saved server '%s'." % server_name


func remove_saved_server(server_name: String) -> void :
	var keep: Array = []
	for s in saved_servers:
		if String(s.get("name", "")) != server_name:
			keep.append(s)
	saved_servers = keep
	_save_saved()
	list_changed.emit()



func list_rows() -> Array:
	var rows: Array = []
	var seen_names: Dictionary = {}
	for id in lan_servers.keys():
		var s: Dictionary = lan_servers[id]
		var nm: = String(s.get("name", "LAN World"))
		seen_names[nm] = true
		rows.append({
			"name": nm, 
			"detail": "LAN · %d/%d online" % [int(s.get("players", 1)), int(s.get("max_players", 8))], 
			"source": "lan", 
			"address": String(s.get("address", "")), 
			"port": int(s.get("port", 7777)), 
		})
	for s in saved_servers:
		var nm: = String(s.get("name", "Server"))
		if seen_names.has(nm):
			continue
		rows.append({
			"name": nm, 
			"detail": "Saved · join when host is online", 
			"source": "saved", 
			"address": String(s.get("address", "")), 
			"port": int(s.get("port", 7777)), 
		})
	return rows


func _send_beacon() -> void :
	if _udp == null:
		return
	var payload: = "%s|%s|%d|%d|%d" % [
		BEACON_MAGIC, _adv_name.replace("|", "/"), _adv_port, _adv_players, _adv_max
	]
	_udp.set_dest_address("255.255.255.255", BEACON_PORT)
	_udp.put_packet(payload.to_utf8_buffer())


func _poll_lan() -> void :
	if _udp == null:
		return
	var changed: = false
	while _udp.get_available_packet_count() > 0:
		var packet: = _udp.get_packet()
		var from_ip: = _udp.get_packet_ip()
		var text: = packet.get_string_from_utf8()
		var parsed: = _parse_beacon(text)
		if parsed.is_empty():
			continue

		if _advertise and int(parsed.port) == _adv_port and String(parsed.name) == _adv_name:
			continue
		var id: = "%s:%d" % [from_ip, int(parsed.port)]
		var prev: Dictionary = lan_servers.get(id, {})
		lan_servers[id] = {
			"name": String(parsed.name), 
			"address": from_ip, 
			"port": int(parsed.port), 
			"players": int(parsed.players), 
			"max_players": int(parsed.max_players), 
			"seen": 0.0, 
		}
		if prev.is_empty() or String(prev.get("name", "")) != String(parsed.name)\
		or int(prev.get("players", -1)) != int(parsed.players):
			changed = true
	if changed:
		list_changed.emit()


func _expire_lan(delta: float) -> void :
	var drop: Array = []
	for id in lan_servers.keys():
		var s: Dictionary = lan_servers[id]
		s["seen"] = float(s.get("seen", 0.0)) + delta
		lan_servers[id] = s
		if float(s["seen"]) > LAN_STALE_SEC:
			drop.append(id)
	if drop.is_empty():
		return
	for id in drop:
		lan_servers.erase(id)
	list_changed.emit()


func _parse_beacon(text: String) -> Dictionary:
	var parts: = text.split("|")
	if parts.size() < 5:
		return {}
	if parts[0] != BEACON_MAGIC:
		return {}
	if not String(parts[2]).is_valid_int():
		return {}
	return {
		"name": String(parts[1]).strip_edges(), 
		"port": clampi(int(parts[2]), 1, 65535), 
		"players": clampi(int(parts[3]), 0, 64), 
		"max_players": clampi(int(parts[4]), 1, 64), 
	}


func _load_saved() -> void :
	saved_servers.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f: = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Array:
		for item in data:
			if item is Dictionary and String(item.get("name", "")) != "":
				saved_servers.append({
					"name": String(item.get("name", "")), 
					"address": String(item.get("address", "")), 
					"port": int(item.get("port", 7777)), 
				})


func _save_saved() -> void :
	var f: = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(saved_servers))
	f.close()
