extends CharacterBody3D
## Player — third-person action RPG controller: orbit camera, sprint, jump,
## dodge roll, block, 3-hit melee combo / ranged shots, class skill, HP/MP.

signal health_changed(hp: float, max_hp: float)
signal mana_changed(mp: float, max_mp: float)
signal died
signal respawned
signal skill_cooldown_started(duration: float)
signal combo_performed

## Greek Tripo hoplite — looks like a Spartan; UAL clips + LegPlant for motion.
## Adventurer base (no medieval crown) + GreekLook Corinthian / bronze paint.
const CharacterGLB := "res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb"
## Embedded Quaternius clips — do not overwrite with a legacy UAL library.
const CharacterLib := ""
const GearGrip = preload("res://scripts/gear_grip.gd")
const GearPaint = preload("res://scripts/gear_paint.gd")
const HeroAnim = preload("res://scripts/utils/hero_anim.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const VfxHelper = preload("res://scripts/vfx_helper.gd")
const NameplateScript = preload("res://scripts/player_nameplate.gd")

const MALE_ATTACK_VOICES := ["male_attack_a", "male_attack_b", "attack_grunt"]
const MALE_HURT_VOICES := ["male_hurt_a", "male_hurt_b", "male_hurt_c"]

const WALK_SPEED := 3.4
const SPRINT_SPEED := 6.4
const JUMP_VELOCITY := 7.0
const GRAVITY := 22.0
const TURN_RATE := 14.0
const MOUSE_SENS := 0.0022
## Fixed third-person camera (zoom removed — close zoom made poses look broken).
const CAM_DISTANCE := 5.6
const CAM_PIVOT_HEIGHT := 1.45
const CAM_PITCH_MIN := -0.85
const CAM_PITCH_MAX := -0.18
const CAM_PITCH_DEFAULT := -0.28
const CAM_SPRING_MARGIN := 0.35

const COMBO_ALIASES := ["attack_1", "attack_2", "attack_3"]
const HEAVY_ALIAS := "attack_heavy"

# Footsteps are driven by distance travelled, so they always match the stride
# no matter how the move speed is tuned. Longer spacing + a cooldown keeps
# multi-hit grass samples from stacking into a stampede.
const STEP_DIST_WALK := 2.8
const STEP_DIST_SPRINT := 3.4
const STEP_COOLDOWN_WALK := 0.34
const STEP_COOLDOWN_SPRINT := 0.26

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
var cam_pitch: float = CAM_PITCH_DEFAULT

# Feedback state: footstep accumulator, camera shake, soft lock-on target.
var _step_accum: float = 0.0
var _step_cooldown: float = 0.0
var _shake_time: float = 0.0
var _shake_dur: float = 0.15
var _shake_mag: float = 0.0
var _target: Node3D = null
var _target_timer: float = 0.0

var mesh_root: Node3D
var anim: AnimationPlayer
var weapon_node: Node3D
var shield_node: Node3D
var helmet_node: Node3D
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var world: Node3D

## Overhead yellow say bubble (ChatSystem → Label3D).
const CHAT_BUBBLE_SECONDS := 6.5
var _chat_bubble: Label3D = null
var _chat_bubble_token: int = 0
var _nameplate: Node3D = null
## Peer id of last PvP attacker (0 = PvE / environment).
var _last_pvp_attacker: int = 0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4  # environment + enemy bodies block movement
	_build_body()
	_build_camera()
	hp = GameState.max_hp()
	mp = GameState.max_mp()
	_sync_identity_meta()
	_nameplate = NameplateScript.new()
	add_child(_nameplate)
	_refresh_nameplate()
	GameState.level_up.connect(_on_level_up)
	GameState.weapon_refined.connect(_on_weapon_refined)
	GameState.stats_changed.connect(_refresh_nameplate)
	if ChatSystem != null and not ChatSystem.message_received.is_connected(_on_chat_message):
		ChatSystem.message_received.connect(_on_chat_message)
	call_deferred("_late_ready")

func _late_ready() -> void:
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	_refresh_nameplate()


func _sync_identity_meta() -> void:
	set_meta("empire", GameState.empire)
	set_meta("chat_name", GameState.player_name)
	set_meta("level", GameState.level)


func _refresh_nameplate(_a: Variant = null) -> void:
	_sync_identity_meta()
	if _nameplate != null:
		_nameplate.call("set_plate", GameState.player_name, GameState.level, GameState.empire)


func empire_id() -> String:
	return String(get_meta("empire", GameState.empire))


func is_rival_player(other: Node) -> bool:
	if other == null or other == self or not is_instance_valid(other):
		return false
	if not other.is_in_group("player"):
		return false
	if other.get("dead") == true or other.get("state") == State.DEAD:
		return false
	var their_emp := String(other.get_meta("empire", ""))
	if their_emp == "" and other.has_method("empire_id"):
		their_emp = String(other.call("empire_id"))
	if their_emp == "":
		return false
	return their_emp != empire_id()


func _pvp_attacker_id() -> int:
	if NetSession and NetSession.is_online():
		return multiplayer.get_unique_id()
	return 1


func _deal_pvp_hit(other: Node, dmg: float) -> void:
	if other == null:
		return
	if other.is_in_group("remote_player") and other.has_method("take_damage"):
		other.take_damage(dmg, global_position)
		return
	if other.has_method("take_pvp_damage"):
		other.call("take_pvp_damage", dmg, global_position, _pvp_attacker_id())
	elif other.has_method("take_damage"):
		other.take_damage(dmg, global_position)


func _on_chat_message(sender: String, text: String, _stamp: float) -> void:
	## Yellow overhead letters for this champion's own say lines.
	if text == "" or sender == "Herald":
		return
	var mine := ""
	if ChatSystem:
		mine = ChatSystem.display_name()
	if mine == "":
		mine = GameState.player_name
	var tagged := String(get_meta("chat_name", ""))
	var for_me := (sender == mine) or (tagged != "" and sender == tagged)
	if not for_me:
		return
	_show_chat_bubble(text)


func _show_chat_bubble(line: String) -> void:
	if _chat_bubble == null or not is_instance_valid(_chat_bubble):
		_chat_bubble = Label3D.new()
		_chat_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_chat_bubble.shaded = false
		_chat_bubble.double_sided = true
		_chat_bubble.no_depth_test = true
		_chat_bubble.pixel_size = 0.0042
		_chat_bubble.font_size = 110
		_chat_bubble.outline_size = 28
		_chat_bubble.outline_modulate = Color(0.05, 0.04, 0.03, 0.95)
		_chat_bubble.modulate = Color(1.0, 0.92, 0.25)
		_chat_bubble.width = 1000.0
		_chat_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chat_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_chat_bubble)
		_chat_bubble.position = Vector3(0.0, 2.35, 0.0)
	_chat_bubble.text = line
	_chat_bubble.visible = true
	_chat_bubble_token += 1
	var token := _chat_bubble_token
	var tree := get_tree()
	if tree:
		tree.create_timer(CHAT_BUBBLE_SECONDS).timeout.connect(
			func() -> void:
				if token == _chat_bubble_token and _chat_bubble != null and is_instance_valid(_chat_bubble):
					_chat_bubble.visible = false
		)

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
	var cd0: Dictionary = GameState.class_data()
	var char_path: String = String(cd0.get("character", CharacterGLB))
	if not ResourceLoader.exists(char_path):
		char_path = CharacterGLB
	var model: Node3D = load(char_path).instantiate()
	mesh_root.add_child(model)
	ModelUtils.setup_character_for_movement(model, 1.85)
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	var role := "hoplite"
	var cls := String(GameState.player_class)
	if cls == "toxotes":
		role = "guard"
	elif cls == "magos":
		role = "oracle"
	GreekLook.apply(model, role)
	_apply_class_tint(model, cd0)

	anim = model.find_child("AnimationPlayer", true) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		model.add_child(anim)
	## Full combat UAL library on the hoplite GeneralSkeleton (shared across classes).
	if CharacterLib != "" and ResourceLoader.exists(CharacterLib):
		var lib := load(CharacterLib) as AnimationLibrary
		if lib:
			if anim.has_animation_library(""):
				anim.remove_animation_library("")
			anim.add_animation_library("", lib)
	ModelUtils.set_animation_loops(anim)
	ModelUtils.bind_leg_plant_anim(model, anim)

	var weapon_path: String = _resolved_weapon_path()
	if ResourceLoader.exists(weapon_path):
		weapon_node = GearGrip.attach_weapon(model, weapon_path)
		if weapon_node:
			GearPaint.paint_attached(weapon_node, weapon_path)
		_update_weapon_glow()

	var shield_path: String = _resolved_shield_path()
	if shield_path != "" and ResourceLoader.exists(shield_path):
		shield_node = GearGrip.attach_shield(model, shield_path)
		if shield_node:
			shield_node.name = "ShieldMount"
			GearPaint.paint_attached(shield_node, shield_path)

	_attach_helmet(model)

	HeroAnim.play(anim, "idle")
	if not GameState.inventory_changed.is_connected(_on_gear_changed):
		GameState.inventory_changed.connect(_on_gear_changed)


