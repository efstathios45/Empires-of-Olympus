extends CharacterBody3D
## Player — third-person action RPG controller: orbit camera, sprint, jump,
## dodge roll, block, 3-hit melee combo / ranged shots, class skill, HP/MP.

signal health_changed(hp: float, max_hp: float)
signal mana_changed(mp: float, max_mp: float)
signal died
signal respawned
signal skill_cooldown_started(duration: float)
signal combo_performed

const HeroAnimScript = preload("res://scripts/hero_anim.gd")
const WeaponGrip = preload("res://scripts/weapon_grip.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const VfxHelper = preload("res://scripts/vfx_helper.gd")
const KAYKIT_MODEL := "res://assets/characters/spartan_hoplite/spartan_hoplite.glb"
const KAYKIT_LIB := "res://assets/characters/spartan_hoplite/spartan_hoplite_animations.tres"

const WALK_SPEED := 3.4
const SPRINT_SPEED := 6.4
const JUMP_VELOCITY := 7.0
const GRAVITY := 22.0
const TURN_RATE := 14.0
const MOUSE_SENS := 0.0022

# Clip names live in hero_anim.gd so each class can point at its own rig.

# Footsteps are driven by distance travelled, so they always match the stride
# no matter how the move speed is tuned.
const STEP_DIST_WALK := 2.2
const STEP_DIST_SPRINT := 2.8

# Soft lock-on: widest cone/range the target highlight considers.
const TARGET_RANGE := 24.0
const TARGET_DOT := 0.7
const TARGET_TICK := 0.15

enum State { FREE, ATTACK, DODGE, BLOCK, DEAD }

var state: int = State.FREE
var hp: float = 100.0
var mp: float = 60.0
var combo_index: int = 0
var attack_timer: float = 0.0
var attack_hit_done: bool = false
var combo_window: float = 0.0
var dodge_timer: float = 0.0
var dodge_dir := Vector3.ZERO
var skill_cd: float = 0.0
var invuln_timer: float = 0.0
var death_timer: float = 0.0
var cam_yaw: float = 0.0
var cam_pitch: float = -0.28

# Feedback state: footstep accumulator, camera shake, soft lock-on target.
var _step_accum: float = 0.0
var _shake_time: float = 0.0
var _shake_dur: float = 0.15
var _shake_mag: float = 0.0
var _target: Node3D = null
var _target_timer: float = 0.0

var mesh_root: Node3D
var anim: AnimationPlayer
var weapon_node: Node3D
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var world: Node3D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4  # environment + enemy bodies block movement
	_build_body()
	_build_camera()
	hp = GameState.max_hp()
	mp = GameState.max_mp()
	GameState.level_up.connect(_on_level_up)
	GameState.weapon_refined.connect(_on_weapon_refined)
	call_deferred("_late_ready")

func _late_ready() -> void:
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())

func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	mesh_root = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)
	var cd := GameState.class_data()
	var model_path := str(cd.get("model", KAYKIT_MODEL))
	var model: Node3D = load(model_path).instantiate()
	mesh_root.add_child(model)
	ModelUtils.setup_character_for_movement(model, 1.85)

	anim = model.find_child("AnimationPlayer", true) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		model.add_child(anim)
	var lib_path := str(cd.get("anim_lib", KAYKIT_LIB))
	if lib_path != "" and ResourceLoader.exists(lib_path):
		var lib := load(lib_path) as AnimationLibrary
		if lib:
			anim.add_animation_library("", lib)
	HeroAnimScript.apply_loops(anim, _anim_profile())

	# Hoplite Chan already has a skinned spear, shield and xiphos. The other
	# classes still grip the separate KayKit weapon.
	if not bool(cd.get("builtin_weapons", false)):
		var weapon_path: String = cd["weapon"]
		if ResourceLoader.exists(weapon_path):
			var grip_class := "melee"
			weapon_node = WeaponGrip.attach(model, weapon_path, grip_class)
	else:
		_tag_builtin_weapons(model)
	_update_weapon_glow()

	_play_anim(_clip("idle"))

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	camera_pivot.position.y = 1.55
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 5.6
	spring_arm.collision_mask = 1
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.current = true
	spring_arm.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
	if event is InputEventMouseButton and event.pressed:
		# Click-to-recapture (web pointer lock needs a gesture).
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw -= event.relative.x * MOUSE_SENS
		cam_pitch = clampf(cam_pitch - event.relative.y * MOUSE_SENS, -1.05, 0.7)

