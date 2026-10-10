extends CharacterBody3D



signal health_changed(hp: float, max_hp: float)
signal mana_changed(mp: float, max_mp: float)
signal died
signal respawned
signal skill_cooldown_started(duration: float)
signal skill2_cooldown_started(duration: float)
signal combo_performed



const CharacterGLB: = "res://assets/characters/greek_hoplite/greek_hoplite.glb"
const CharacterLib: = ""
const GearGrip = preload("res://scripts/gear_grip.gd")
const GearPaint = preload("res://scripts/gear_paint.gd")
const GreekLook = preload("res://scripts/utils/greek_look.gd")
const HeroAnim = preload("res://scripts/utils/hero_anim.gd")
const USE_GREEK_LOOK: = false
const ProjectileScript = preload("res://scripts/projectile.gd")
const VfxHelper = preload("res://scripts/vfx_helper.gd")
const NameplateScript = preload("res://scripts/player_nameplate.gd")

const MALE_ATTACK_VOICES: = ["male_attack_a", "male_attack_b", "attack_grunt"]
const MALE_HURT_VOICES: = ["male_hurt_a", "male_hurt_b", "male_hurt_c"]

const WALK_SPEED: = 3.4
const SPRINT_SPEED: = 6.4
const JUMP_VELOCITY: = 7.0
const GRAVITY: = 22.0
const TURN_RATE: = 14.0
const MOUSE_SENS: = 0.0022

const CAM_DISTANCE: = 5.6
const CAM_PIVOT_HEIGHT: = 1.45
const CAM_PITCH_MIN: = -0.85
const CAM_PITCH_MAX: = -0.18
const CAM_PITCH_DEFAULT: = -0.28
const CAM_SPRING_MARGIN: = 0.35

const COMBO_ALIASES: = ["attack_1", "attack_2", "attack_3"]
const HEAVY_ALIAS: = "attack_heavy"




const STEP_DIST_WALK: = 2.8
const STEP_DIST_SPRINT: = 3.4
const STEP_COOLDOWN_WALK: = 0.34
const STEP_COOLDOWN_SPRINT: = 0.26


const TARGET_RANGE: = 24.0
const TARGET_DOT: = 0.7
const TARGET_TICK: = 0.15

enum State{FREE, ATTACK, DODGE, BLOCK, DEAD}

var state: int = State.FREE
var hp: float = 100.0
var mp: float = 60.0
var combo_index: int = 0
var attack_timer: float = 0.0
var attack_hit_done: bool = false
var combo_window: float = 0.0
var dodge_timer: float = 0.0
var dodge_dir: = Vector3.ZERO
var skill_cd: float = 0.0
var skill2_cd: float = 0.0
var _skill_pending: String = ""
var _skill_hit_timer: float = 0.0
var _phalanx_guard: float = 0.0
var invuln_timer: float = 0.0
var death_timer: float = 0.0
var cam_yaw: float = 0.0
var cam_pitch: float = CAM_PITCH_DEFAULT


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


const CHAT_BUBBLE_SECONDS: = 6.5
var _chat_bubble: Label3D = null
var _chat_bubble_token: int = 0
var _nameplate: Node3D = null

var _last_pvp_attacker: int = 0

func _ready() -> void :
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4
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
	if PartyShare != null and not PartyShare.party_changed.is_connected(_on_social_tint_changed):
		PartyShare.party_changed.connect(_on_social_tint_changed)
	if SocialSystem != null and not SocialSystem.duel_changed.is_connected(_on_duel_tint_changed):
		SocialSystem.duel_changed.connect(_on_duel_tint_changed)
	call_deferred("_late_ready")

func _late_ready() -> void :
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	_refresh_nameplate()
	_apply_social_tint()


func _on_social_tint_changed(_a: Variant = null) -> void:
	_apply_social_tint()


func _on_duel_tint_changed(_peer: int = 0, _active: bool = false) -> void:
	_apply_social_tint()


func _apply_social_tint() -> void:
	## Soft overlay — party blue / duel orange; never flat albedo override (pink bug).
	if mesh_root == null:
		return
	var in_party: = false
	if PartyShare != null:
		## Blue only when at least one other champion shares the group.
		in_party = PartyShare.member_list().size() > 1
	var in_duel: = SocialSystem != null and SocialSystem.duel_peer != 0
	var tint: Color = Color(1, 1, 1, 1)
	if in_party:
		tint = Color(0.55, 0.75, 1.0)
	elif in_duel:
		tint = Color(1.0, 0.55, 0.45)
	for node in mesh_root.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
		if mi == null:
			continue
		if tint.r >= 0.99 and tint.g >= 0.99 and tint.b >= 0.99:
			mi.material_overlay = null
			continue
		var overlay: = StandardMaterial3D.new()
		overlay.albedo_color = Color(tint.r, tint.g, tint.b, 0.35)
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_overlay = overlay


