extends Node
## AccountSystem — local username/password accounts + local saves (default).
## Local: hashed credentials in user://accounts.json, saves in user://saves/<user>.json
##
## Multiplayer / shared readiness: keep GameState.to_save_dict() as the single
## snapshot format. Flip CLOUD_ENABLED and point sync_url at cloud_sync/ (or a
## future game-server) when you want cross-device or authoritative multiplayer
## persistence. See docs/ACCOUNTS.md.

signal auth_changed
signal sync_finished(ok: bool, message: String)
signal save_finished(ok: bool, message: String)

const ACCOUNTS_PATH := "user://accounts.json"
const SAVES_DIR := "user://saves"
const SESSION_PATH := "user://session.json"
const SAVE_VERSION := 1

## Local-only until a shared backend is hosted. Cloud code paths stay wired.
const CLOUD_ENABLED := false

## When CLOUD_ENABLED, set this (or user://sync_url.txt) to the sync API root.
var sync_url: String = ""

var username: String = ""
var auth_token: String = ""
var display_name: String = ""
var last_error: String = ""
var _http: HTTPRequest
var _pending: String = ""  # register | login | push | pull
var _busy: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_http)
	if CLOUD_ENABLED:
		_load_sync_url_override()
	else:
		sync_url = ""
	_restore_session()


func cloud_available() -> bool:
	return CLOUD_ENABLED and sync_url != ""


func is_logged_in() -> bool:
	return username != ""


func has_local_save(user: String = "") -> bool:
	var u := user if user != "" else username
	if u == "":
		return false
	return FileAccess.file_exists(_save_path(u))


func read_local_save(user: String = "") -> Dictionary:
	var u := user if user != "" else username
	if u == "" or not has_local_save(u):
		return {}
	var f := FileAccess.open(_save_path(u), FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _save_path(user: String) -> String:
	var safe := user.to_lower().strip_edges().replace("/", "_").replace("\\", "_")
	return "%s/%s.json" % [SAVES_DIR, safe]


func _load_sync_url_override() -> void:
	if FileAccess.file_exists("user://sync_url.txt"):
		var f := FileAccess.open("user://sync_url.txt", FileAccess.READ)
		if f:
			var line := f.get_as_text().strip_edges()
			f.close()
			if line.begins_with("http"):
				sync_url = line.trim_suffix("/")


func _hash_password(password: String, salt: String) -> String:
	return (salt + ":" + password).sha256_text()


func _new_salt() -> String:
	return str(Time.get_unix_time_from_system()) + "-" + str(randi())


func _load_accounts() -> Dictionary:
	if not FileAccess.file_exists(ACCOUNTS_PATH):
		return {"users": {}}
	var f := FileAccess.open(ACCOUNTS_PATH, FileAccess.READ)
	if f == null:
		return {"users": {}}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"users": {}}
	if not parsed.has("users") or typeof(parsed["users"]) != TYPE_DICTIONARY:
		parsed["users"] = {}
	return parsed


func _write_accounts(data: Dictionary) -> bool:
	var f := FileAccess.open(ACCOUNTS_PATH, FileAccess.WRITE)
	if f == null:
		last_error = "Could not write accounts file."
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


func _persist_session() -> void:
	var f := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"username": username,
		"token": auth_token,
		"display_name": display_name,
	}, "\t"))
	f.close()


func _restore_session() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var f := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	username = String(parsed.get("username", ""))
	auth_token = String(parsed.get("token", ""))
	display_name = String(parsed.get("display_name", username))


func logout() -> void:
	username = ""
	auth_token = ""
	display_name = ""
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)
	auth_changed.emit()


## Create a local account. Optionally registers on the cloud API too.
func register(user: String, password: String, hero_name: String = "") -> bool:
	user = user.strip_edges().to_lower()
	password = password.strip_edges()
	if user.length() < 3 or user.length() > 24:
		last_error = "Username must be 3–24 characters."
		return false
	if not _valid_username(user):
		last_error = "Username: letters, numbers, underscore only."
		return false
	if password.length() < 6:
		last_error = "Password must be at least 6 characters."
		return false
	var db := _load_accounts()
	var users: Dictionary = db["users"]
	if users.has(user):
		last_error = "That username is already taken on this device."
		return false
	var salt := _new_salt()
	users[user] = {
		"salt": salt,
		"hash": _hash_password(password, salt),
		"display_name": hero_name.strip_edges() if hero_name.strip_edges() != "" else user.capitalize(),
		"created_at": Time.get_unix_time_from_system(),
	}
	if not _write_accounts(db):
		return false
	username = user
	display_name = String(users[user]["display_name"])
	auth_token = ""
	_persist_session()
	auth_changed.emit()
	## Optional cloud register when a shared backend is enabled.
	if cloud_available():
		_cloud_register(user, password, display_name)
	last_error = ""
	return true