func _apply_class_tint(model: Node3D, cd: Dictionary) -> void:
	if not cd.has("tint"):
		return
	var tint: Color = cd["tint"]
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var base: Material = mi.get_active_material(0)
		var mat: StandardMaterial3D
		if base is StandardMaterial3D:
			mat = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
		else:
			mat = StandardMaterial3D.new()
			if base != null and base is BaseMaterial3D:
				mat.albedo_texture = (base as BaseMaterial3D).albedo_texture
		mat.albedo_color = tint
		mi.material_override = mat


func _play_male_voice(pool: Array, volume_db: float = -4.0) -> void:
	if pool.is_empty():
		return
	var key: String = String(pool[randi() % pool.size()])
	AudioManager.play_sfx(key, volume_db, randf_range(0.92, 1.08))


func _on_gear_changed() -> void:
	_refresh_held_gear()


func _refresh_held_gear() -> void:
	if mesh_root == null or mesh_root.get_child_count() == 0:
		return
	var model: Node3D = mesh_root.get_child(0) as Node3D
	if model == null:
		return
	if weapon_node != null and is_instance_valid(weapon_node):
		weapon_node.queue_free()
		weapon_node = null
	if shield_node != null and is_instance_valid(shield_node):
		shield_node.queue_free()
		shield_node = null
	if helmet_node != null and is_instance_valid(helmet_node):
		helmet_node.queue_free()
		helmet_node = null
	var weapon_path: String = _resolved_weapon_path()
	if ResourceLoader.exists(weapon_path):
		weapon_node = GearGrip.attach_weapon(model, weapon_path)
		if weapon_node:
			GearPaint.paint_attached(weapon_node, weapon_path)
		_update_weapon_glow()
	var shield_path: String = _resolved_shield_path()
	if shield_path != "" and ResourceLoader.exists(shield_path):
		shield_node = GearGrip.attach_shield(model, shield_path)
		if shield_node:
			shield_node.name = "ShieldMount"
			GearPaint.paint_attached(shield_node, shield_path)
	_attach_helmet(model)


