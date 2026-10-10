extends Node3D
## Small horse + cart caravan that shuttles along a Hellenic road.
## Escorts are peaceful until struck — then the whole group aggroes.


const EnemyScript = preload("res://scripts/enemy.gd")
const CART_PATH: = "res://assets/environment/obstacles/olive_cart.glb"
const HORSE_PATH: = "res://assets/characters/horse/animal_horse.glb"

const SPEED: = 3.4
const RESPAWN_S: = 90.0
const MEMBER_LATERAL: = 1.8
const CART_BACK: = 3.2
const HORSE_FORWARD: = 2.8
const HORSE_HEIGHT: = 2.05
const CART_HEIGHT: = 2.3
## Far caravans skip path snaps / escort teleports until the player approaches.
const FAR_SLEEP_DIST: = 120.0
const FAR_SLEEP_DIST_SQ: = FAR_SLEEP_DIST * FAR_SLEEP_DIST
const FAR_SLEEP_TICK: = 0.5

var road_name: String = ""
var path_pts: Array = [] ## Array[Vector2]
var progress_m: float = 0.0
var going_forward: bool = true
var fighting: bool = false
var _path_len: float = 0.0
var _seg_cum: Array = [] ## cumulative lengths at each point
var _world: Node = null
var _horse: Node3D = null
var _cart: Node3D = null
var _members: Array = [] ## Enemy CharacterBody3D
var _moving: bool = false
var _rng: = RandomNumberGenerator.new()
var _far_timer: float = 0.0
var _player: Node3D = null


static func create(p_road_name: String, pts: Array, start_frac: float, seed_i: int) -> Node3D:
	var n: = Node3D.new()
	n.set_script(load("res://scripts/world/road_caravan.gd"))
	n.road_name = p_road_name
	n.path_pts = pts.duplicate()
	n._rng.seed = seed_i
	n.progress_m = clampf(start_frac, 0.02, 0.98) ## filled after _ready computes length
	n.set_meta("_start_frac", start_frac)
	return n


func is_moving() -> bool:
	return _moving and not fighting


func _ready() -> void:
	add_to_group("road_caravans")
	_world = get_tree().get_first_node_in_group("game_world")
	_build_path_cache()
	var frac: float = float(get_meta("_start_frac", 0.25))
	progress_m = clampf(frac, 0.05, 0.95) * maxf(_path_len, 1.0)
	going_forward = _rng.randf() > 0.5
	_spawn_props()
	_spawn_escorts()
	_snap_to_progress(true)


func _build_path_cache() -> void:
	_seg_cum.clear()
	_path_len = 0.0
	_seg_cum.append(0.0)
	for i in range(path_pts.size() - 1):
		var a: Vector2 = path_pts[i]
		var b: Vector2 = path_pts[i + 1]
		_path_len += a.distance_to(b)
		_seg_cum.append(_path_len)


func _spawn_props() -> void:
	_horse = _instance_glb(HORSE_PATH, HORSE_HEIGHT)
	_cart = _instance_glb(CART_PATH, CART_HEIGHT)


func _instance_glb(path: String, height_m: float) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var obj: Node3D = scene.instantiate()
	add_child(obj)
	if height_m > 0.0:
		ModelUtils.scale_to_height(obj, height_m)
	return obj


func _spawn_escorts() -> void:
	var ids: Array = ["caravan_guard", "caravan_bandit", "caravan_bandit"]
	for i in ids.size():
		var e: CharacterBody3D = EnemyScript.create(String(ids[i]), global_position)
		e.caravan = self
		_world.add_child(e) if _world != null else add_child(e)
		_members.append(e)
		if NetSession and NetSession.is_hosting():
			NetSession.host_register_enemy(e)
		e.enemy_died.connect(_on_member_died)


func _on_member_died(_id: String, _pos: Vector3) -> void:
	## If the whole escort is gone, despawn props and respawn later.
	call_deferred("_check_wipe")


func _check_wipe() -> void:
	var alive: = 0
	for m in _members:
		if m != null and is_instance_valid(m) and not bool(m.get("dead")):
			alive += 1
	if alive > 0:
		return
	if _horse != null:
		_horse.visible = false
	if _cart != null:
		_cart.visible = false
	fighting = false
	_moving = false
	var t: = get_tree().create_timer(RESPAWN_S)
	t.timeout.connect(_respawn_caravan)


func _respawn_caravan() -> void:
	if NetSession and NetSession.is_online() and not NetSession.is_hosting():
		return
	## Clear stale refs and rebuild escorts at a random point on the road.
	_members.clear()
	progress_m = _rng.randf_range(0.1, 0.9) * maxf(_path_len, 1.0)
	going_forward = _rng.randf() > 0.5
	fighting = false
	if _horse != null:
		_horse.visible = true
	if _cart != null:
		_cart.visible = true
	_spawn_escorts()
	_snap_to_progress(true)


func on_member_aggro(who: Node) -> void:
	if fighting:
		return
	fighting = true
	_moving = false
	const ST_IDLE: = 0
	const ST_CHASE: = 1
	for m in _members:
		if m == null or not is_instance_valid(m) or bool(m.get("dead")):
			continue
		if m == who:
			continue
		## Pull the rest of the convoy into the fight.
		if int(m.get("state")) == ST_IDLE:
			m.set("state", ST_CHASE)
			if m.has_method("_telegraph_aggro"):
				m._telegraph_aggro()


