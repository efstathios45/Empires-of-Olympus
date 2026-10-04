extends CharacterBody3D



signal enemy_died(enemy_id: String, position: Vector3)

const VfxHelper = preload("res://scripts/vfx_helper.gd")



const ENEMY_CONFIGS: = {
	"wolf_enemy": {

		"name": "Lykaon Wolf", 
		"level": 1, 
		"glb": "res://assets/characters/_free_cc0/quaternius_wolf.glb", 
		"lib": "", 
		"height": 1.05, "hp": 42, "dmg": 7.0, "speed": 4.6, 
		"xp": 18, "gold": [3, 8], "aggro": 9.0, "reach": 1.9, 
		"attack_cd": 1.4, "material": "Wolf Pelt", 
		"facing_plus_z": true, 
		"tint": Color(0.78, 0.78, 0.82), 
		"sfx_attack": "wolf_attack", "sfx_death": "wolf_death", 
		"sfx_aggro": "wolf_aggro", 
		"sfx_attack_alt": "wolf_bite", 
		"clips": {
			"idle": "Idle", "walk": "Walk", "sprint": "Gallop", 
			"attack": "Attack", "hit": "Idle_HitReact1", "death": "Death", 
		}, 
	}, 
	"wolf_black_enemy": {

		"name": "Stygian Wolf", 
		"level": 1, 
		"quest_id": "wolf_enemy", 
		"glb": "res://assets/characters/_free_cc0/quaternius_wolf.glb", 
		"lib": "", 
		"height": 1.12, "hp": 48, "dmg": 8.5, "speed": 4.8, 
		"xp": 22, "gold": [4, 9], "aggro": 9.5, "reach": 1.95, 
		"attack_cd": 1.35, "material": "Wolf Pelt", 
		"facing_plus_z": true, 
		"tint": Color(0.28, 0.26, 0.3), 
		"sfx_attack": "wolf_black_attack", "sfx_death": "wolf_black_death", 
		"sfx_aggro": "wolf_aggro", 
		"sfx_attack_alt": "wolf_black_bite", 
		"clips": {
			"idle": "Idle", "walk": "Walk", "sprint": "Gallop", 
			"attack": "Attack", "hit": "Idle_HitReact1", "death": "Death", 
		}, 
	}, 
	"wolf_dire_enemy": {

		"name": "Erymanthian Wolf", 
		"level": 1, 
		"quest_id": "wolf_enemy", 
		"glb": "res://assets/characters/_free_cc0/quaternius_wolf.glb", 
		"lib": "", 
		"height": 1.28, "hp": 58, "dmg": 10.0, "speed": 4.4, 
		"xp": 28, "gold": [5, 11], "aggro": 10.0, "reach": 2.1, 
		"attack_cd": 1.5, "material": "Wolf Pelt", 
		"facing_plus_z": true, 
		"tint": Color(0.55, 0.42, 0.34), 
		"sfx_attack": "wolf_dire_attack", "sfx_death": "wolf_dire_death", 
		"sfx_aggro": "wolf_aggro", 
		"sfx_attack_alt": "wolf_dire_bite", 
		"clips": {
			"idle": "Idle", "walk": "Walk", "sprint": "Gallop", 
			"attack": "Attack", "hit": "Idle_HitReact1", "death": "Death", 
		}, 
	}, 
	"boar_enemy": {

		"name": "Erymanthian Boar", 
		"level": 3, 
		"glb": "res://assets/characters/_free_cc0/oga_wild_boar.glb", 
		"lib": "", 
		"height": 1.05, "hp": 110, "dmg": 14.0, "speed": 4.2, 
		"xp": 48, "gold": [8, 16], "aggro": 9.5, "reach": 2.0, 
		"attack_cd": 1.7, "material": "Boar Tusk", 
		"facing_plus_z": true, 
		"sfx_attack": "boar_attack", "sfx_death": "boar_death", 
		"sfx_aggro": "boar_idle", 
		"sfx_attack_alt": "boar_attack_b", 
		"clips": {
			"idle": "Idle", "walk": "Walk", "sprint": "Gallop", 
			"attack": "Attack", "hit": "Idle_HitReact1", "death": "Death", 
		}, 
	}, 
	"satyr_enemy": {
		"name": "Satyr Raider", 
		"level": 5, 
		"glb": "res://assets/characters/satyr_enemy/satyr_enemy.glb", 
		"lib": "res://assets/characters/satyr_enemy/satyr_enemy_animations.tres", 
		"height": 1.7, "hp": 160, "dmg": 18.0, "speed": 5.2, 
		"xp": 78, "gold": [14, 26], "aggro": 10.5, "reach": 2.1, 
		"attack_cd": 1.3, "material": "Satyr Horn", 
		"sfx_attack": "satyr_attack", "sfx_death": "satyr_death", 
	}, 
	"harpy_enemy": {
		"name": "Harpy", 
		"level": 8, 
		"glb": "res://assets/characters/harpy_enemy/harpy_enemy.glb", 
		"lib": "res://assets/characters/harpy_enemy/harpy_enemy_animations.tres", 
		"height": 1.75, "hp": 240, "dmg": 24.0, "speed": 5.6, 
		"xp": 120, "gold": [20, 36], "aggro": 11.5, "reach": 2.1, 
		"attack_cd": 1.2, "material": "Harpy Feather", "screech": true, 
		"sfx_attack": "harpy_attack", "sfx_death": "harpy_death", 
	}, 
	"centaur_enemy": {
		"name": "Centaur Warrior", 
		"level": 8, 
		"glb": "res://assets/characters/bone_centaur/bone_centaur.glb", 
		"lib": "", 
		"center_xz": true, 
		"credit": "Sandstone, Bone centaur monster by Nagisa_Kurama — CC-BY 4.0", 
		"height": 2.3, "hp": 320, "dmg": 28.0, "speed": 6.0, 
		"xp": 145, "gold": [28, 48], "aggro": 11.0, "reach": 2.6, 
		"attack_cd": 1.6, "material": "Centaur Hoof", 
		"sfx_attack": "centaur_attack", "sfx_death": "centaur_death", 
		"clips": {
			"idle": "Armature|RestPose", 
			"walk": "Armature|Walking", 
			"sprint": "Armature|Walking", 
			"attack": "Attack", 
			"heavy": "Armature|UpwardStrike", 
			"hit": "Armature|RestPose", 
			"death": "Armature|RestPose", 
		}, 
	}, 
	"gorgon_enemy": {
		"name": "Gorgon", 
		"level": 8, 
		"glb": "res://assets/characters/gorgon_enemy/gorgon_enemy.glb", 
		"lib": "res://assets/characters/gorgon_enemy/gorgon_enemy_animations.tres", 
		"height": 2.0, "hp": 360, "dmg": 30.0, "speed": 4.4, 
		"xp": 160, "gold": [32, 55], "aggro": 10.0, "reach": 2.4, 
		"attack_cd": 1.8, "material": "Gorgon Venom", 
		"sfx_attack": "gorgon_attack", "sfx_death": "gorgon_death", 
	}, 
	"minotaur_boss": {
		"name": "The Minotaur", 
		"level": 15, 
		"glb": "res://assets/characters/minotaur_boss/minotaur_boss.glb", 
		"lib": "res://assets/characters/minotaur_boss/minotaur_boss_animations.tres", 
		"height": 3.4, "hp": 2800, "dmg": 55.0, "speed": 5.0, 
		"xp": 2200, "gold": [400, 600], "aggro": 14.0, "reach": 3.4, 
		"attack_cd": 2.2, "material": "Minotaur Horn", "boss": true, 
		"sfx_attack": "minotaur_attack", "sfx_death": "minotaur_death", 
	}, 
}