func _sync_identity_meta() -> void :
	set_meta("empire", GameState.empire)
	set_meta("chat_name", GameState.player_name)
	set_meta("level", GameState.level)


func _refresh_nameplate(_a: Variant = null) -> void :
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
	var pid: = int(other.get_meta("peer_id", 0))
	## Party members are never rivals (friendly blue).
	if PartyShare != null and pid != 0:
		for row in PartyShare.member_list():
			if int(row.get("peer_id", -1)) == pid:
				return false
	## Active duel overrides empire friendship.
	if SocialSystem != null and pid != 0 and SocialSystem.is_dueling(pid):
		return true
	var their_emp: = String(other.get_meta("empire", ""))
	if their_emp == "" and other.has_method("empire_id"):
		their_emp = String(other.call("empire_id"))
	if their_emp == "":
		return false
	return their_emp != empire_id()


func _pvp_attacker_id() -> int:
	if NetSession and NetSession.is_online():
		return multiplayer.get_unique_id()
	return 1


func _deal_pvp_hit(other: Node, dmg: float) -> void :
	if other == null:
		return
	if other.is_in_group("remote_player") and other.has_method("take_damage"):
		other.take_damage(dmg, global_position)
		return
	if other.has_method("take_pvp_damage"):
		other.call("take_pvp_damage", dmg, global_position, _pvp_attacker_id())
	elif other.has_method("take_damage"):
		other.take_damage(dmg, global_position)


func _on_chat_message(sender: String, text: String, _stamp: float, peer_id: int = -1) -> void:
	if text == "" or sender == "Herald" or sender.begins_with("["):
		return
	var mine: = ""
	if ChatSystem:
		mine = ChatSystem.display_name()
	if mine == "":
		mine = GameState.player_name
	var my_peer: = multiplayer.get_unique_id() if NetSession and NetSession.is_online() else 1
	if peer_id > 0 and peer_id != my_peer and sender != mine:
		return
	var tagged: = String(get_meta("chat_name", ""))
	var for_me: = (sender == mine) or (tagged != "" and sender == tagged)
	if not for_me:
		return
	_show_chat_bubble(text)


func _show_chat_bubble(line: String) -> void :
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
	var token: = _chat_bubble_token
	var tree: = get_tree()
	if tree:
		tree.create_timer(CHAT_BUBBLE_SECONDS).timeout.connect(
			func() -> void :
				if token == _chat_bubble_token and _chat_bubble != null and is_instance_valid(_chat_bubble):
					_chat_bubble.visible = false
		)

func _build_body() -> void :
	var shape: = CollisionShape3D.new()
	var capsule: = CapsuleShape3D.new()
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
	if bool(cd0.get("builtin_weapons", false)):
		ModelUtils.setup_authored_humanoid(model, 1.85)
	else:
		ModelUtils.setup_character_for_movement(model, 1.85)
	_harden_body_materials(model)

	if USE_GREEK_LOOK:
		GreekLook.apply(model, "hoplite")
	_apply_class_tint(model, cd0)

	anim = model.find_child("AnimationPlayer", true) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		model.add_child(anim)

	if CharacterLib != "" and ResourceLoader.exists(CharacterLib):
		var lib: = load(CharacterLib) as AnimationLibrary
		if lib:
			if anim.has_animation_library(""):
				anim.remove_animation_library("")
			anim.add_animation_library("", lib)
	ModelUtils.set_animation_loops(anim)

	ModelUtils.bind_leg_plant_anim(model, anim)

	if _uses_builtin_weapons():
		_tag_builtin_weapons(model)
		_update_weapon_glow()
	else:
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

		if model.find_child("CorinthianHelmMount", true, false) == null:
			_attach_helmet(model)

	HeroAnim.play(anim, _idle_alias())
	if not GameState.inventory_changed.is_connected(_on_gear_changed):
		GameState.inventory_changed.connect(_on_gear_changed)


func _harden_body_materials(model: Node3D) -> void:
	## Same as remote_avatar — keep large body surfaces opaque.
	if model == null:
		return
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if mi.get_aabb().size.y < 0.75:
			continue
		var base: = mi.get_active_material(0)
		if base == null or not (base is BaseMaterial3D):
			continue
		var bm: = base as BaseMaterial3D
		if bm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			continue
		var fixed: = bm.duplicate() as BaseMaterial3D
		fixed.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mi.material_override = fixed