func _resolved_weapon_path() -> String:
	var eq: String = GameState.equipped_glb("weapon")
	if eq != "" and ResourceLoader.exists(eq):
		return eq
	return String(GameState.class_data().get("weapon", ""))


func _resolved_shield_path() -> String:
	## Only show a shield mesh when one is actually equipped (or class default).
	var eq: String = GameState.equipped_glb("shield")
	if eq != "":
		return eq
	return String(GameState.class_data().get("shield", ""))


func _attach_helmet(model: Node3D) -> void:
	var GreekLook = load("res://scripts/utils/greek_look.gd")
	## Inventory helm replaces the GreekLook default Corinthian (no double stack).
	GreekLook.remove_corinthian_helm(model)
	var helm_path: String = GameState.equipped_glb("helmet")
	if helm_path == "" or not ResourceLoader.exists(helm_path):
		## No inventory helm — restore Hellenic Corinthian for warriors.
		var cls := String(GameState.player_class)
		var role := "hoplite"
		if cls == "toxotes":
			role = "guard"
		elif cls == "magos":
			role = "oracle"
		if role in ["hoplite", "guard"]:
			GreekLook.apply(model, role)
		return
	helmet_node = GearGrip.attach_helmet(model, helm_path)
	if helmet_node != null:
		var mount: Node3D = helmet_node.find_child("HelmetMount", true, false) as Node3D
		if mount != null and mount.get_child_count() > 0:
			GearPaint.paint_attached(mount.get_child(0) as Node3D, helm_path)
		else:
			GearPaint.paint_attached(helmet_node, helm_path)