const DEFAULT_CLIPS: = {
	"idle": "ual1_Idle", 
	"walk": "ual1_Walk", 
	"sprint": "ual1_Sprint", 
	"attack": "ual1_Sword_Attack", 
	"hit": "ual1_Hit_Chest", 
	"death": "ual1_Death01", 
}

const GRAVITY: = 22.0
const WANDER_RADIUS: = 7.0


const NAME_FONT: = "res://assets/fonts/cinzel.ttf"
const BAR_TEX_W: = 32.0
const BAR_TEX_H: = 4.0
const PLATE_RANGE: = 34.0
const PLATE_RANGE_BOSS: = 75.0
const BAR_RANGE: = 30.0
const PLATE_TICK: = 0.22

enum State{IDLE, CHASE, ATTACK, HIT, DEAD}

var enemy_id: String = "wolf_enemy"
var cfg: Dictionary = {}
var hp: float = 50.0
var max_hp: float = 50.0
var level: int = 1
var dead: bool = false
var is_boss: bool = false

var state: int = State.IDLE
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var attack_hit_done: bool = false
var wander_target: = Vector3.ZERO
var spawn_point: = Vector3.ZERO
var hit_flash: float = 0.0

var mesh_root: Node3D
var anim: AnimationPlayer
var player: Node3D
var world: Node3D

var _skeletal_anims: bool = false
var _death_clip: = "ual1_Death01"
var _clips: Dictionary = {}