func _apply_class_tint(model: Node3D, cd: Dictionary) -> void :
	if not cd.has("tint"):
		return
	var tint: Color = cd["tint"]
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi: = node as MeshInstance3D
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
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mi.material_override = mat


func _play_male_voice(pool: Array, volume_db: float = -4.0) -> void :
	if pool.is_empty():
		return
	var key: String = String(pool[randi() % pool.size()])
	AudioManager.play_sfx(key, volume_db, randf_range(0.92, 1.08))


func _on_gear_changed() -> void :
	_refresh_held_gear()


func _refresh_held_gear() -> void :
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
	if _uses_builtin_weapons():
		_tag_builtin_weapons(model)
		_update_weapon_glow()
		return
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

	var eq: String = GameState.equipped_glb("shield")
	if eq != "":
		return eq
	return String(GameState.class_data().get("shield", ""))


func _attach_helmet(model: Node3D) -> void :

	var helm_path: String = GameState.equipped_glb("helmet")
	if helm_path == "" or not ResourceLoader.exists(helm_path):
		return
	helmet_node = GearGrip.attach_helmet(model, helm_path)
	if helmet_node != null:
		var mount: Node3D = helmet_node.find_child("HelmetMount", true, false) as Node3D
		if mount != null and mount.get_child_count() > 0:
			GearPaint.paint_attached(mount.get_child(0) as Node3D, helm_path)
		else:
			GearPaint.paint_attached(helmet_node, helm_path)


func _build_camera() -> void :
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	camera_pivot.position.y = CAM_PIVOT_HEIGHT
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = CAM_DISTANCE

	spring_arm.collision_mask = 1
	spring_arm.margin = CAM_SPRING_MARGIN
	var spring_shape: = SphereShape3D.new()
	spring_shape.radius = 0.22
	spring_arm.shape = spring_shape
	camera_pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.current = true
	spring_arm.add_child(camera)



var _mmb_down: bool = false
var _mmb_looking: bool = false
var _mmb_press_pos: Vector2 = Vector2.ZERO
const MMB_LOOK_SLOP: = 4.0


func _unhandled_input(event: InputEvent) -> void :
	if state == State.DEAD:
		return
	if _ui_open():
		_mmb_down = false
		_mmb_looking = false
		return
	if event is InputEventMouseButton:

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
			## Social menu first (any remote under cursor / near crosshair).
			## Same-empire friends used to fail because aim only picked rivals.
			if _try_open_player_menu():
				get_viewport().set_input_as_handled()
				return
			_try_heavy_attack()
			return
	if event is InputEventMouseMotion and _mmb_down:
		if not _mmb_looking and event.position.distance_to(_mmb_press_pos) >= MMB_LOOK_SLOP:
			_mmb_looking = true
		if _mmb_looking:
			cam_yaw -= event.relative.x * MOUSE_SENS
			cam_pitch = clampf(cam_pitch - event.relative.y * MOUSE_SENS, CAM_PITCH_MIN, CAM_PITCH_MAX)

func _physics_process(delta: float) -> void :
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
	skill2_cd = maxf(0.0, skill2_cd - delta)
	_phalanx_guard = maxf(0.0, _phalanx_guard - delta)
	if _skill_pending != "" and _skill_hit_timer > 0.0:
		_skill_hit_timer = maxf(0.0, _skill_hit_timer - delta)
		if _skill_hit_timer <= 0.0:
			_resolve_skill_hit(_skill_pending)
			_skill_pending = ""
	combo_window = maxf(0.0, combo_window - delta)
	invuln_timer = maxf(0.0, invuln_timer - delta)


	mp = minf(mp + 4.0 * GameState.mana_regen_mult() * delta, GameState.max_mp())
	mana_changed.emit(mp, GameState.max_mp())


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