func _physics_process(delta: float) -> void:
	if world == null:
		world = get_tree().get_first_node_in_group("game_world")

	_update_shake(delta)

	if state == State.DEAD:
		_set_target(null)
		death_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		if death_timer <= 0.0:
			_respawn()
		return

	camera_pivot.rotation.y = cam_yaw
	camera_pivot.rotation.x = cam_pitch

	skill_cd = maxf(0.0, skill_cd - delta)
	combo_window = maxf(0.0, combo_window - delta)
	invuln_timer = maxf(0.0, invuln_timer - delta)

	# Mana regen.
	mp = minf(mp + 4.0 * GameState.mana_regen_mult() * delta, GameState.max_mp())
	mana_changed.emit(mp, GameState.max_mp())

	# Soft lock-on refresh — a few times a second, never every tick.
	_target_timer -= delta
	if _target_timer <= 0.0:
		_target_timer = TARGET_TICK
		_set_target(_find_aim_target(TARGET_RANGE, TARGET_DOT))

	match state:
		State.FREE:
			_process_free(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge(delta)
		State.BLOCK:
			_process_block(delta)

	_apply_gravity(delta)
	move_and_slide()

func _process_free(delta: float) -> void:
	if _ui_open():
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		_play_anim(_clip("idle"))
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := camera_pivot.global_transform.basis
	var dir := (cam_basis * Vector3(input_dir.x, 0, input_dir.y))
	dir.y = 0
	dir = dir.normalized()

	var sprinting := Input.is_action_pressed("sprint") and dir.length() > 0.1
	var speed := (SPRINT_SPEED if sprinting else WALK_SPEED) * GameState.move_speed_mult()

	if dir.length() > 0.1:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_face_direction(dir, delta)
		_play_anim(_clip("sprint") if sprinting else _clip("walk"))
		_tick_footsteps(delta, sprinting)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		_play_anim(_clip("idle"))
		# Prime the accumulator so the first step lands soon after moving off.
		_step_accum = maxf(_step_accum, STEP_DIST_WALK * 0.7)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play_anim(_clip("jump"), false)

	if Input.is_action_just_pressed("attack_light"):
		_try_light_attack()
	elif Input.is_action_just_pressed("attack_heavy"):
		_try_heavy_attack()
	elif Input.is_action_just_pressed("skill"):
		_try_skill()
	elif Input.is_action_just_pressed("dodge") and dir.length() > 0.1:
		_start_dodge(dir)
	elif Input.is_action_just_pressed("block"):
		state = State.BLOCK
		_play_anim(_clip("block"))
	elif Input.is_action_just_pressed("potion_1"):
		_drink_health_potion()
	elif Input.is_action_just_pressed("potion_2"):
		_drink_mana_potion()

func _ui_open() -> bool:
	var hud := get_tree().get_first_node_in_group("hud")
	return hud != null and hud.get("ui_open") == true

# ── Footsteps ────────────────────────────────────────────────────────────
func _tick_footsteps(delta: float, sprinting: bool) -> void:
	if not is_on_floor():
		return
	_step_accum += Vector2(velocity.x, velocity.z).length() * delta
	var step_len: float = STEP_DIST_SPRINT if sprinting else STEP_DIST_WALK
	if _step_accum < step_len:
		return
	_step_accum -= step_len
	var vol: float = -10.0 if sprinting else -13.0
	AudioManager.play_sfx("footstep_" + _ground_kind(), vol, randf_range(0.92, 1.09))

func _ground_kind() -> String:
	## The world tells us what we're standing on; grass is the safe default.
	if world != null and world.has_method("ground_kind"):
		return str(world.ground_kind(global_position.x, global_position.z))
	return "grass"

# ── Camera shake ─────────────────────────────────────────────────────────
## Public: enemies call this when a hit of ours lands on them.
func add_camera_shake(magnitude: float, duration: float = 0.15) -> void:
	_shake_mag = maxf(_shake_mag, magnitude)
	_shake_time = maxf(_shake_time, duration)
	_shake_dur = _shake_time

func _update_shake(delta: float) -> void:
	# Offsets the Camera3D inside the SpringArm3D, so the arm's own collision
	# and follow behaviour are untouched.
	if camera == null:
		return
	if _shake_time <= 0.0:
		if camera.position != Vector3.ZERO:
			camera.position = Vector3.ZERO
		return
	_shake_time -= delta
	if _shake_time <= 0.0:
		camera.position = Vector3.ZERO
		_shake_mag = 0.0
		_shake_dur = 0.15
		return
	var amp: float = _shake_mag * (_shake_time / maxf(0.01, _shake_dur))
	camera.position = Vector3(randf_range(-amp, amp), randf_range(-amp, amp), 0.0)

# ── Soft lock-on ─────────────────────────────────────────────────────────
func _set_target(t: Node3D) -> void:
	if t == _target:
		return
	if _target != null and is_instance_valid(_target) and _target.has_method("set_targeted"):
		_target.set_targeted(false)
	_target = t
	if _target != null and _target.has_method("set_targeted"):
		_target.set_targeted(true)

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	# Hit lands mid-swing.
	if not attack_hit_done and attack_timer <= _attack_hit_time:
		attack_hit_done = true
		_apply_attack_hit()
	if attack_timer <= 0.0:
		state = State.FREE
		# Chain the next combo step if the player kept clicking.
		if Input.is_action_pressed("attack_light") and combo_window > 0.0:
			_try_light_attack()

var _attack_hit_time: float = 0.3

func _process_dodge(delta: float) -> void:
	dodge_timer -= delta
	var speed := 8.5 * GameState.move_speed_mult()
	velocity.x = dodge_dir.x * speed
	velocity.z = dodge_dir.z * speed
	if dodge_timer <= 0.0:
		state = State.FREE

func _process_block(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	if not Input.is_action_pressed("block"):
		state = State.FREE

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5

func _face_direction(dir: Vector3, delta: float) -> void:
	var target_yaw := ModelUtils.yaw_from_direction(dir)
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_yaw, TURN_RATE * delta)

func _face_camera() -> void:
	var forward := -camera_pivot.global_transform.basis.z
	forward.y = 0
	if forward.length() > 0.01:
		mesh_root.rotation.y = ModelUtils.yaw_from_direction(forward.normalized())

func _anim_profile() -> String:
	return str(GameState.class_data().get("anim_profile", "kaykit"))

func _clip(action: String) -> String:
	return HeroAnimScript.clip(_anim_profile(), action)

func _combo_clips() -> PackedStringArray:
	return HeroAnimScript.combo(_anim_profile())

func _play_anim(clip: String, loop_ok: bool = true) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	if anim.current_animation == clip and loop_ok:
		return
	anim.play(clip)

# ── Combat ───────────────────────────────────────────────────────────────
func _try_light_attack() -> void:
	var cd := GameState.class_data()
	if cd["ranged"]:
		_start_attack(_clip("light"), HeroAnimScript.duration(_anim_profile(), "ranged_time"))
	else:
		if combo_window <= 0.0:
			combo_index = 0
		var clips := _combo_clips()
		if clips.is_empty():
			return
		_start_attack(clips[combo_index], HeroAnimScript.duration(_anim_profile(), "light_time"))
		combo_index = (combo_index + 1) % clips.size()
		combo_window = 1.1
	AudioManager.play_sfx("sword_swing", -4.0, randf_range(0.95, 1.1))

func _try_heavy_attack() -> void:
	_start_attack(_clip("heavy"), HeroAnimScript.duration(_anim_profile(), "heavy_time"))
	AudioManager.play_sfx("sword_swing", -2.0, 0.85)

func _start_attack(clip: String, duration: float) -> void:
	state = State.ATTACK
	attack_timer = duration
	_attack_hit_time = duration * 0.55
	attack_hit_done = false
	_face_camera()
	_play_anim(clip, false)
	combo_performed.emit()

var _heavy_next: bool = false

func _apply_attack_hit() -> void:
	var cd := GameState.class_data()
	var dmg := GameState.attack_damage()
	if anim != null and anim.current_animation == _clip("heavy"):
		dmg *= 1.8
	if cd["ranged"]:
		_fire_projectile(dmg, cd["projectile_speed"])
	else:
		_melee_hit(dmg, cd["attack_range"], cd["attack_arc"])

func _melee_hit(dmg: float, reach: float, arc: float) -> void:
	var forward := -mesh_root.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("dead"):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0
		var dist := to_enemy.length()
		if dist > reach + 0.6:
			continue
		if dist > 0.3 and forward.angle_to(to_enemy.normalized()) > arc:
			continue
		enemy.take_damage(dmg, global_position)
		VfxHelper.spawn_hit(enemy.global_position + Vector3(0, 1.2, 0), self)
		hit_any = true
	if hit_any:
		AudioManager.play_sfx("hit_flesh", -2.0, randf_range(0.9, 1.1))
		AudioManager.play_sfx("spear_clash", -8.0)
		add_camera_shake(0.055, 0.15)

func _fire_projectile(dmg: float, speed: float) -> void:
	var cd := GameState.class_data()
	var origin := global_position + Vector3(0, 1.4, 0)
	var dir := -camera.global_transform.basis.z
	# Aim at nearest enemy in view, else straight ahead.
	var target := _find_aim_target()
	if target:
		dir = (target.global_position + Vector3(0, 1.0, 0) - origin).normalized()
	var is_magic: bool = GameState.player_class == "magos"
	ProjectileScript.spawn(get_parent(), origin, dir, speed, dmg, is_magic)
	AudioManager.play_sfx("sword_swing" if not is_magic else "thunderbolt", -6.0)

func _find_aim_target(max_dist: float = 30.0, min_dot: float = 0.85) -> Node3D:
	## Nearest-to-centre living enemy inside the view cone. Defaults are the
	## ranged-aim assist; the lock-on highlight passes a wider, shorter cone.
	var best: Node3D = null
	var best_score: float = min_dot  # min dot toward camera forward
	var cam_forward := -camera.global_transform.basis.z
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead"):
			continue
		if not enemy.is_inside_tree():
			continue
		var to: Vector3 = (enemy.global_position + Vector3(0, 0.9, 0)) - camera.global_position
		var dist := to.length()
		if dist > max_dist or dist < 0.05:
			continue
		var score := cam_forward.dot(to.normalized())
		if score > best_score:
			best_score = score
			best = enemy
	return best

func _try_skill() -> void:
	var cd := GameState.class_data()
	if skill_cd > 0.0 or mp < cd["skill_mp"]:
		return
	mp -= cd["skill_mp"]
	skill_cd = cd["skill_cd"]
	skill_cooldown_started.emit(skill_cd)
	mana_changed.emit(mp, GameState.max_mp())
	_face_camera()
	_play_anim(_clip("skill"), false)

	match GameState.player_class:
		"hoplite":
			# Spear of Achilles: sweeping AoE around the player.
			var dmg := GameState.skill_damage()
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or enemy.get("dead"):
					continue
				var to: Vector3 = enemy.global_position - global_position
				to.y = 0
				if to.length() <= 4.5:
					enemy.take_damage(dmg, global_position)
					VfxHelper.spawn_hit(enemy.global_position + Vector3(0, 1.2, 0), self)
			VfxHelper.spawn_strike(global_position + Vector3(0, 0.4, 0), -mesh_root.global_transform.basis.z, self)
			AudioManager.play_sfx("spear_clash", 0.0)
		"toxotes":
			# Artemis Volley: fan of five arrows.
			var dmg := GameState.skill_damage()
			var base_dir := -camera.global_transform.basis.z
			for i in range(-2, 3):
				var dir := base_dir.rotated(Vector3.UP, deg_to_rad(i * 8.0))
				ProjectileScript.spawn(get_parent(), global_position + Vector3(0, 1.4, 0), dir, 28.0, dmg, false)
			AudioManager.play_sfx("sword_swing", 0.0, 0.8)
		"magos":
			# Zeus's Thunderbolt: lightning strike on the aimed point.
			var dmg := GameState.skill_damage()
			var target_pos := global_position + -camera_pivot.global_transform.basis.z * 9.0
			var aim := _find_aim_target()
			if aim:
				target_pos = aim.global_position
			if world and world.has_method("sample_height"):
				target_pos.y = world.sample_height(target_pos.x, target_pos.z)
			VfxHelper.spawn_strike(target_pos + Vector3(0, 0.5, 0), Vector3.FORWARD, self)
			AudioManager.play_sfx("thunderbolt", 2.0)
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or enemy.get("dead"):
					continue
				if enemy.global_position.distance_to(target_pos) <= 4.0:
					enemy.take_damage(dmg, global_position)

func _start_dodge(dir: Vector3) -> void:
	state = State.DODGE
	dodge_timer = 0.42
	invuln_timer = 0.5
	dodge_dir = dir.normalized()
	_face_direction(dodge_dir, 1.0)
	_play_anim(_clip("roll"), false)
	AudioManager.play_sfx("dodge_roll", -4.0)

func _drink_health_potion() -> void:
	if hp >= GameState.max_hp():
		return
	if GameState.use_health_potion():
		hp = minf(hp + 60.0, GameState.max_hp())
		health_changed.emit(hp, GameState.max_hp())
		AudioManager.play_sfx("potion_drink")

func _drink_mana_potion() -> void:
	if mp >= GameState.max_mp():
		return
	if GameState.use_mana_potion():
		mp = minf(mp + 40.0, GameState.max_mp())
		mana_changed.emit(mp, GameState.max_mp())
		AudioManager.play_sfx("potion_drink")

# ── Damage intake ────────────────────────────────────────────────────────
func take_damage(amount: float, from_position: Vector3) -> void:
	if state == State.DEAD or invuln_timer > 0.0:
		return
	var dmg := amount * GameState.damage_taken_mult()
	if state == State.BLOCK:
		dmg *= 0.35
		AudioManager.play_sfx("spear_clash", -2.0)
	hp -= dmg
	health_changed.emit(hp, GameState.max_hp())
	# Taking a hit kicks the camera harder than landing one.
	add_camera_shake(0.16 if state != State.BLOCK else 0.09, 0.28)
	if hp <= 0.0:
		_die()
	else:
		if state == State.FREE:
			_play_anim(_clip("hit"), false)
		AudioManager.play_sfx("hit_flesh", -4.0, 0.8)

func _die() -> void:
	state = State.DEAD
	hp = 0.0
	death_timer = 4.0
	_set_target(null)
	add_camera_shake(0.26, 0.5)
	_play_anim(_clip("death"), false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music_once("defeat")
	died.emit()

func _respawn() -> void:
	# Classic MMO soft death: lose 10% gold, wake at the sanctuary.
	var penalty := int(GameState.gold * 0.10)
	GameState.gold -= penalty
	GameState.gold_changed.emit(GameState.gold)
	hp = GameState.max_hp()
	mp = GameState.max_mp()
	state = State.FREE
	_set_target(null)
	_step_accum = 0.0
	if world and world.has_method("get_respawn_point"):
		global_position = world.get_respawn_point()
	velocity = Vector3.ZERO
	_play_anim(_clip("idle"))
	AudioManager.play_music("exploration")
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	respawned.emit()

func _on_level_up(_new_level: int) -> void:
	hp = minf(hp + GameState.max_hp() * 0.35, GameState.max_hp())
	mp = GameState.max_mp()
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	AudioManager.play_sfx("level_up")
	VfxHelper.spawn_hit(global_position + Vector3(0, 1.0, 0), self)

func _on_weapon_refined(_lvl: int) -> void:
	_update_weapon_glow()

func _tag_builtin_weapons(model: Node3D) -> void:
	for child in model.find_children("*", "MeshInstance3D"):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
			continue
		var mat := mi.mesh.surface_get_material(0)
		var mat_name := mat.resource_name.to_upper() if mat != null else ""
		if "DORY" in mat_name or "XIPHOS" in mat_name or "SHIELD" in mat_name:
			mi.set_meta("class_weapon", true)

func _weapon_meshes() -> Array:
	if weapon_node != null:
		return weapon_node.find_children("*", "MeshInstance3D")
	var found: Array = []
	if mesh_root == null:
		return found
	for child in mesh_root.find_children("*", "MeshInstance3D"):
		if child.get_meta("class_weapon", false):
			found.append(child)
	return found

func _update_weapon_glow() -> void:
	# Divine glow on high-refine weapons — the visible power fantasy.
	var meshes := _weapon_meshes()
	if meshes.is_empty():
		return
	var refine := GameState.weapon_refine
	for child in meshes:
		var mi := child as MeshInstance3D
		var mat := mi.get_active_material(0)
		if mat is StandardMaterial3D:
			var m := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			if refine >= 7:
				m.emission_enabled = true
				m.emission = Color(1.0, 0.75, 0.25)
				m.emission_energy_multiplier = 0.6 + refine * 0.12
			elif refine >= 4:
				m.emission_enabled = true
				m.emission = Color(0.45, 0.7, 1.0)
				m.emission_energy_multiplier = 0.35
			else:
				m.emission_enabled = false
			mi.material_override = m