var plate: Node3D
var name_label: Label3D
var bar_bg: Sprite3D
var bar_fill: Sprite3D
var beacon: MeshInstance3D
var beacon_mat: StandardMaterial3D
var damaged: bool = false
var targeted: bool = false
var _plate_timer: float = 0.0
var _bar_shown: float = -1.0
var _telegraph_cd: float = 0.0
var _flash_tween: Tween

static var _bar_tex: ImageTexture

static func _get_bar_tex() -> ImageTexture:

	if _bar_tex == null:
		var img: = Image.create_empty(int(BAR_TEX_W), int(BAR_TEX_H), false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		_bar_tex = ImageTexture.create_from_image(img)
	return _bar_tex

static func create(id: String, at: Vector3) -> CharacterBody3D:
	var e: = CharacterBody3D.new()
	e.set_script(load("res://scripts/enemy.gd"))
	e.enemy_id = id
	e.position = at
	return e

func _ready() -> void :
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2
	cfg = ENEMY_CONFIGS.get(enemy_id, ENEMY_CONFIGS["wolf_enemy"])
	level = int(cfg.get("level", 1))
	max_hp = float(cfg["hp"])
	hp = max_hp
	is_boss = cfg.get("boss", false)
	spawn_point = global_position
	wander_target = spawn_point
	_build_body()
	_build_plate()
	if is_boss:
		_build_beacon()
	world = get_tree().get_first_node_in_group("game_world")
	_find_player.call_deferred()

func _find_player() -> void :
	player = get_tree().get_first_node_in_group("player")

func _build_body() -> void :
	var shape: = CollisionShape3D.new()
	var capsule: = CapsuleShape3D.new()
	capsule.radius = 0.4 * (cfg["height"] / 1.8)
	capsule.height = cfg["height"] * 0.9
	shape.shape = capsule
	shape.position.y = cfg["height"] * 0.5
	add_child(shape)

	mesh_root = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)

	_clips = DEFAULT_CLIPS.duplicate()
	if cfg.has("clips"):
		for k in cfg["clips"]:
			_clips[k] = cfg["clips"][k]
	_death_clip = String(_clips.get("death", "ual1_Death01"))

	var glb_path: String = cfg["glb"]
	if ResourceLoader.exists(glb_path):
		var model: Node3D = load(glb_path).instantiate()
		mesh_root.add_child(model)
		# Match pre-chat/server exe (gofile m84Azz3v): animals authored +Z → PI.
		# Do NOT retarget UAL tracks or run posture dampeners — those entangled
		# limbs/sky-gaze on the chat/server build. %GeneralSkeleton resolves via
		# rename + unique_name_in_owner in _prepare_skeleton_for_anims.
		if cfg.get("facing_plus_z", false):
			model.rotation.y = PI
		if cfg.get("maya_cm", false):
			ModelUtils.setup_maya_cm_animal(model, cfg["height"])
		else:
			ModelUtils.setup_character_for_movement(model, cfg["height"])
		ModelUtils.clamp_world_height(model, maxf(cfg["height"] * 2.5, 4.0), cfg["height"])
		if cfg.get("bristle_hide", false):
			_apply_bristle_boar_hide(model)
		elif cfg.has("tint"):
			_apply_tint(model, cfg["tint"])
		anim = model.find_child("AnimationPlayer", true) as AnimationPlayer
		if anim == null:
			anim = AnimationPlayer.new()
			model.add_child(anim)
		var lib_path: String = String(cfg.get("lib", ""))
		if lib_path != "" and ResourceLoader.exists(lib_path):
			var lib: = load(lib_path) as AnimationLibrary
			if lib:
				if anim.has_animation_library(""):
					anim.remove_animation_library("")
				anim.add_animation_library("", lib)
		if cfg.has("slices") and cfg.has("slice_master"):
			_install_sliced_clips(String(cfg["slice_master"]), float(cfg.get("slice_fps", 24.0)), cfg["slices"])
		_skeletal_anims = _prepare_skeleton_for_anims(model)
		ModelUtils.set_animation_loops(anim)
		_force_oneshot_clips([
			_clip("death"), _clip("hit"), _clip("attack"), _clip("heavy"), 
			"ual1_Death01", "ual1_Hit_Chest", "ual1_Sword_Attack", 
			"ual1_Punch_Jab", "ual2_Sword_Heavy_A", "ual2_Sword_Heavy_B", 
			"Death", "Attack", "Attack_Headbutt", "Idle_HitReact1", "Idle_HitReact2", 
		])

		for role in ["idle", "walk", "sprint"]:
			var n: = _clip(role)
			if anim.has_animation(n):
				var a: = anim.get_animation(n)
				if a:
					a.loop_mode = Animation.LOOP_LINEAR
		if bool(cfg.get("center_xz", false)):
			if anim.has_animation(_clip("idle")):
				anim.play(_clip("idle"))
				anim.seek(0.0, true)
			ModelUtils.align_skeleton_to_ground(model)
	if anim and _skeletal_anims:
		_play(_clip("idle"))