func _process_free(delta: float) -> void :
	if _ui_open():
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		_play_alias(_idle_alias())
		return
	var input_dir: = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis: = camera_pivot.global_transform.basis
	var dir: = (cam_basis * Vector3(input_dir.x, 0, input_dir.y))
	dir.y = 0
	dir = dir.normalized()

	var sprinting: = Input.is_action_pressed("sprint") and dir.length() > 0.1
	var speed: = (SPRINT_SPEED if sprinting else WALK_SPEED) * GameState.move_speed_mult()

	if dir.length() > 0.1:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_face_direction(dir, delta)
		_play_alias("sprint" if sprinting else "walk")
		_tick_footsteps(delta, sprinting)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		_play_alias(_idle_alias())

		_step_accum = maxf(_step_accum, STEP_DIST_WALK * 0.7)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play_alias("jump", false)

	if Input.is_action_just_pressed("attack_light"):
		_try_light_attack()

	elif Input.is_action_just_pressed("skill"):
		_try_skill("q")
	elif Input.is_action_just_pressed("skill2"):
		_try_skill("r")
	elif Input.is_action_just_pressed("dodge") and dir.length() > 0.1:
		_start_dodge(dir)
	elif Input.is_action_pressed("block"):

		state = State.BLOCK
		_play_alias("block")
	elif Input.is_action_just_pressed("potion_1"):
		_drink_health_potion()
	elif Input.is_action_just_pressed("potion_2"):
		_drink_mana_potion()

func _ui_open() -> bool:
	var hud: = get_tree().get_first_node_in_group("hud")
	return hud != null and hud.get("ui_open") == true


func _tick_footsteps(delta: float, sprinting: bool) -> void :
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

	AudioManager.play_footstep("footstep_" + _ground_kind(), vol, randf_range(0.94, 1.06))

func _ground_kind() -> String:

	if world != null and world.has_method("ground_kind"):
		return str(world.ground_kind(global_position.x, global_position.z))
	return "grass"



func add_camera_shake(magnitude: float, duration: float = 0.15) -> void :
	_shake_mag = maxf(_shake_mag, magnitude)
	_shake_time = maxf(_shake_time, duration)
	_shake_dur = _shake_time

func _update_shake(delta: float) -> void :


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
	camera.position = Vector3(randf_range( - amp, amp), randf_range( - amp, amp), 0.0)


func _set_target(t: Node3D) -> void :
	if t == _target:
		return
	if _target != null and is_instance_valid(_target) and _target.has_method("set_targeted"):
		_target.set_targeted(false)
	_target = t
	if _target != null and _target.has_method("set_targeted"):
		_target.set_targeted(true)

func _process_attack(delta: float) -> void :
	attack_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

	if not attack_hit_done and attack_timer <= _attack_hit_time:
		attack_hit_done = true
		_apply_attack_hit()
	if attack_timer <= 0.0:
		state = State.FREE

		if Input.is_action_pressed("attack_light") and combo_window > 0.0:
			_try_light_attack()

var _attack_hit_time: float = 0.3

func _process_dodge(delta: float) -> void :
	dodge_timer -= delta
	var speed: = 8.5 * GameState.move_speed_mult()
	velocity.x = dodge_dir.x * speed
	velocity.z = dodge_dir.z * speed
	if dodge_timer <= 0.0:
		state = State.FREE

func _process_block(delta: float) -> void :
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)

	_play_alias("block")
	if not Input.is_action_pressed("block"):
		state = State.FREE
		_play_alias(_idle_alias())

func _apply_gravity(delta: float) -> void :
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5

func _face_direction(dir: Vector3, delta: float) -> void :
	var target_yaw: = ModelUtils.yaw_from_direction(dir)
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_yaw, TURN_RATE * delta)

func _face_camera() -> void :
	var forward: = - camera_pivot.global_transform.basis.z
	forward.y = 0
	if forward.length() > 0.01:
		mesh_root.rotation.y = ModelUtils.yaw_from_direction(forward.normalized())

func _play_anim(clip: String, loop_ok: bool = true) -> void :
	if anim == null or not anim.has_animation(clip):
		return
	if anim.current_animation == clip and loop_ok:
		return
	anim.play(clip)


func _play_alias(alias: String, loop_ok: bool = true) -> void :
	HeroAnim.play(anim, alias, loop_ok)


func _idle_alias() -> String:
	# KayKit rigs look best resting in a weapon-ready pose (spear/staff held
	# upright) rather than the unarmed "Idle", where the mounted prop droops.
	# Classes declare that clip via their "idle" field; fall back to the
	# generic alias when the rig lacks it.
	var cd: = GameState.class_data()
	var want: = String(cd.get("idle", ""))
	if want != "" and anim != null and anim.has_animation(want):
		return want
	return "idle"


func _clip_for_alias(alias: String) -> String:
	return HeroAnim.resolve(anim, alias)


func _attack_time(key: String, fallback: float) -> float:
	return float(GameState.class_data().get(key, fallback))