## Login against local accounts; if unknown locally, try cloud then cache.
func login(user: String, password: String) -> bool:
	user = user.strip_edges().to_lower()
	password = password.strip_edges()
	if user == "" or password == "":
		last_error = "Enter username and password."
		return false
	var db := _load_accounts()
	var users: Dictionary = db["users"]
	if users.has(user):
		var rec: Dictionary = users[user]
		var expect := String(rec.get("hash", ""))
		var salt := String(rec.get("salt", ""))
		if _hash_password(password, salt) != expect:
			last_error = "Wrong password."
			return false
		username = user
		display_name = String(rec.get("display_name", user))
		_persist_session()
		auth_changed.emit()
		if cloud_available():
			_cloud_login(user, password)
		last_error = ""
		return true
	## Not on this device — only recoverable via a shared backend.
	if not cloud_available():
		last_error = "Unknown account on this device."
		return false
	last_error = "Contacting sync server…"
	_cloud_login(user, password, true)
	return true  # async; UI should wait on sync_finished


func _valid_username(user: String) -> bool:
	var re := RegEx.new()
	re.compile("^[a-z0-9_]{3,24}$")
	return re.search(user) != null


## Runtime lookup avoids compile-time dependency on the GameState autoload name.
func _game_state() -> Node:
	return get_node_or_null("/root/GameState")


func save_game(extra: Dictionary = {}) -> bool:
	if not is_logged_in():
		last_error = "Log in to save your legend."
		return false
	var gs := _game_state()
	if gs == null or not gs.has_method("to_save_dict"):
		last_error = "Game state unavailable."
		return false
	var payload: Dictionary = gs.call("to_save_dict")
	payload["saved_at"] = Time.get_unix_time_from_system()
	payload["account"] = username
	payload["display_name"] = display_name
	for k in extra:
		payload[k] = extra[k]
	var path := _save_path(username)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		last_error = "Could not write save file."
		save_finished.emit(false, last_error)
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	last_error = ""
	save_finished.emit(true, "Saved.")
	if cloud_available() and auth_token != "":
		_cloud_push(payload)
	return true


func load_game() -> bool:
	if not is_logged_in():
		last_error = "Log in first."
		return false
	var path := _save_path(username)
	if not FileAccess.file_exists(path):
		last_error = "No save yet — start a new legend."
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		last_error = "Could not read save file."
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Save file corrupted."
		return false
	var gs := _game_state()
	if gs == null or not gs.has_method("apply_save_dict"):
		last_error = "Game state unavailable."
		return false
	if not bool(gs.call("apply_save_dict", parsed)):
		last_error = "Could not apply save."
		return false
	if parsed.has("display_name"):
		display_name = String(parsed["display_name"])
		gs.set("player_name", display_name)
	last_error = ""
	return true


func request_cloud_pull() -> void:
	if not cloud_available() or auth_token == "":
		sync_finished.emit(false, "Shared sync is off (local saves only).")
		return
	_cloud_pull()


func request_cloud_push() -> void:
	if not cloud_available():
		sync_finished.emit(false, "Shared sync is off (local saves only).")
		return
	if not is_logged_in():
		sync_finished.emit(false, "Log in first.")
		return
	var path := _save_path(username)
	if not FileAccess.file_exists(path):
		save_game()
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text()) if f else null
	if f:
		f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		sync_finished.emit(false, "No save to upload.")
		return
	_cloud_push(parsed)


# ── HTTP helpers ─────────────────────────────────────────────────────────

func _headers(with_auth: bool = false) -> PackedStringArray:
	var h := PackedStringArray(["Content-Type: application/json"])
	if with_auth and auth_token != "":
		h.append("Authorization: Bearer %s" % auth_token)
	return h