func _clip(role: String) -> String:
	return String(_clips.get(role, DEFAULT_CLIPS.get(role, role)))



func _install_sliced_clips(master_name: String, fps: float, slices: Dictionary) -> void :
	if anim == null or not anim.has_animation(master_name):
		return
	var master: = anim.get_animation(master_name)
	if master == null:
		return
	var lib: AnimationLibrary
	if anim.has_animation_library(""):
		lib = anim.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim.add_animation_library("", lib)
	for role in slices.keys():
		var spec: Array = slices[role]
		var from_f: float = float(spec[0])
		var to_f: float = float(spec[1])
		var do_loop: bool = bool(spec[2]) if spec.size() > 2 else false
		var start_s: float = from_f / fps
		var end_s: float = (to_f + 1.0) / fps
		var sliced: = ModelUtils.subclip_animation(master, start_s, end_s, do_loop)
		var clip_name: = String(_clips.get(role, role))
		if lib.has_animation(clip_name):
			lib.remove_animation(clip_name)
		lib.add_animation(clip_name, sliced)






## Humanoid UAL rigs need GeneralSkeleton+Hips. Free animal packs need a Death
## clip whose tracks actually address bones on THIS skeleton.
## Pre-chat exe bind: rename + unique_name so %GeneralSkeleton resolves — never
## rewrite animation tracks (retarget/posture dampen entangled limbs).
func _prepare_skeleton_for_anims(model: Node3D) -> bool:
	if anim == null:
		return false
	var skel: Skeleton3D = null
	for node in model.find_children("*", "Skeleton3D", true, false):
		skel = node as Skeleton3D
		break
	if skel == null:
		return false

	# Must run before any early return: ual1_* bone-name matches look "bound"
	# even while %GeneralSkeleton is still unresolved (silent T-pose).
	if _anim_uses_general_skeleton_paths():
		if skel.name != "GeneralSkeleton":
			skel.name = "GeneralSkeleton"
		skel.unique_name_in_owner = true
		anim.clear_caches()

	for candidate in [_death_clip, "Death", "death", "ual1_Death01"]:
		var cname: = String(candidate)
		if cname == "" or not anim.has_animation(cname):
			continue
		if _anim_binds_to_skeleton(anim.get_animation(cname), skel):
			_death_clip = cname
			_clips["death"] = cname
			return true

	if skel.find_bone("Hips") < 0:
		return false
	if _anim_uses_general_skeleton_paths():
		return anim.has_animation(_clip("idle")) or anim.has_animation("ual1_Idle")
	return false


func _anim_uses_general_skeleton_paths() -> bool:
	if anim == null:
		return false
	for an in anim.get_animation_list():
		var a: = anim.get_animation(an)
		if a == null:
			continue
		for ti in a.get_track_count():
			if String(a.track_get_path(ti)).begins_with("%GeneralSkeleton"):
				return true
	return false


func _anim_binds_to_skeleton(animation: Animation, skel: Skeleton3D) -> bool:
	if animation == null or skel == null:
		return false
	for ti in animation.get_track_count():
		var path: = String(animation.track_get_path(ti))
		var colon: = path.rfind(":")
		if colon < 0:
			continue
		var bone: = path.substr(colon + 1)
		if skel.find_bone(bone) >= 0:
			return true
	return false


func _force_oneshot_clips(names: Array) -> void :
	if anim == null:
		return
	for n in names:
		var clip: = String(n)
		if clip == "" or not anim.has_animation(clip):
			continue
		var a: = anim.get_animation(clip)
		if a:
			a.loop_mode = Animation.LOOP_NONE



func _apply_bristle_boar_hide(model: Node3D) -> void :
	const HIDE: = "res://assets/textures/creatures/boar_hide_bristle.png"
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.88)
	if ResourceLoader.exists(HIDE):
		mat.albedo_texture = load(HIDE)
	mat.roughness = 0.96
	mat.metallic = 0.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for child in model.find_children("*", "MeshInstance3D"):
		var mi: = child as MeshInstance3D
		if mi:
			mi.material_override = mat



