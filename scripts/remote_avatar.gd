extends CharacterBody3D
## Lightweight remote champion — mesh, nameplate, PvP hitbox. Driven by NetSession.

const CharacterGLB := "res://assets/characters/quaternius_hero_king/hero_king.glb"
const CharacterLib := ""
const NameplateScript = preload("res://scripts/player_nameplate.gd")
const HeroAnim = preload("res://scripts/utils/hero_anim.gd")

var peer_id: int = 0
var empire_id: String = "sparta"
var display_name: String = "Champion"
var level: int = 1
var hp: float = 100.0
var max_hp: float = 100.0
var dead: bool = false

var mesh_root: Node3D
var anim: AnimationPlayer
var _nameplate: Node3D
var _target_pos: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _has_target: bool = false


func setup(p_peer: int, p_name: String, p_empire: String, p_level: int) -> void:
	peer_id = p_peer
	display_name = p_name
	empire_id = p_empire
	level = maxi(1, p_level)
	set_meta("empire", empire_id)
	set_meta("chat_name", display_name)
	set_meta("level", level)
	set_meta("peer_id", peer_id)


func _ready() -> void:
	add_to_group("player")
	add_to_group("remote_player")
	collision_layer = 2
	collision_mask = 1
	_build_body()
	_nameplate = NameplateScript.new()
	add_child(_nameplate)
	(_nameplate as Node).call("set_plate", display_name, level, empire_id)
	_target_pos = global_position


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
	if ResourceLoader.exists(CharacterGLB):
		var model: Node3D = load(CharacterGLB).instantiate()
		mesh_root.add_child(model)
		ModelUtils.setup_character_for_movement(model, 1.85)
		anim = model.find_child("AnimationPlayer", true) as AnimationPlayer
		if anim == null:
			anim = AnimationPlayer.new()
			anim.name = "AnimationPlayer"
			model.add_child(anim)
		if CharacterLib != "" and ResourceLoader.exists(CharacterLib):
			var lib := load(CharacterLib) as AnimationLibrary
			if lib:
				if anim.has_animation_library(""):
					anim.remove_animation_library("")
				anim.add_animation_library("", lib)
		if anim != null:
			ModelUtils.set_animation_loops(anim)
			ModelUtils.bind_leg_plant_anim(model, anim)
			HeroAnim.play(anim, "idle")
	_tint_empire(empire_id)


func _tint_empire(emp: String) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var data: Dictionary = gs.EMPIRES.get(emp, {})
	if not data.has("color"):
		return
	var tint: Color = data["color"].lightened(0.25)
	for node in mesh_root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mi.material_override = mat


func apply_state(pos: Vector3, yaw: float, p_hp: float, p_max_hp: float, p_level: int, moving: bool) -> void:
	_target_pos = pos
	_target_yaw = yaw
	_has_target = true
	hp = p_hp
	max_hp = p_max_hp
	if p_level != level:
		level = p_level
		set_meta("level", level)
		if _nameplate:
			_nameplate.call("set_plate", display_name, level, empire_id)
	if anim and not dead:
		HeroAnim.play(anim, "walk" if moving else "idle")


func _physics_process(delta: float) -> void:
	if not _has_target or dead:
		return
	global_position = global_position.lerp(_target_pos, clampf(12.0 * delta, 0.0, 1.0))
	if mesh_root:
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, _target_yaw, 10.0 * delta)


func take_damage(amount: float, from_position: Vector3) -> void:
	if dead:
		return
	var net := get_node_or_null("/root/NetSession")
	if net != null and net.has_method("request_damage"):
		net.call("request_damage", peer_id, amount, from_position)


func mark_dead() -> void:
	dead = true
	if anim:
		HeroAnim.play(anim, "death", false)
