extends StaticBody3D
## NPC — a friendly face in the city. Shows a prompt; E speaks with them.
##
## Two flavours of NPC share this script:
##   • SERVICE npcs ("priestess", "smith") — created with create(); E opens the
##     matching HUD panel.
##   • TOWNSFOLK — created with create_flavour(); E shows one short spoken line
##     above their head (and mirrors it to the HUD if the HUD offers a
##     notification method). No AI, no pathfinding — pure decoration.

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

const TURN_INTERVAL := 0.12   # NPC turning/anim polls at ~8 Hz, not per frame
const NOTICE_RANGE := 4.5
const TALK_RANGE := 3.2
const BUBBLE_SECONDS := 4.5
## The game's display face — used for the speech bubble so townsfolk chatter
## matches the rest of the UI instead of the raw engine default font.
const SPEECH_FONT := "res://assets/fonts/cinzel.ttf"

var _model: Node3D
var _anim: AnimationPlayer
var _player: Node3D
var _turn_accum: float = 0.0
var _bubble: Label3D = null

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
		if ResourceLoader.exists(lib_path):
			var lib := load(lib_path) as AnimationLibrary
			if lib:
				_anim.add_animation_library("", lib)
		ModelUtils.set_animation_loops(_anim)
		if not _anim.has_animation(idle_clip):
			idle_clip = "ual1_Idle"
		if _anim.has_animation(idle_clip):
			_anim.play(idle_clip)

	# Ground on the terrain.
	var world := get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("sample_height"):
		global_position.y = world.sample_height(global_position.x, global_position.z)

func _process(delta: float) -> void:
	# Face the player when they come close; talk-idle while engaged. Polled at
	# ~8 Hz so a crowded plaza costs almost nothing per frame.
	_turn_accum += delta
	if _turn_accum < TURN_INTERVAL:
		return
	var step: float = _turn_accum
	_turn_accum = 0.0
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	if _model == null:
		return
	var d: float = global_position.distance_to(_player.global_position)
	if d < NOTICE_RANGE:
		var dir: Vector3 = _player.global_position - global_position
		dir.y = 0
		if dir.length_squared() > 0.01:
			_model.rotation.y = lerp_angle(_model.rotation.y,
				ModelUtils.yaw_from_direction(dir.normalized()), minf(1.0, step * 6.0))
		if _anim and d < TALK_RANGE and _anim.has_animation("ual1_Idle_Talking"):
			if _anim.current_animation != "ual1_Idle_Talking":
				_anim.play("ual1_Idle_Talking")
	else:
		_model.rotation.y = lerp_angle(_model.rotation.y, spawn_yaw, minf(1.0, step * 2.5))
		if _anim and _anim.has_animation(idle_clip) and _anim.current_animation != idle_clip:
			_anim.play(idle_clip)

func get_prompt() -> String:
	return "Speak with %s" % display_name

func interact() -> void:
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

# ── Flavour chatter ──────────────────────────────────────────────────────

## Show a one-off remark above this NPC's head. Just the floating bubble — the
## line used to be mirrored to the HUD too, which read as a doubled message.
func _say(line: String) -> void:
	if _bubble == null or not is_instance_valid(_bubble):
		_bubble = Label3D.new()
		if ResourceLoader.exists(SPEECH_FONT):
			var f: Font = load(SPEECH_FONT)
			if f:
				_bubble.font = f
		_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble.shaded = false
		_bubble.double_sided = true
		_bubble.no_depth_test = false
		_bubble.pixel_size = 0.0038
		_bubble.font_size = 96
		_bubble.outline_size = 26
		_bubble.outline_modulate = Color(0.05, 0.04, 0.03, 0.95)
		_bubble.modulate = Color(1.0, 0.98, 0.92)
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