func _cloud_register(user: String, password: String, hero: String) -> void:
	if _busy:
		return
	_busy = true
	_pending = "register"
	var body := JSON.stringify({"username": user, "password": password, "display_name": hero})
	var err := _http.request(sync_url + "/v1/register", _headers(), HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false
		_pending = ""
		push_warning("AccountSystem: cloud register failed to start (%s)" % err)


func _cloud_login(user: String, password: String, cache_local: bool = false) -> void:
	if _busy:
		return
	_busy = true
	_pending = "login_cache" if cache_local else "login"
	var body := JSON.stringify({"username": user, "password": password})
	## Stash password salt material for local cache via meta on node — keep brief.
	set_meta("_login_user", user)
	set_meta("_login_pass", password)
	var err := _http.request(sync_url + "/v1/login", _headers(), HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false
		_pending = ""
		last_error = "Could not reach sync server."
		sync_finished.emit(false, last_error)


func _cloud_push(payload: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	_pending = "push"
	var body := JSON.stringify({"save": payload})
	var err := _http.request(sync_url + "/v1/save", _headers(true), HTTPClient.METHOD_PUT, body)
	if err != OK:
		_busy = false
		_pending = ""
		sync_finished.emit(false, "Upload failed to start.")


func _cloud_pull() -> void:
	if _busy:
		return
	_busy = true
	_pending = "pull"
	var err := _http.request(sync_url + "/v1/save", _headers(true), HTTPClient.METHOD_GET)
	if err != OK:
		_busy = false
		_pending = ""
		sync_finished.emit(false, "Download failed to start.")


func _on_http(_result: int, code: int, _headers_arr: PackedStringArray, body: PackedByteArray) -> void:
	var pending := _pending
	_pending = ""
	_busy = false
	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text) if text != "" else null
	if typeof(data) != TYPE_DICTIONARY:
		data = {}

	match pending:
		"register":
			if code >= 200 and code < 300:
				auth_token = String(data.get("token", ""))
				_persist_session()
				sync_finished.emit(true, "Account linked to cloud.")
			else:
				sync_finished.emit(false, String(data.get("detail", "Cloud register failed (%d)." % code)))
		"login", "login_cache":
			if code >= 200 and code < 300:
				auth_token = String(data.get("token", ""))
				username = String(data.get("username", get_meta("_login_user", "")))
				display_name = String(data.get("display_name", username))
				if pending == "login_cache":
					_cache_cloud_user_locally(username, String(get_meta("_login_pass", "")), display_name)
				_persist_session()
				auth_changed.emit()
				last_error = ""
				sync_finished.emit(true, "Signed in.")
				## Auto-pull cloud save after remote login
				call_deferred("request_cloud_pull")
			else:
				last_error = String(data.get("detail", "Login failed (%d)." % code))
				sync_finished.emit(false, last_error)
			if has_meta("_login_pass"):
				remove_meta("_login_pass")
		"push":
			if code >= 200 and code < 300:
				sync_finished.emit(true, "Cloud save updated.")
			else:
				sync_finished.emit(false, String(data.get("detail", "Upload failed (%d)." % code)))
		"pull":
			if code == 404:
				sync_finished.emit(false, "No cloud save yet — play and save once.")
			elif code >= 200 and code < 300:
				var save = data.get("save", data)
				if typeof(save) != TYPE_DICTIONARY:
					sync_finished.emit(false, "Bad cloud save payload.")
					return
				## Write local copy, then apply if we're about to continue.
				var path := _save_path(username if username != "" else String(save.get("account", "guest")))
				var f := FileAccess.open(path, FileAccess.WRITE)
				if f:
					f.store_string(JSON.stringify(save, "\t"))
					f.close()
				sync_finished.emit(true, "Cloud save downloaded.")
			else:
				sync_finished.emit(false, String(data.get("detail", "Download failed (%d)." % code)))


func _cache_cloud_user_locally(user: String, password: String, hero: String) -> void:
	var db := _load_accounts()
	var users: Dictionary = db["users"]
	if users.has(user):
		return
	var salt := _new_salt()
	users[user] = {
		"salt": salt,
		"hash": _hash_password(password, salt),
		"display_name": hero,
		"created_at": Time.get_unix_time_from_system(),
		"from_cloud": true,
	}
	_write_accounts(db)