func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	camera_pivot.position.y = CAM_PIVOT_HEIGHT
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = CAM_DISTANCE
	## Environment only (layer 1). Player is layer 2.
	spring_arm.collision_mask = 1
	spring_arm.margin = CAM_SPRING_MARGIN
	var spring_shape := SphereShape3D.new()
	spring_shape.radius = 0.22
	spring_arm.shape = spring_shape
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.current = true
	spring_arm.add_child(camera)

## Orbit: hold middle-mouse and drag. No wheel zoom.
## RMB click still heavy-attacks.
var _mmb_down: bool = false
var _mmb_looking: bool = false
var _mmb_press_pos: Vector2 = Vector2.ZERO
const MMB_LOOK_SLOP := 4.0


func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
	if _ui_open():
		_mmb_down = false
		_mmb_looking = false
		return
	if event is InputEventMouseButton:
		## Swallow wheel so it cannot change camera distance.
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			return
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_mmb_down = true
				_mmb_looking = false
				_mmb_press_pos = event.position
			else:
				_mmb_down = false
				_mmb_looking = false
			return
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and state == State.FREE:
			_try_heavy_attack()
			return
	if event is InputEventMouseMotion and _mmb_down:
		if not _mmb_looking and event.position.distance_to(_mmb_press_pos) >= MMB_LOOK_SLOP:
			_mmb_looking = true
		if _mmb_looking:
			cam_yaw -= event.relative.x * MOUSE_SENS
			cam_pitch = clampf(cam_pitch - event.relative.y * MOUSE_SENS, CAM_PITCH_MIN, CAM_PITCH_MAX)

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

	cam_pitch = clampf(cam_pitch, CAM_PITCH_MIN, CAM_PITCH_MAX)
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
		_play_alias("idle")
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
		_play_alias("sprint" if sprinting else "walk")
		_tick_footsteps(delta, sprinting)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		_play_alias("idle")
		# Prime the accumulator so the first step lands soon after moving off.
		_step_accum = maxf(_step_accum, STEP_DIST_WALK * 0.7)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play_alias("jump", false)

	if Input.is_action_just_pressed("attack_light"):
		_try_light_attack()
	## Heavy blow: short RMB click is handled in _unhandled_input (RMB also looks).
	elif Input.is_action_just_pressed("skill"):
		_try_skill()
	elif Input.is_action_just_pressed("dodge") and dir.length() > 0.1:
		_start_dodge(dir)
	elif Input.is_action_pressed("block"):
		## Hold F — raise shield (KayKit Blocking loop). Releases in _process_block.
		state = State.BLOCK
		_play_alias("block")
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
	_step_cooldown = maxf(0.0, _step_cooldown - delta)
	_step_accum += Vector2(velocity.x, velocity.z).length() * delta
	var step_len: float = STEP_DIST_SPRINT if sprinting else STEP_DIST_WALK
	if _step_accum < step_len:
		return
	if _step_cooldown > 0.0:
		return
	_step_accum -= step_len
	_step_cooldown = STEP_COOLDOWN_SPRINT if sprinting else STEP_COOLDOWN_WALK
	var vol: float = -10.0 if sprinting else -13.0
	# Dedicated channel — never stack overlapping multi-crunch grass samples.
	AudioManager.play_footstep("footstep_" + _ground_kind(), vol, randf_range(0.94, 1.06))

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
	## Keep the shield-up clip looping while F is held.
	_play_alias("block")
	if not Input.is_action_pressed("block"):
		state = State.FREE
		_play_alias("idle")

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