func _try_light_attack() -> void :
	var cd: = GameState.class_data()
	if cd["ranged"]:
		_start_attack(_clip_for_alias("attack_ranged"), _attack_time("ranged_time", 0.55), "attack_ranged")
	else:
		if combo_window <= 0.0:
			combo_index = 0
		var alias: = COMBO_ALIASES[combo_index]
		_start_attack(_clip_for_alias(alias), _attack_time("light_time", 0.55), alias)
		combo_index = (combo_index + 1) % COMBO_ALIASES.size()
		combo_window = 1.1
	_play_attack_swing_sfx(false)

func _try_heavy_attack() -> void :
	_start_attack(_clip_for_alias(HEAVY_ALIAS), _attack_time("heavy_time", 0.85), HEAVY_ALIAS)
	_play_attack_swing_sfx(true)

func _play_attack_swing_sfx(heavy: bool) -> void :

	match GameState.player_class:
		"hoplite":
			AudioManager.play_sfx("spear_thrust" if heavy else "sword_swing", -3.0 if heavy else -5.0, randf_range(0.92, 1.08))
		"toxotes":
			AudioManager.play_sfx("sword_swing", -6.0, randf_range(1.05, 1.2))
		_:
			AudioManager.play_sfx("sword_swing", -4.0, randf_range(0.95, 1.1))
	_play_male_voice(MALE_ATTACK_VOICES, -5.5 if heavy else -7.0)

func _start_attack(clip: String, duration: float, fx_alias: String = "attack_1") -> void :
	state = State.ATTACK
	attack_timer = duration
	_attack_hit_time = duration * 0.55
	attack_hit_done = false
	_face_camera()
	if clip != "" and anim != null and anim.has_animation(clip):
		anim.play(clip)
	combo_performed.emit()
	## Peers need the swing anim — skills already call request_skill_fx.
	if NetSession != null and NetSession.is_online() and fx_alias != "":
		var yaw: float = float(mesh_root.rotation.y) if mesh_root else 0.0
		NetSession.request_combat_fx(fx_alias, global_position, yaw)

var _heavy_next: bool = false

func _apply_attack_hit() -> void :
	var cd: = GameState.class_data()
	var dmg: = GameState.attack_damage()
	if anim != null and anim.current_animation == _clip_for_alias(HEAVY_ALIAS):
		dmg *= 1.8
	if cd["ranged"]:
		_fire_projectile(dmg, cd["projectile_speed"])
	else:
		_melee_hit(dmg, cd["attack_range"], cd["attack_arc"])

func _melee_hit(dmg: float, reach: float, arc: float) -> void :
	var forward: = - mesh_root.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var hit_any: = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("dead"):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0
		var dist: = to_enemy.length()
		if dist > reach + 0.6:
			continue
		if dist > 0.3 and forward.angle_to(to_enemy.normalized()) > arc:
			continue
		enemy.take_damage(dmg, global_position)
		VfxHelper.spawn_hit(enemy.global_position + Vector3(0, 1.2, 0), self)
		hit_any = true

	for other in get_tree().get_nodes_in_group("player"):
		if not is_rival_player(other) or not other.has_method("take_damage"):
			continue
		var to_p: Vector3 = other.global_position - global_position
		to_p.y = 0
		var dist_p: = to_p.length()
		if dist_p > reach + 0.6:
			continue
		if dist_p > 0.3 and forward.angle_to(to_p.normalized()) > arc:
			continue
		_deal_pvp_hit(other, dmg)
		VfxHelper.spawn_hit(other.global_position + Vector3(0, 1.2, 0), self)
		hit_any = true
	if hit_any:

		AudioManager.play_sfx("bronze_hit", -1.0, randf_range(0.88, 1.12))
		if GameState.player_class == "hoplite" and randf() < 0.35:
			AudioManager.play_sfx("spear_clash", -5.5, randf_range(0.95, 1.05))
		add_camera_shake(0.055, 0.15)

func _fire_projectile(dmg: float, speed: float) -> void :
	var cd: = GameState.class_data()
	var origin: = global_position + Vector3(0, 1.4, 0)
	var dir: = - camera.global_transform.basis.z

	var target: = _find_aim_target()
	if target:
		dir = (target.global_position + Vector3(0, 1.0, 0) - origin).normalized()
	var is_magic: bool = GameState.player_class == "magos"
	ProjectileScript.spawn(get_parent(), origin, dir, speed, dmg, is_magic)
	AudioManager.play_sfx("sword_swing" if not is_magic else "thunderbolt", -6.0)