func _apply_tint(model: Node3D, tint: Color) -> void :
	for child in model.find_children("*", "MeshInstance3D"):
		var mi: = child as MeshInstance3D
		if mi == null:
			continue
		var base: Material = mi.get_active_material(0)
		var mat: StandardMaterial3D
		if base is StandardMaterial3D:
			mat = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
		else:
			mat = StandardMaterial3D.new()
			if base != null:
				mi.set_surface_override_material(0, mat)
		mat.albedo_color = tint
		mat.roughness = 0.85
		mi.material_override = mat


func _build_plate() -> void :



	var height: float = cfg["height"]
	var big: float = 1.7 if is_boss else 1.0

	plate = Node3D.new()
	plate.name = "Nameplate"
	plate.position.y = height + (0.9 if is_boss else 0.5)
	plate.visible = false
	add_child(plate)

	name_label = Label3D.new()
	name_label.text = "%s  Lv.%d" % [str(cfg["name"]), level]
	if ResourceLoader.exists(NAME_FONT):
		var f: Font = load(NAME_FONT)
		if f:
			name_label.font = f
	name_label.font_size = int(64.0 * big)
	name_label.pixel_size = 0.0038
	name_label.outline_size = 14
	name_label.outline_modulate = Color(0, 0, 0, 0.85)
	name_label.modulate = _plate_color()
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = false
	name_label.shaded = false
	name_label.double_sided = true
	name_label.render_priority = 2
	name_label.outline_render_priority = 1
	plate.add_child(name_label)





	var bar_w: float = 1.15 * (1.9 if is_boss else 1.0)
	var px: float = bar_w / BAR_TEX_W
	var bar_y: float = -0.16 * big

	bar_bg = Sprite3D.new()
	_setup_bar_sprite(bar_bg, px * 1.16, Color(0.03, 0.02, 0.02, 0.8), 0)
	bar_bg.position.y = bar_y
	plate.add_child(bar_bg)

	bar_fill = Sprite3D.new()
	_setup_bar_sprite(bar_fill, px, _bar_color(), 1)
	bar_fill.position.y = bar_y
	plate.add_child(bar_fill)
	_set_bar_fraction(1.0)

func _setup_bar_sprite(s: Sprite3D, px: float, tint: Color, priority: int) -> void :
	s.texture = _get_bar_tex()
	s.pixel_size = px
	s.modulate = tint
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.double_sided = true
	s.no_depth_test = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.render_priority = priority
	s.region_enabled = true
	s.region_rect = Rect2(0.0, 0.0, BAR_TEX_W, BAR_TEX_H)

func _set_bar_fraction(frac: float) -> void :
	if bar_fill == null:
		return
	var w: float = BAR_TEX_W * clampf(frac, 0.0, 1.0)
	bar_fill.region_rect = Rect2(0.0, 0.0, maxf(w, 0.01), BAR_TEX_H)

	bar_fill.offset = Vector2((w - BAR_TEX_W) * 0.5, 0.0)

func _plate_color() -> Color:
	if targeted:
		return Color(1.0, 0.96, 0.72)
	if is_boss:
		return Color(1.0, 0.52, 0.26)
	return Color(0.93, 0.91, 0.87)

func _bar_color() -> Color:
	return Color(1.0, 0.34, 0.12) if is_boss else Color(0.86, 0.22, 0.18)

func _build_beacon() -> void :


	var quad: = QuadMesh.new()
	quad.size = Vector2(0.55, 18.0)
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beacon_mat.albedo_color = Color(1.0, 0.3, 0.14, 0.28)
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color(1.0, 0.38, 0.16)
	beacon_mat.emission_energy_multiplier = 2.2
	beacon_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	beacon_mat.billboard_keep_scale = true
	beacon_mat.no_depth_test = true
	beacon_mat.disable_receive_shadows = true
	beacon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beacon = MeshInstance3D.new()
	beacon.name = "BossBeacon"
	beacon.mesh = quad
	beacon.material_override = beacon_mat
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.position.y = float(cfg["height"]) + 10.0
	beacon.visible = false
	add_child(beacon)

func _update_plate() -> void :
	if beacon != null:
		var hunting: bool = not dead and (state == State.CHASE or state == State.ATTACK or state == State.HIT)
		if beacon.visible != hunting:
			beacon.visible = hunting
		if hunting and beacon_mat != null:
			beacon_mat.albedo_color.a = 0.22 + 0.14 * sin(float(Time.get_ticks_msec()) * 0.004)
	if plate == null:
		return
	if dead:
		if plate.visible:
			plate.visible = false
		return
	var dist: float = _player_distance()
	var show_plate: bool = targeted or dist < (PLATE_RANGE_BOSS if is_boss else PLATE_RANGE)
	if plate.visible != show_plate:
		plate.visible = show_plate
	if not show_plate:
		return
	var show_bar: bool = targeted or damaged or dist < BAR_RANGE
	if bar_bg.visible != show_bar:
		bar_bg.visible = show_bar
		bar_fill.visible = show_bar
	if not show_bar:
		return
	var frac: float = clampf(hp / maxf(1.0, float(cfg["hp"])), 0.0, 1.0)
	if absf(frac - _bar_shown) > 0.004:
		_bar_shown = frac
		_set_bar_fraction(frac)


