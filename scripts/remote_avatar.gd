extends CharacterBody3D
## Other players in the world — class-correct mesh, chat bubble, party/duel tint.


const NameplateScript = preload("res://scripts/player_nameplate.gd")
const HeroAnim = preload("res://scripts/utils/hero_anim.gd")
const FALLBACK_GLB: = "res://assets/characters/hoplite_chan/hoplite_chan.glb"

var peer_id: int = 0
var empire_id: String = "sparta"
var class_id: String = "hoplite"
var display_name: String = "Champion"
var level: int = 1
var hp: float = 100.0
var max_hp: float = 100.0
var dead: bool = false
var in_party: bool = false
var in_duel: bool = false

var mesh_root: Node3D
var anim: AnimationPlayer
var _nameplate: Node3D
var _model: Node3D
var _chat_bubble: Label3D = null
var _bubble_timer: float = 0.0
var _target_pos: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _has_target: bool = false


func setup(p_peer: int, p_name: String, p_empire: String, p_level: int, p_class: String = "hoplite") -> void:
	peer_id = p_peer
	display_name = p_name
	empire_id = p_empire
	class_id = p_class if p_class != "" else "hoplite"
	level = maxi(1, p_level)
	set_meta("empire", empire_id)
	set_meta("chat_name", display_name)
	set_meta("level", level)
	set_meta("peer_id", peer_id)
	set_meta("player_class", class_id)
	if is_inside_tree() and mesh_root != null:
		_rebuild_model()
		if _nameplate:
			_nameplate.call("set_plate", display_name, level, empire_id)


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
	if ChatSystem != null and not ChatSystem.message_received.is_connected(_on_chat_message):
		ChatSystem.message_received.connect(_on_chat_message)
	if PartyShare != null and not PartyShare.party_changed.is_connected(_on_party_changed):
		PartyShare.party_changed.connect(_on_party_changed)
	_on_party_changed()


func _build_body() -> void:
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
	_rebuild_model()


func _rebuild_model() -> void:
	if mesh_root == null:
		return
	## Free immediately — queue_free leaves stale skinned meshes for a frame
	## and can leave remotes as floating weapons while the body is mid-replace.
	for c in mesh_root.get_children():
		mesh_root.remove_child(c)
		c.free()
	_model = null
	anim = null
	var path: = FALLBACK_GLB
	var cd: Dictionary = {}
	var gs: = get_node_or_null("/root/GameState")
	if gs != null:
		cd = gs.CLASSES.get(class_id, {})
		var p: = String(cd.get("character", ""))
		if p != "" and ResourceLoader.exists(p):
			path = p
	if not ResourceLoader.exists(path):
		path = "res://assets/characters/greek_hoplite/greek_hoplite.glb"
	if not ResourceLoader.exists(path):
		return
	_model = load(path).instantiate()
	mesh_root.add_child(_model)
	## Must match player.gd: Hoplite Chan / builtin-weapon rigs are already in
	## meters. setup_character_for_movement runs Maya-cm *100 on small prop
	## meshes then crushes the root (~0.012) — body vanishes, weapons float.
	var authored: = bool(cd.get("builtin_weapons", false)) \
		or path.contains("hoplite_chan")
	if authored:
		ModelUtils.setup_authored_humanoid(_model, 1.85)
	else:
		ModelUtils.setup_character_for_movement(_model, 1.85)
	_harden_body_materials(_model)
	anim = _model.find_child("AnimationPlayer", true) as AnimationPlayer
	if anim == null:
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		_model.add_child(anim)
	ModelUtils.set_animation_loops(anim)
	ModelUtils.bind_leg_plant_anim(_model, anim)
	HeroAnim.play(anim, "idle")
	_apply_status_tint()


func _harden_body_materials(model: Node3D) -> void:
	## Hoplite Chan body surface ships with ALPHA_DEPTH_PRE_PASS; on some
	## drivers that sorts the body away while opaque weapons stay. Force opaque.
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


func _on_party_changed() -> void:
	in_party = false
	if PartyShare != null:
		var roster: = PartyShare.member_list()
		if roster.size() > 1:
			for row in roster:
				if int(row.get("peer_id", -1)) == peer_id:
					in_party = true
					break
	_apply_status_tint()


func set_duel_active(active: bool) -> void:
	in_duel = active
	_apply_status_tint()


func _apply_status_tint() -> void:
	## Soft multiply tint — keeps textures (fixes pink flat override).
	if _model == null:
		return
	var tint: Color = Color(1, 1, 1, 1)
	if in_party:
		tint = Color(0.55, 0.75, 1.0) ## friendly blue
	elif in_duel:
		tint = Color(1.0, 0.55, 0.45) ## duel orange-red
	for node in _model.find_children("*", "MeshInstance3D", true, false):
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
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0 and _chat_bubble != null:
			_chat_bubble.visible = false
	if not _has_target or dead:
		return
	global_position = global_position.lerp(_target_pos, clampf(12.0 * delta, 0.0, 1.0))
	if mesh_root:
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, _target_yaw, 10.0 * delta)


func take_damage(amount: float, from_position: Vector3) -> void:
	if dead:
		return
	var net: = get_node_or_null("/root/NetSession")
	if net != null and net.has_method("request_damage"):
		net.call("request_damage", peer_id, amount, from_position)


func mark_dead() -> void:
	dead = true
	if anim:
		HeroAnim.play(anim, "death", false)


func play_skill_fx(_skill_id: String, origin: Vector3, yaw: float, _p_class: String) -> void:
	if mesh_root:
		mesh_root.rotation.y = yaw
	if anim:
		if HeroAnim.play(anim, "skill", false) == "":
			HeroAnim.play(anim, "attack_heavy", false)
	var VfxHelper = load("res://scripts/vfx_helper.gd")
	if VfxHelper != null and VfxHelper.has_method("spawn_strike"):
		VfxHelper.spawn_strike(origin + Vector3(0, 0.5, 0), Vector3.FORWARD.rotated(Vector3.UP, yaw), get_parent())


func _on_chat_message(sender: String, text: String, _stamp: float, peer: int = -1) -> void:
	if text == "" or sender == "Herald" or sender.begins_with("["):
		return
	var mine: = display_name
	var match_name: = sender == mine or sender == String(get_meta("chat_name", ""))
	var match_peer: = peer > 0 and peer == peer_id
	if not match_name and not match_peer:
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
		_chat_bubble.modulate = Color(1.0, 0.92, 0.55)
		_chat_bubble.width = 900.0
		_chat_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chat_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_chat_bubble)
		_chat_bubble.position = Vector3(0, 2.35, 0)
	_chat_bubble.text = line
	_chat_bubble.visible = true
	_bubble_timer = 6.5