func _find_aim_target(max_dist: float = 30.0, min_dot: float = 0.85) -> Node3D:

	var best: Node3D = null
	var best_score: float = min_dot
	var cam_forward: = - camera.global_transform.basis.z
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
		var dist: = to.length()
		if dist > max_dist or dist < 0.05:
			continue
		var score: = cam_forward.dot(to.normalized())
		if score > best_score:
			best_score = score
			best = enemy
	return best

func _try_skill(which: String = "q") -> void :
	if state == State.DEAD or state == State.ATTACK:
		return
	var cd: = GameState.class_data()
	var is_r: = which == "r"
	var mp_cost: = int(cd.get("skill2_mp" if is_r else "skill_mp", 25))
	var cool: = float(cd.get("skill2_cd" if is_r else "skill_cd", 8.0))
	if is_r:
		if skill2_cd > 0.0 or mp < mp_cost:
			return
		mp -= mp_cost
		skill2_cd = cool
		skill2_cooldown_started.emit(skill2_cd)
	else:
		if skill_cd > 0.0 or mp < mp_cost:
			return
		mp -= mp_cost
		skill_cd = cool
		skill_cooldown_started.emit(skill_cd)
	mana_changed.emit(mp, GameState.max_mp())
	_face_camera()
	state = State.ATTACK
	attack_timer = float(cd.get("skill2_hit_delay" if is_r else "skill_hit_delay", 0.4)) + 0.55
	attack_hit_done = true
	var anim_alias: = String(cd.get("skill2_anim" if is_r else "skill_anim", "skill"))
	if anim != null and HeroAnim.play(anim, anim_alias, false) == "":
		_play_alias("attack_heavy" if not bool(cd.get("ranged", false)) else "attack_ranged", false)
	else:
		_play_alias(anim_alias, false)
	_skill_pending = "r" if is_r else "q"
	_skill_hit_timer = float(cd.get("skill2_hit_delay" if is_r else "skill_hit_delay", 0.4))
	## Wind-up VFX so the animated attack is visible immediately.
	if mesh_root != null:
		VfxHelper.spawn_strike(global_position + Vector3(0, 0.55, 0), -mesh_root.global_transform.basis.z, self)
	AudioManager.play_sfx(MALE_ATTACK_VOICES[randi() % MALE_ATTACK_VOICES.size()], -2.0, randf_range(0.92, 1.08))
	if NetSession.is_online():
		NetSession.request_skill_fx(_skill_pending, global_position, float(mesh_root.rotation.y) if mesh_root else 0.0)
	if GameState.tutorial_step < 4:
		GameState.advance_tutorial(4)


func _resolve_skill_hit(which: String) -> void :
	var is_r: = which == "r"
	match GameState.player_class:
		"hoplite":
			if is_r:
				_phalanx_guard = 4.0
				var dmg: = GameState.skill2_damage()
				_skill_melee_burst(dmg, 3.2)
				AudioManager.play_sfx("bronze_hit", -1.0)
			else:
				var dmg_q: = GameState.skill_damage()
				_skill_melee_burst(dmg_q, 4.8)
				VfxHelper.spawn_strike(global_position + Vector3(0, 0.4, 0), -mesh_root.global_transform.basis.z, self)
				AudioManager.play_sfx("spear_clash", 0.0)
		"toxotes":
			if is_r:
				var dmg: = GameState.skill2_damage()
				var dir: = -camera.global_transform.basis.z
				var aim: = _find_aim_target()
				if aim:
					dir = (aim.global_position + Vector3(0, 1.0, 0) - (global_position + Vector3(0, 1.4, 0))).normalized()
				ProjectileScript.spawn(get_parent(), global_position + Vector3(0, 1.4, 0), dir, 34.0, dmg, false)
				AudioManager.play_sfx("sword_swing", 0.0, 1.15)
			else:
				var dmg_q: = GameState.skill_damage()
				var base_dir: = -camera.global_transform.basis.z
				for i in range(-2, 3):
					var dir2: = base_dir.rotated(Vector3.UP, deg_to_rad(i * 8.0))
					ProjectileScript.spawn(get_parent(), global_position + Vector3(0, 1.4, 0), dir2, 28.0, dmg_q, false)
				AudioManager.play_sfx("sword_swing", 0.0, 0.8)
		"magos":
			var dmg: = GameState.skill2_damage() if is_r else GameState.skill_damage()
			var target_pos: = global_position + -camera_pivot.global_transform.basis.z * (6.0 if is_r else 9.0)
			var aim: = _find_aim_target()
			if aim:
				target_pos = aim.global_position
			if world and world.has_method("sample_height"):
				target_pos.y = world.sample_height(target_pos.x, target_pos.z)
			VfxHelper.spawn_strike(target_pos + Vector3(0, 0.5, 0), Vector3.FORWARD, self)
			if is_r:
				VfxHelper.spawn_explosion(target_pos + Vector3(0, 0.3, 0), self)
			AudioManager.play_sfx("thunderbolt", 2.0 if not is_r else 0.5)
			var radius: = 3.2 if is_r else 4.0
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or enemy.get("dead"):
					continue
				if enemy.global_position.distance_to(target_pos) <= radius:
					enemy.take_damage(dmg, global_position)
			for other in get_tree().get_nodes_in_group("player"):
				if not is_rival_player(other):
					continue
				if other.global_position.distance_to(target_pos) <= radius:
					_deal_pvp_hit(other, dmg)