func set_targeted(on: bool) -> void :
	if targeted == on or dead:
		return
	targeted = on
	if name_label == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	name_label.text = ("[ %s ]" % str(cfg["name"])) if on else str(cfg["name"])
	name_label.modulate = _plate_color()
	name_label.outline_modulate = Color(0.5, 0.36, 0.06, 0.95) if on else Color(0, 0, 0, 0.85)
	if bar_bg != null:
		bar_bg.modulate = Color(0.16, 0.12, 0.03, 0.88) if on else Color(0.03, 0.02, 0.02, 0.8)
	_plate_timer = 0.0

func _telegraph_aggro() -> void :

	if player != null and is_instance_valid(player):
		PartyShare.note(self, player)
	PartyShare.note_nearby(self, global_position, float(cfg.get("aggro", 10.0)))
	if _telegraph_cd > 0.0:
		return
	_telegraph_cd = 5.0
	var notice: String = String(cfg.get("sfx_aggro", cfg.get("sfx_death", "enemy_growl")))
	AudioManager.play_sfx(notice, -5.0, randf_range(0.94, 1.06))
	if is_boss:
		AudioManager.play_sfx("minotaur_roar", -1.0)
	_flash_plate()

func _flash_plate() -> void :
	if name_label == null:
		return
	plate.visible = true
	if bar_bg != null:
		bar_bg.visible = true
		bar_fill.visible = true
	name_label.modulate = Color(1.0, 0.16, 0.1)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	_flash_tween = name_label.create_tween()
	_flash_tween.tween_property(name_label, "modulate", _plate_color(), 0.8).set_delay(0.3)

func _physics_process(delta: float) -> void :
	_plate_timer -= delta
	if _plate_timer <= 0.0:
		_plate_timer = PLATE_TICK
		_update_plate()
	_telegraph_cd = maxf(0.0, _telegraph_cd - delta)

	if dead:


		velocity = Vector3.ZERO
		return

	if player == null or not is_instance_valid(player):
		_find_player()
		if player == null:
			_apply_gravity(delta)
			move_and_slide()
			return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	state_timer = maxf(0.0, state_timer - delta)

	match state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HIT:
			if state_timer <= 0.0:
				if player != null and is_instance_valid(player) and _world_is_sanctuary(player.global_position):
					_abandon_to_home()
				else:
					state = State.CHASE

	_apply_gravity(delta)
	move_and_slide()

func _process_idle(delta: float) -> void :

	var to_target: Vector3 = wander_target - global_position
	to_target.y = 0
	if to_target.length() < 1.0 or state_timer <= 0.0:
		state_timer = randf_range(2.0, 5.0)
		var offset: = Vector3(randf_range( - WANDER_RADIUS, WANDER_RADIUS), 0, randf_range( - WANDER_RADIUS, WANDER_RADIUS))
		wander_target = spawn_point + offset
		velocity.x = 0
		velocity.z = 0
		_play(_clip("idle"))
	else:
		velocity.x = to_target.normalized().x * cfg["speed"] * 0.35
		velocity.z = to_target.normalized().z * cfg["speed"] * 0.35
		_face(to_target, delta)
		_play(_clip("walk"))


	if player != null and is_instance_valid(player) and _world_is_sanctuary(player.global_position):
		return
	if _player_distance() < float(cfg["aggro"]):
		state = State.CHASE
		_telegraph_aggro()

func _process_chase(delta: float) -> void :
	var dist: = _player_distance()


	if player != null and is_instance_valid(player):
		if _world_is_sanctuary(player.global_position) or _world_is_sanctuary(global_position):
			_abandon_to_home()
			return


	if dist > maxf(float(cfg["aggro"]) * 2.0, 16.0):
		_abandon_to_home()
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0
	if dist <= cfg["reach"] and attack_cooldown <= 0.0:
		state = State.ATTACK
		state_timer = 0.7 if is_boss else 0.55
		attack_hit_done = false
		attack_cooldown = cfg["attack_cd"]
		velocity.x = 0
		velocity.z = 0
		_face(to_player, 1.0)
		_play(_attack_clip(), false)

		_play_attack_sfx()
	else:
		var step: Vector3 = to_player.normalized() * float(cfg["speed"]) * delta
		var next_pos: Vector3 = global_position + step
		if world != null and world.has_method("would_enter_sanctuary")\
		and world.would_enter_sanctuary(global_position, next_pos):
			_abandon_to_home()
			return
		velocity.x = to_player.normalized().x * float(cfg["speed"])
		velocity.z = to_player.normalized().z * float(cfg["speed"])
		_face(to_player, delta)
		_play(_clip("sprint"))