func _play_anim(clip: String, loop_ok: bool = true) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	if anim.current_animation == clip and loop_ok:
		return
	anim.play(clip)


func _play_alias(alias: String, loop_ok: bool = true) -> void:
	HeroAnim.play(anim, alias, loop_ok)


func _clip_for_alias(alias: String) -> String:
	return HeroAnim.resolve(anim, alias)

# ── Combat ───────────────────────────────────────────────────────────────
func _try_light_attack() -> void:
	var cd := GameState.class_data()
	if cd["ranged"]:
		_start_attack(_clip_for_alias("attack_ranged"), 0.55)
	else:
		if combo_window <= 0.0:
			combo_index = 0
		_start_attack(_clip_for_alias(COMBO_ALIASES[combo_index]), 0.55)
		combo_index = (combo_index + 1) % COMBO_ALIASES.size()
		combo_window = 1.1
	_play_attack_swing_sfx(false)

func _try_heavy_attack() -> void:
	_start_attack(_clip_for_alias(HEAVY_ALIAS), 0.85)
	_play_attack_swing_sfx(true)

func _play_attack_swing_sfx(heavy: bool) -> void:
	## Weapon whoosh + Skyrim-style male "ah/ha" effort.
	match GameState.player_class:
		"hoplite":
			AudioManager.play_sfx("spear_thrust" if heavy else "sword_swing", -3.0 if heavy else -5.0, randf_range(0.92, 1.08))
		"toxotes":
			AudioManager.play_sfx("sword_swing", -6.0, randf_range(1.05, 1.2))
		_:
			AudioManager.play_sfx("sword_swing", -4.0, randf_range(0.95, 1.1))
	_play_male_voice(MALE_ATTACK_VOICES, -5.5 if heavy else -7.0)

func _start_attack(clip: String, duration: float) -> void:
	state = State.ATTACK
	attack_timer = duration
	_attack_hit_time = duration * 0.55
	attack_hit_done = false
	_face_camera()
	if clip != "" and anim != null and anim.has_animation(clip):
		anim.play(clip)
	combo_performed.emit()

var _heavy_next: bool = false

func _apply_attack_hit() -> void:
	var cd := GameState.class_data()
	var dmg := GameState.attack_damage()
	if anim != null and anim.current_animation == _clip_for_alias(HEAVY_ALIAS):
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
	## Cross-empire PvP — rivals only.
	for other in get_tree().get_nodes_in_group("player"):
		if not is_rival_player(other) or not other.has_method("take_damage"):
			continue
		var to_p: Vector3 = other.global_position - global_position
		to_p.y = 0
		var dist_p := to_p.length()
		if dist_p > reach + 0.6:
			continue
		if dist_p > 0.3 and forward.angle_to(to_p.normalized()) > arc:
			continue
		_deal_pvp_hit(other, dmg)
		VfxHelper.spawn_hit(other.global_position + Vector3(0, 1.2, 0), self)
		hit_any = true
	if hit_any:
		## Distinct impact (never reuse the swing whoosh) — bronze ring on hit.
		AudioManager.play_sfx("bronze_hit", -1.0, randf_range(0.88, 1.12))
		if GameState.player_class == "hoplite" and randf() < 0.35:
			AudioManager.play_sfx("spear_clash", -5.5, randf_range(0.95, 1.05))
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
	## Nearest-to-centre living enemy (or rival champion) inside the view cone.
	var best: Node3D = null
	var best_score: float = min_dot  # min dot toward camera forward
	var cam_forward := -camera.global_transform.basis.z
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("enemies"))
	for p in get_tree().get_nodes_in_group("player"):
		if is_rival_player(p):
			candidates.append(p)
	for enemy in candidates:
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
	_play_alias("attack_heavy", false)

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
			for other in get_tree().get_nodes_in_group("player"):
				if not is_rival_player(other):
					continue
				var to_p: Vector3 = other.global_position - global_position
				to_p.y = 0
				if to_p.length() <= 4.5:
					_deal_pvp_hit(other, dmg)
					VfxHelper.spawn_hit(other.global_position + Vector3(0, 1.2, 0), self)
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
			for other in get_tree().get_nodes_in_group("player"):
				if not is_rival_player(other):
					continue
				if other.global_position.distance_to(target_pos) <= 4.0:
					_deal_pvp_hit(other, dmg)