func _skill_melee_burst(dmg: float, reach: float) -> void :
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead"):
			continue
		var to: Vector3 = enemy.global_position - global_position
		to.y = 0
		if to.length() <= reach:
			enemy.take_damage(dmg, global_position)
			VfxHelper.spawn_hit(enemy.global_position + Vector3(0, 1.2, 0), self)
	for other in get_tree().get_nodes_in_group("player"):
		if not is_rival_player(other):
			continue
		var to_p: Vector3 = other.global_position - global_position
		to_p.y = 0
		if to_p.length() <= reach:
			_deal_pvp_hit(other, dmg)
			VfxHelper.spawn_hit(other.global_position + Vector3(0, 1.2, 0), self)

func _start_dodge(dir: Vector3) -> void :
	state = State.DODGE
	dodge_timer = 0.42
	invuln_timer = 0.5
	dodge_dir = dir.normalized()
	_face_direction(dodge_dir, 1.0)
	_play_alias("dodge", false)
	AudioManager.play_sfx("dodge_roll", -4.0)

func _drink_health_potion() -> void :
	if hp >= GameState.max_hp():
		return
	if GameState.use_health_potion():
		hp = minf(hp + 60.0, GameState.max_hp())
		health_changed.emit(hp, GameState.max_hp())
		AudioManager.play_sfx("potion_drink")

func _drink_mana_potion() -> void :
	if mp >= GameState.max_mp():
		return
	if GameState.use_mana_potion():
		mp = minf(mp + 40.0, GameState.max_mp())
		mana_changed.emit(mp, GameState.max_mp())
		AudioManager.play_sfx("potion_drink")


func take_damage(amount: float, from_position: Vector3) -> void :
	_apply_damage(amount, from_position, 0)



func take_pvp_damage(amount: float, from_position: Vector3, attacker_peer: int) -> void :
	_apply_damage(amount, from_position, attacker_peer)


func _apply_damage(amount: float, from_position: Vector3, attacker_peer: int) -> void :
	if state == State.DEAD or invuln_timer > 0.0:
		return
	if attacker_peer != 0:
		_last_pvp_attacker = attacker_peer
	var dmg: = amount * GameState.damage_taken_mult()
	if _phalanx_guard > 0.0:
		dmg *= 0.55
	if state == State.BLOCK:
		dmg *= 0.35
		AudioManager.play_sfx("spear_clash", -2.0)
		_play_alias("block_hit", false)
	hp -= dmg
	health_changed.emit(hp, GameState.max_hp())

	add_camera_shake(0.16 if state != State.BLOCK else 0.09, 0.28)
	if hp <= 0.0:
		_die()
	else:
		if state == State.FREE:
			_play_alias("hit", false)
		AudioManager.play_sfx("hit_flesh", -4.0, 0.8)
		_play_male_voice(MALE_HURT_VOICES, -3.5)