func _abandon_to_home() -> void :
	state = State.IDLE
	state_timer = 0.25
	wander_target = spawn_point
	velocity.x = 0.0
	velocity.z = 0.0


func _world_is_sanctuary(pos: Vector3) -> bool:
	if world == null:
		world = get_tree().get_first_node_in_group("game_world")
	if world != null and world.has_method("is_sanctuary"):
		return bool(world.is_sanctuary(pos))
	return false

func _play_attack_sfx() -> void :

	var key: String = String(cfg.get("sfx_attack", "enemy_growl"))
	AudioManager.play_sfx(key, -2.0, randf_range(0.94, 1.08))

func _play_attack_hit_sfx() -> void :

	var key: String = String(cfg.get("sfx_attack_alt", ""))
	if key.is_empty():
		return
	AudioManager.play_sfx(key, -5.0, randf_range(0.96, 1.06))

func _process_attack(_delta: float) -> void :
	velocity.x = 0
	velocity.z = 0

	if player != null and is_instance_valid(player) and _world_is_sanctuary(player.global_position):
		_abandon_to_home()
		return
	if not attack_hit_done and state_timer <= 0.25:
		attack_hit_done = true

		_play_attack_hit_sfx()
		if _player_distance() <= cfg["reach"] + 0.7:
			if player.has_method("take_damage"):
				player.take_damage(cfg["dmg"], global_position)

			if is_boss:
				VfxHelper.spawn_hit(player.global_position + Vector3(0, 1.0, 0), self)
	if state_timer <= 0.0:
		state = State.CHASE

func _attack_clip() -> String:
	match enemy_id:
		"minotaur_boss":
			return "ual2_Sword_Heavy_A" if randf() < 0.5 else _clip("attack")
		"centaur_enemy":
			return _clip("heavy") if _clips.has("heavy") and randf() < 0.4 else _clip("attack")
		_:
			return _clip("attack")

func _player_distance() -> float:
	if player == null:
		return 9999.0
	var d: Vector3 = player.global_position - global_position
	d.y = 0
	return d.length()

func _face(dir: Vector3, delta: float) -> void :
	if dir.length_squared() < 0.001:
		return
	var target_yaw: = ModelUtils.yaw_from_direction(dir)
	var w: = clampf(10.0 * delta, 0.0, 1.0)
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_yaw, w)

func _apply_gravity(delta: float) -> void :
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5

func _play(clip: String, loop_ok: bool = true) -> void :
	if anim == null or not anim.has_animation(clip):
		return
	if anim.current_animation == clip and loop_ok:
		return
	anim.play(clip)

func take_damage(amount: float, from_position: Vector3) -> void :
	if dead:
		return
	hp -= amount
	DamageNumbers.spawn(get_parent(), global_position + Vector3(0, cfg["height"] + 0.3, 0), int(amount))

	damaged = true
	_plate_timer = 0.0
	_update_plate()

	if player != null and is_instance_valid(player):
		PartyShare.note(self, player)
	PartyShare.note_nearby(self, from_position, 5.0)

	if player != null and is_instance_valid(player) and player.has_method("add_camera_shake"):
		player.add_camera_shake(0.05, 0.14)

	if state == State.IDLE:
		state = State.CHASE
		_telegraph_aggro()
		if player != null:
			PartyShare.note(self, player)
	if hp <= 0.0:
		_die()
		return

	if not is_boss and state != State.ATTACK:
		state = State.HIT
		state_timer = 0.35
		_play(_clip("hit"), false)
	velocity += (global_position - from_position).normalized() * 2.2