func _start_dodge(dir: Vector3) -> void:
	state = State.DODGE
	dodge_timer = 0.42
	invuln_timer = 0.5
	dodge_dir = dir.normalized()
	_face_direction(dodge_dir, 1.0)
	_play_alias("dodge", false)
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
	_apply_damage(amount, from_position, 0)


## PvP blow from another peer (via NetSession RPC).
func take_pvp_damage(amount: float, from_position: Vector3, attacker_peer: int) -> void:
	_apply_damage(amount, from_position, attacker_peer)


func _apply_damage(amount: float, from_position: Vector3, attacker_peer: int) -> void:
	if state == State.DEAD or invuln_timer > 0.0:
		return
	if attacker_peer != 0:
		_last_pvp_attacker = attacker_peer
	var dmg := amount * GameState.damage_taken_mult()
	if state == State.BLOCK:
		dmg *= 0.35
		AudioManager.play_sfx("spear_clash", -2.0)
		_play_alias("block_hit", false)
	hp -= dmg
	health_changed.emit(hp, GameState.max_hp())
	# Taking a hit kicks the camera harder than landing one.
	add_camera_shake(0.16 if state != State.BLOCK else 0.09, 0.28)
	if hp <= 0.0:
		_die()
	else:
		if state == State.FREE:
			_play_alias("hit", false)
		AudioManager.play_sfx("hit_flesh", -4.0, 0.8)
		_play_male_voice(MALE_HURT_VOICES, -3.5)

func _die() -> void:
	state = State.DEAD
	hp = 0.0
	death_timer = 4.0
	_set_target(null)
	add_camera_shake(0.26, 0.5)
	_play_alias("death", false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music_once("defeat")
	## Rival kill: scatter random worn + bag gear onto the field.
	if _last_pvp_attacker != 0:
		var drops: Array = GameState.take_pvp_death_drops(2, 3)
		if not drops.is_empty():
			if NetSession:
				NetSession.notify_death_loot(drops, global_position)
			if ChatSystem:
				ChatSystem.call("_push_system", "Defeated in rival combat — spoils scatter on the ground.")
	_last_pvp_attacker = 0
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
	_last_pvp_attacker = 0
	if world and world.has_method("get_respawn_point"):
		global_position = world.get_respawn_point()
	velocity = Vector3.ZERO
	_play_alias("idle")
	AudioManager.play_music("exploration")
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	_refresh_nameplate()
	respawned.emit()

func _on_level_up(_new_level: int) -> void:
	hp = minf(hp + GameState.max_hp() * 0.35, GameState.max_hp())
	_refresh_nameplate()
	mp = GameState.max_mp()
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	AudioManager.play_sfx("level_up")
	VfxHelper.spawn_hit(global_position + Vector3(0, 1.0, 0), self)

func _on_weapon_refined(_lvl: int) -> void:
	_update_weapon_glow()

func _update_weapon_glow() -> void:
	# Divine glow on high-refine weapons — the visible power fantasy.
	if weapon_node == null:
		return
	var refine := GameState.weapon_refine
	for child in weapon_node.find_children("*", "MeshInstance3D"):
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
