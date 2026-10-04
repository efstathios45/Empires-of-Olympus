extends StaticBody3D
## NPC — a friendly face in the city. Shows a prompt; E speaks with them.
##
## Motion/idle path restored from pre-chat/server Windows exe (gofile m84Azz3v):
## load UAL lib as-authored, play ual1_* (or native) idle, no track retarget and
## no posture/LegPlant dampeners. Facing uses spawn yaw; on E, turn with +PI
## for UAL +Z fronts.

var npc_id: String = "priestess"
var display_name: String = "Villager"
var glb_path: String = ""
var lib_path: String = ""
var height_m: float = 1.75
var spawn_yaw: float = 0.0
## Which looping clip this NPC idles in (townsfolk vary so the crowd isn't clones).
var idle_clip: String = "ual1_Idle"
## Non-empty = this NPC is townsfolk: E shows this remark instead of a panel.
var flavour_line: String = ""

const BUBBLE_SECONDS := 4.5
const FACE_SECONDS := 4.0

var _model: Node3D
var _anim: AnimationPlayer
var _player: Node3D
var _bubble: Label3D = null
var _face_tween: Tween = null

static func create(p_id: String, p_name: String, p_glb: String, p_lib: String,
		at: Vector3, p_height: float, yaw_deg: float) -> StaticBody3D:
	var n := StaticBody3D.new()
	n.set_script(load("res://scripts/npc.gd"))
	n.npc_id = p_id
	n.display_name = p_name
	n.glb_path = p_glb
	n.lib_path = p_lib
	n.height_m = p_height
	n.spawn_yaw = deg_to_rad(yaw_deg)
	n.position = at
	return n

## Townsfolk: same rig, but E just shows `line`. `p_idle` picks their idle clip.
static func create_flavour(p_id: String, p_name: String, p_glb: String, p_lib: String,
		at: Vector3, p_height: float, yaw_deg: float,
		p_idle: String, line: String) -> StaticBody3D:
	var n := create(p_id, p_name, p_glb, p_lib, at, p_height, yaw_deg)
	n.idle_clip = p_idle
	n.flavour_line = line
	return n

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
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
		ModelUtils.setup_character_for_movement(_model, height_m)
		_model.rotation.y = spawn_yaw
		_anim = _model.find_child("AnimationPlayer", true) as AnimationPlayer
		if _anim == null:
			_anim = AnimationPlayer.new()
			_model.add_child(_anim)
		if lib_path != "" and ResourceLoader.exists(lib_path):
			var lib := load(lib_path) as AnimationLibrary
			if lib:
				if _anim.has_animation_library(""):
					_anim.remove_animation_library("")
				_anim.add_animation_library("", lib)
		# Resolve %GeneralSkeleton UAL tracks the same way the old exe did for
		# humanoid enemies: rename + scene-unique name (never rewrite tracks).
		_bind_ual_skeleton(_model)
		ModelUtils.set_animation_loops(_anim)
		if not _anim.has_animation(idle_clip):
			idle_clip = "ual1_Idle"
		if _anim.has_animation(idle_clip):
			_anim.play(idle_clip)

	# Ground on the terrain.
	var world := get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("sample_height"):
		global_position.y = world.sample_height(global_position.x, global_position.z)


func _bind_ual_skeleton(model: Node3D) -> void:
	if model == null or _anim == null:
		return
	var skel: Skeleton3D = null
	for node in model.find_children("*", "Skeleton3D", true, false):
		skel = node as Skeleton3D
		break
	if skel == null or skel.find_bone("Hips") < 0:
		return
	if skel.name != "GeneralSkeleton":
		skel.name = "GeneralSkeleton"
	skel.unique_name_in_owner = true


func get_prompt() -> String:
	return "Speak with %s" % display_name

func interact() -> void:
	# Local-only face toward the interacting player (multiplayer-safe later).
	_face_local_player()
	if flavour_line != "":
		_say(flavour_line)
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	if npc_id == "priestess" and hud.has_method("open_dialogue"):
		hud.open_dialogue(self)
	elif npc_id == "smith" and hud.has_method("open_smith"):
		hud.open_smith(self)


## Client-side turn toward the local player, then ease back to spawn facing.
func _face_local_player() -> void:
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
	# Humanoid UAL rigs face +Z in these GLBs; yaw_from_direction aims -Z.
	# Without the PI flip, E turns them so the player sees the back of the head.
	var target_yaw: float = ModelUtils.yaw_from_direction(dir.normalized()) + PI
	if _face_tween != null and _face_tween.is_valid():
		_face_tween.kill()
	_face_tween = create_tween()
	_face_tween.tween_property(_model, "rotation:y", target_yaw, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_face_tween.tween_interval(FACE_SECONDS)
	_face_tween.tween_property(_model, "rotation:y", spawn_yaw, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ── Flavour chatter ──────────────────────────────────────────────────────

## Show a one-off remark above this NPC's head (speech bubble only — no HUD
## duplicate toast; that was reading as a "double message" on E).
func _say(line: String) -> void:
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
		_bubble.modulate = Color(1.0, 0.96, 0.85)
		_bubble.width = 900.0
		_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_bubble)
		_bubble.position = Vector3(0.0, height_m + 0.55, 0.0)
	_bubble.text = line
	_bubble.visible = true
	get_tree().create_timer(BUBBLE_SECONDS).timeout.connect(_hide_bubble,
		CONNECT_ONE_SHOT)

func _hide_bubble() -> void:
	if _bubble != null and is_instance_valid(_bubble):
		_bubble.visible = false
