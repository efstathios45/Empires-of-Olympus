extends StaticBody3D












var npc_id: String = "priestess"
var display_name: String = "Villager"
var glb_path: String = ""
var lib_path: String = ""
var height_m: float = 1.75
var spawn_yaw: float = 0.0

var _base_yaw: float = 0.0

var idle_clip: String = "Idle_Neutral"

var greek_role: String = "citizen"

var flavour_line: String = ""

const BUBBLE_SECONDS: = 4.5
const FACE_SECONDS: = 4.0

var _model: Node3D
var _anim: AnimationPlayer
var _player: Node3D
var _bubble: Label3D = null
var _face_tween: Tween = null
var _idle_variants: PackedStringArray = PackedStringArray()
var _idle_timer: float = 0.0
var _idle_idx: int = 0

static func create(p_id: String, p_name: String, p_glb: String, p_lib: String, 
		at: Vector3, p_height: float, yaw_deg: float) -> StaticBody3D:
	var n: = StaticBody3D.new()
	n.set_script(load("res://scripts/npc.gd"))
	n.npc_id = p_id
	n.display_name = p_name
	n.glb_path = p_glb
	n.lib_path = p_lib
	n.height_m = p_height
	n.spawn_yaw = deg_to_rad(yaw_deg)
	n.position = at
	return n


static func create_flavour(p_id: String, p_name: String, p_glb: String, p_lib: String, 
		at: Vector3, p_height: float, yaw_deg: float, 
		p_idle: String, line: String) -> StaticBody3D:
	var n: = create(p_id, p_name, p_glb, p_lib, at, p_height, yaw_deg)
	n.idle_clip = p_idle
	n.flavour_line = line
	return n

func _ready() -> void :
	collision_layer = 1
	collision_mask = 0
	var shape: = CollisionShape3D.new()
	var capsule: = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = height_m * 0.9
	shape.shape = capsule
	shape.position.y = height_m * 0.5
	add_child(shape)

	var scene: PackedScene = null
	if ResourceLoader.exists(glb_path):
		scene = load(glb_path) as PackedScene
	if scene != null:
		_model = scene.instantiate()
		add_child(_model)

		_base_yaw = _model.rotation.y
		ModelUtils.setup_character_for_movement(_model, height_m)
		_model.rotation.y = _base_yaw + spawn_yaw

		var gpath: = glb_path.to_lower()
		var is_hellenic_cast: = "/greek_" in gpath or gpath.contains("greek_hoplite")
		if not is_hellenic_cast and ("hero_king" in gpath or "quaternius_guard" in gpath\
		or "guard_adventurer" in gpath):
			var GreekLook = load("res://scripts/utils/greek_look.gd")
			GreekLook.apply(_model, "guard")
		_anim = _model.find_child("AnimationPlayer", true) as AnimationPlayer
		if _anim == null:
			_anim = AnimationPlayer.new()
			_anim.name = "AnimationPlayer"
			_model.add_child(_anim)
		if lib_path != "" and ResourceLoader.exists(lib_path):
			var lib: = load(lib_path) as AnimationLibrary
			if lib:
				_anim.add_animation_library("", lib)
		ModelUtils.set_animation_loops(_anim)
		ModelUtils.bind_leg_plant_anim(_model, _anim)
		if not _anim.has_animation(idle_clip):
			if _anim.has_animation("Idle"):
				idle_clip = "Idle"
			elif _anim.has_animation("Idle_Neutral"):
				idle_clip = "Idle_Neutral"
			elif _anim.has_animation("ual1_Idle"):
				idle_clip = "ual1_Idle"
		_idle_variants = _collect_idle_variants()
		if _anim.has_animation(idle_clip):
			_anim.play(idle_clip)
		_idle_timer = randf_range(2.5, 5.0)
		set_process(true)


	var world: = get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("sample_height"):
		global_position.y = world.sample_height(global_position.x, global_position.z)


func _collect_idle_variants() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if _anim == null:
		return out
	for clip in [idle_clip, "Idle", "Idle_Neutral", "Idle_Sword", "Wave", "Interact", 
			"ual1_Idle", "ual1_Idle_Talking", "ual1_Idle_LookAround", "ual2_Idle_FoldArms", "ual2_Idle_Rail"]:
		if _anim.has_animation(clip) and not out.has(clip):
			out.append(clip)
	return out


func _process(delta: float) -> void :
	if _anim == null or _idle_variants.is_empty():
		return

	if _face_tween != null and _face_tween.is_running():
		return
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = randf_range(3.0, 6.5)
	_idle_idx = (_idle_idx + 1 + randi() % maxi(1, _idle_variants.size())) % _idle_variants.size()
	var next: = _idle_variants[_idle_idx]
	if _anim.current_animation != next:
		_anim.play(next)

func get_prompt() -> String:
	return "Speak with %s" % display_name

func interact() -> void :

	_face_local_player()
	if flavour_line != "":
		_say(flavour_line)
		return
	var hud: = get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	if npc_id == "priestess" and hud.has_method("open_dialogue"):
		hud.open_dialogue(self)
	elif npc_id == "smith" and hud.has_method("open_smith"):
		hud.open_smith(self)



func _face_local_player() -> void :
	if _model == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null or not is_instance_valid(_player):
		return
	var dir: Vector3 = _player.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return

	var target_yaw: float = _base_yaw + ModelUtils.yaw_from_direction(dir.normalized())
	if _face_tween != null and _face_tween.is_valid():
		_face_tween.kill()
	_face_tween = create_tween()
	_face_tween.tween_property(_model, "rotation:y", target_yaw, 0.28)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_face_tween.tween_interval(FACE_SECONDS)
	_face_tween.tween_property(_model, "rotation:y", _base_yaw + spawn_yaw, 0.45)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)





func _say(line: String) -> void :
	if _bubble == null or not is_instance_valid(_bubble):
		_bubble = Label3D.new()
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.shaded = false
		_bubble.double_sided = true
		_bubble.no_depth_test = false
		_bubble.pixel_size = 0.0038
		_bubble.font_size = 96
		_bubble.outline_size = 26
		_bubble.outline_modulate = Color(0.05, 0.04, 0.03, 0.95)

		_bubble.modulate = Color(1.0, 0.84, 0.28)
		_bubble.width = 900.0
		_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_bubble)
		_bubble.position = Vector3(0.0, height_m + 0.55, 0.0)
	_bubble.text = line
	_bubble.visible = true
	get_tree().create_timer(BUBBLE_SECONDS).timeout.connect(_hide_bubble, 
		CONNECT_ONE_SHOT)

func _hide_bubble() -> void :
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.visible = false