func _die() -> void :
	state = State.DEAD
	hp = 0.0
	death_timer = 4.0
	_set_target(null)
	add_camera_shake(0.26, 0.5)
	_play_alias("death", false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music_once("defeat")

	if _last_pvp_attacker != 0:
		var drops: Array = []
		var gold_drop: = 0
		if SocialSystem != null and SocialSystem.is_dueling(_last_pvp_attacker):
			var duel_loot: Dictionary = SocialSystem.duel_death_drops()
			drops = duel_loot.get("drops", [])
			gold_drop = int(duel_loot.get("gold", 0))
			if ChatSystem:
				ChatSystem.call("_push_system",
					"Duel lost — dropped a random item and %d δρ (15%%)." % gold_drop)
			SocialSystem.end_duel()
		else:
			drops = GameState.take_pvp_death_drops(2, 3)
			if ChatSystem:
				ChatSystem.call("_push_system", "Defeated in rival combat — spoils scatter on the ground.")
		if (not drops.is_empty() or gold_drop > 0) and NetSession:
			NetSession.notify_death_loot(drops, global_position, gold_drop)
	_last_pvp_attacker = 0
	died.emit()


func _try_open_player_menu() -> bool:
	if not NetSession or not NetSession.is_online():
		return false
	var target: = _find_social_target()
	if target == null or not target.is_in_group("remote_player"):
		return false
	var hud: = get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("open_player_menu"):
		return false
	hud.open_player_menu(target)
	return true


func _find_social_target() -> Node3D:
	## Prefer physics pick under the mouse (Metin2-style), then screen-near remotes.
	if camera == null or not is_inside_tree():
		return null
	var mouse: = get_viewport().get_mouse_position()
	var from: = camera.project_ray_origin(mouse)
	var dir: = camera.project_ray_normal(mouse)
	var space: = get_world_3d().direct_space_state
	if space != null:
		var q: = PhysicsRayQueryParameters3D.create(from, from + dir * 48.0)
		q.collision_mask = 2 ## player layer
		q.exclude = [get_rid()]
		var hit: = space.intersect_ray(q)
		if not hit.is_empty():
			var col = hit.get("collider")
			if col is Node and (col as Node).is_in_group("remote_player"):
				return col as Node3D
	## Fallback: nearest remote projected near the cursor / screen center.
	var best: Node3D = null
	var best_d: = 72.0 ## px
	var vp: = get_viewport().get_visible_rect().size
	var anchor: = mouse if mouse.x > 1.0 else vp * 0.5
	for n in get_tree().get_nodes_in_group("remote_player"):
		if n == null or not is_instance_valid(n) or not (n is Node3D):
			continue
		if n.get("dead") == true:
			continue
		var p3: Node3D = n as Node3D
		if camera.is_position_behind(p3.global_position + Vector3(0, 1.0, 0)):
			continue
		var dist3: = camera.global_position.distance_to(p3.global_position)
		if dist3 > 28.0:
			continue
		var sp: = camera.unproject_position(p3.global_position + Vector3(0, 1.0, 0))
		var d: = sp.distance_to(anchor)
		if d < best_d:
			best_d = d
			best = p3
	return best

func _respawn() -> void :

	var penalty: = int(GameState.gold * 0.1)
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
	_play_alias(_idle_alias())
	AudioManager.play_music("exploration")
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	_refresh_nameplate()
	respawned.emit()

func _on_level_up(_new_level: int) -> void :
	hp = minf(hp + GameState.max_hp() * 0.35, GameState.max_hp())
	_refresh_nameplate()
	mp = GameState.max_mp()
	health_changed.emit(hp, GameState.max_hp())
	mana_changed.emit(mp, GameState.max_mp())
	AudioManager.play_sfx("level_up")
	VfxHelper.spawn_hit(global_position + Vector3(0, 1.0, 0), self)

func _on_weapon_refined(_lvl: int) -> void :
	_update_weapon_glow()

func _uses_builtin_weapons() -> bool:
	return bool(GameState.class_data().get("builtin_weapons", false))


func _tag_builtin_weapons(model: Node3D) -> void:
	if model == null:
		return
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi == null:
			continue
		var blob: String = String(mi.name)
		var mat: Material = mi.get_active_material(0)
		if mat != null:
			blob += " " + String(mat.resource_name)
		if mi.mesh != null and mi.mesh.get_surface_count() > 0:
			var surf: Material = mi.mesh.surface_get_material(0)
			if surf != null:
				blob += " " + String(surf.resource_name)
		blob = blob.to_upper()
		if "DORY" in blob or "XIPHOS" in blob or "SHIELD" in blob:
			mi.set_meta("class_weapon", true)


func _update_weapon_glow() -> void:
	var meshes: Array = []
	if weapon_node != null and is_instance_valid(weapon_node):
		for child in weapon_node.find_children("*", "MeshInstance3D"):
			meshes.append(child)
	elif mesh_root != null:
		for node in mesh_root.find_children("*", "MeshInstance3D", true, false):
			if node.has_meta("class_weapon"):
				meshes.append(node)
	if meshes.is_empty():
		return
	var refine: = GameState.weapon_refine
	for child in meshes:
		var mi: = child as MeshInstance3D
		var mat: = mi.get_active_material(0)
		if mat is StandardMaterial3D:
			var m: = (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
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