func _die() -> void :
	dead = true
	state = State.DEAD
	targeted = false
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 1
	var death_sfx: String = String(cfg.get("sfx_death", "hit_flesh"))
	AudioManager.play_sfx(death_sfx, -1.0, randf_range(0.92, 1.05))

	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	if plate != null:
		plate.visible = false
	if beacon != null:
		beacon.visible = false


	var foe_lvl: int = int(cfg.get("level", 1))
	if player != null:
		PartyShare.note(self, player)
	PartyShare.note_nearby(self, global_position, float(cfg.get("aggro", 10.0)) * 1.5)
	var gold_range: Array = cfg["gold"]
	var gold_amount: int = GameState.roll_gold_drop(
		int(gold_range[0]), int(gold_range[1]), foe_lvl)

	PartyShare.award_xp_and_gold(self, int(cfg["xp"]), gold_amount)
	_spawn_world_loot(foe_lvl, false)
	GameState.register_kill(String(cfg.get("quest_id", enemy_id)))
	if is_boss:
		GameState.register_minotaur_kill()
	enemy_died.emit(enemy_id, global_position)



	var settle_s: float = _start_death_performance()
	print("[enemy] death id=", enemy_id, " skeletal=", _skeletal_anims, 
		" clip=", _death_clip, " settle_s=", settle_s)
	var tree: = get_tree()
	if tree:
		var t: = tree.create_timer(settle_s)
		t.timeout.connect(_fade_out)



func _spawn_world_loot(foe_lvl: int, include_gold: bool = false) -> void :
	var parent: = get_parent()
	if parent == null:
		return
	var LootPickup: = load("res://scripts/loot_pickup.gd")
	if LootPickup == null:
		return
	if include_gold:
		var gold_range: Array = cfg["gold"]
		var gold_amount: int = GameState.roll_gold_drop(
			int(gold_range[0]), int(gold_range[1]), foe_lvl)
		_spawn_one_drop(LootPickup, parent, "gold_coin", gold_amount)


	var mat_name: String = String(cfg.get("material", ""))
	if mat_name != "":
		var mat_id: String = GameState.material_item_id(mat_name)
		if mat_id == "":
			mat_id = "mat_" + mat_name.to_lower().replace(" ", "_")
		_spawn_one_drop(LootPickup, parent, mat_id, 0)

	if randf() < 0.12:
		_spawn_one_drop(LootPickup, parent, "health_potion", 0)

	var rolls: = 2 if is_boss else 1
	var chance: = 0.55 if is_boss else 0.38
	chance += clampf(float(foe_lvl) * 0.03, 0.0, 0.2)
	for _i in rolls:
		var loot_id: String = GameState.roll_loot_drop(chance, is_boss, foe_lvl)
		if loot_id == "":
			continue
		_spawn_one_drop(LootPickup, parent, loot_id, 0)


func _spawn_one_drop(LootPickup: Script, parent: Node, loot_id: String, gold_value: int) -> void :
	if LootPickup == null or parent == null or loot_id == "":
		return
	var drop: Node = LootPickup.new()
	if drop == null:
		return
	parent.add_child(drop)
	if drop.has_method("setup"):
		drop.call("setup", loot_id, global_position + Vector3(0, 0.2, 0), gold_value)




func _start_death_performance() -> float:
	var skeletal_len: = 0.0
	if _skeletal_anims and anim != null and anim.has_animation(_death_clip):
		var clip: = anim.get_animation(_death_clip)
		if clip:
			clip.loop_mode = Animation.LOOP_NONE
			skeletal_len = clip.length
		anim.stop()
		anim.play(_death_clip)

		anim.animation_finished.connect(_on_death_anim_finished, CONNECT_ONE_SHOT)


		var hold: = 2.4 if is_boss else 2.0
		return maxf(skeletal_len, 1.2) + hold


	return _play_procedural_death()


func _on_death_anim_finished(anim_name: StringName) -> void :
	if String(anim_name) != _death_clip or anim == null:
		return

	anim.pause()
	anim.seek(anim.current_animation_length, true)



func _play_procedural_death() -> float:
	if mesh_root == null:
		return 1.6
	var fall_sign: = 1.0 if randf() < 0.5 else -1.0

	var target_z: float = mesh_root.rotation.z + fall_sign * (PI * 0.5)
	var target_x: float = mesh_root.rotation.x - 0.35
	var start_y: float = mesh_root.position.y
	var tween: = create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_root, "rotation:z", target_z, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(mesh_root, "rotation:x", target_x, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(mesh_root, "position:y", start_y + 0.35, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(mesh_root, "position:y", start_y - 0.08, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return 2.2


func _fade_out() -> void :
	if not is_instance_valid(self):
		return
	var tween: = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 1.6, 1.2)

	for mi in find_children("*", "MeshInstance3D", true, false):
		var mesh_i: = mi as MeshInstance3D
		if mesh_i == null:
			continue
		tween.tween_property(mesh_i, "transparency", 1.0, 1.0)
	tween.chain().tween_callback(queue_free)