func _physics_process(delta: float) -> void:
	if path_pts.size() < 2 or _path_len < 1.0:
		return
	if fighting:
		_update_fighting()
		return
	## Sleep when the player is far — 6 caravans * escorts was a steady CPU tax.
	if _player == null or not is_instance_valid(_player):
		if _world != null:
			_player = _world.get("player") as Node3D
		if _player == null:
			_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player != null:
		var d2: = global_position.distance_squared_to(_player.global_position)
		if d2 > FAR_SLEEP_DIST_SQ:
			_moving = false
			_far_timer -= delta
			if _far_timer > 0.0:
				return
			_far_timer = FAR_SLEEP_TICK
			## Cheap catch-up so the convoy isn't frozen forever at one spot.
			var dir_far: float = 1.0 if going_forward else -1.0
			progress_m += SPEED * dir_far * FAR_SLEEP_TICK
			if progress_m >= _path_len:
				progress_m = _path_len
				going_forward = false
			elif progress_m <= 0.0:
				progress_m = 0.0
				going_forward = true
			_snap_to_progress(false)
			return
	_far_timer = 0.0
	_moving = true
	var dir: float = 1.0 if going_forward else -1.0
	progress_m += SPEED * dir * delta
	if progress_m >= _path_len:
		progress_m = _path_len
		going_forward = false
	elif progress_m <= 0.0:
		progress_m = 0.0
		going_forward = true
	_snap_to_progress(false)


func _update_fighting() -> void:
	## Resume the road once every living escort has calmed down.
	const ST_CHASE: = 1
	const ST_ATTACK: = 2
	const ST_HIT: = 3
	var any_alive: = false
	var any_fighting: = false
	for m in _members:
		if m == null or not is_instance_valid(m) or bool(m.get("dead")):
			continue
		any_alive = true
		var st: int = int(m.get("state"))
		if st == ST_CHASE or st == ST_ATTACK or st == ST_HIT:
			any_fighting = true
	if not any_alive:
		fighting = false
		return
	if not any_fighting:
		fighting = false
		_snap_to_progress(true)


func _snap_to_progress(force_face: bool) -> void:
	var sample: Dictionary = _sample_at(progress_m)
	var pos2: Vector2 = sample["pos"]
	var yaw: float = float(sample["yaw"])
	var y: float = 0.0
	if _world != null and _world.has_method("sample_height"):
		y = float(_world.sample_height(pos2.x, pos2.y))
	var origin: = Vector3(pos2.x, y, pos2.y)
	var forward: = Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right: = Vector3(cos(yaw), 0.0, -sin(yaw))
	global_position = origin
	if _horse != null:
		_horse.global_position = origin + forward * HORSE_FORWARD
		_horse.rotation.y = yaw
		if _world != null and _world.has_method("sample_height"):
			_horse.global_position.y = float(_world.sample_height(_horse.global_position.x, _horse.global_position.z))
	if _cart != null:
		_cart.global_position = origin - forward * CART_BACK
		_cart.rotation.y = yaw
		if _world != null and _world.has_method("sample_height"):
			_cart.global_position.y = float(_world.sample_height(_cart.global_position.x, _cart.global_position.z))
	## Escort slots: left, right, trailing left.
	var slots: Array[Vector3] = [
		right * MEMBER_LATERAL + forward * 0.4,
		-right * MEMBER_LATERAL + forward * 0.2,
		-right * (MEMBER_LATERAL * 0.6) - forward * 1.8,
	]
	for i in _members.size():
		var m: Node = _members[i]
		if m == null or not is_instance_valid(m) or bool(m.get("dead")):
			continue
		## While fighting, leave AI in control of position.
		if fighting and int(m.get("state")) != 0:
			continue
		var slot: Vector3 = slots[mini(i, slots.size() - 1)]
		var mp: = origin + slot
		if _world != null and _world.has_method("sample_height"):
			mp.y = float(_world.sample_height(mp.x, mp.z)) + 0.05
		else:
			mp.y = y + 0.05
		m.global_position = mp
		m.set("spawn_point", mp)
		m.set("wander_target", mp)
		if force_face or is_moving():
			var mesh: Node3D = m.get("mesh_root") as Node3D
			if mesh != null:
				var facing_off: float = 180.0
				var cfg_v = m.get("cfg")
				if cfg_v is Dictionary:
					facing_off = float((cfg_v as Dictionary).get("facing_yaw_deg", 180.0))
				mesh.rotation.y = yaw + deg_to_rad(facing_off)


func _sample_at(dist_m: float) -> Dictionary:
	var d: float = clampf(dist_m, 0.0, _path_len)
	for i in range(path_pts.size() - 1):
		var a_cum: float = float(_seg_cum[i])
		var b_cum: float = float(_seg_cum[i + 1])
		if d <= b_cum or i == path_pts.size() - 2:
			var seg: float = maxf(b_cum - a_cum, 0.001)
			var t: float = clampf((d - a_cum) / seg, 0.0, 1.0)
			var a: Vector2 = path_pts[i]
			var b: Vector2 = path_pts[i + 1]
			var pos: Vector2 = a.lerp(b, t)
			var yaw: float = atan2(-(b.x - a.x), -(b.y - a.y))
			if not going_forward:
				yaw += PI
			return {"pos": pos, "yaw": yaw}
	return {"pos": path_pts[0], "yaw": 0.0}
