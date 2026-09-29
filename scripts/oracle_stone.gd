extends StaticBody3D




const VfxHelper = preload("res://scripts/vfx_helper.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

const NAME_FONT: = "res://assets/fonts/cinzel.ttf"

const TIER_CFG: = {
	1: {
		"name": "Titan Seed", 
		"hp": 180, "xp_hit": 4, "xp_break": 90, "gold": [12, 24], 
		"color": Color(0.85, 0.55, 0.18), 
		"spawn": ["wolf_enemy", "wolf_black_enemy"], 
		"spawn_max": 4, 
	}, 
	5: {
		"name": "Gaia's Wound", 
		"hp": 420, "xp_hit": 8, "xp_break": 220, "gold": [28, 48], 
		"color": Color(0.35, 0.7, 0.28), 
		"spawn": ["boar_enemy", "wolf_dire_enemy"], 
		"spawn_max": 5, 
	}, 
	10: {
		"name": "Cronus Spire", 
		"hp": 780, "xp_hit": 14, "xp_break": 420, "gold": [50, 90], 
		"color": Color(0.35, 0.55, 0.85), 
		"spawn": ["satyr_enemy", "wolf_dire_enemy"], 
		"spawn_max": 5, 
	}, 
	15: {
		"name": "Omphalos of Tartarus", 
		"hp": 1400, "xp_hit": 22, "xp_break": 900, "gold": [100, 180], 
		"color": Color(0.55, 0.2, 0.55), 
		"spawn": ["harpy_enemy", "satyr_enemy"], 
		"spawn_max": 6, 
	}, 
}

var stone_tier: int = 1
var hp: float = 180.0
var max_hp: float = 180.0
var dead: bool = false
var destroyed: bool = false
var emerging: bool = true
var cfg: Dictionary = {}

var _body: Node3D
var _glow: MeshInstance3D
var _light: OmniLight3D
var _glow_time: float = 0.0
var _spawned: int = 0
var _hit_spawn_cd: float = 0.0
var _rest_y: float = 0.0
var _emerge_from: float = -2.4

var plate: Node3D
var name_label: Label3D
var bar_bg: Sprite3D
var bar_fill: Sprite3D
static var _bar_tex: ImageTexture


static func create(at: Vector3, tier: int = 1) -> StaticBody3D:
	var s: = StaticBody3D.new()
	s.set_script(load("res://scripts/oracle_stone.gd"))
	s.stone_tier = tier
	s.position = at
	return s


static func _get_bar_tex() -> ImageTexture:
	if _bar_tex == null:
		var img: = Image.create_empty(32, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		_bar_tex = ImageTexture.create_from_image(img)
	return _bar_tex


func _ready() -> void :
	add_to_group("enemies")
	add_to_group("oracle_stones")
	collision_layer = 4
	collision_mask = 0
	cfg = TIER_CFG.get(stone_tier, TIER_CFG[1])
	max_hp = float(cfg["hp"])
	hp = max_hp

	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = Vector3(1.8, 2.2, 1.8)
	shape.shape = box
	shape.position.y = 1.0
	add_child(shape)

	_build_body()
	_build_plate()
	_start_crawl_emergence()


func _build_body() -> void :
	var col: Color = cfg["color"]
	_body = Node3D.new()
	_body.name = "StoneBody"
	add_child(_body)


	const ROCK_A: = "res://assets/props/stones/nature_rock_large_a.glb"
	const ROCK_C: = "res://assets/props/stones/nature_rock_large_c.glb"
	const ROCK_E: = "res://assets/props/stones/nature_rock_large_e.glb"
	const ROCK_S: = "res://assets/props/stones/nature_rock_small_b.glb"
	const CLIFF: = "res://assets/props/stones/nature_cliff_rock.glb"
	_add_prop(ROCK_A, Vector3(0.0, 0.45, 0.0), 1.9, Color(0.38, 0.34, 0.3))
	_add_prop(ROCK_C, Vector3(0.4, 0.95, -0.25), 1.25, Color(0.42, 0.36, 0.3))
	_add_prop(ROCK_E, Vector3(-0.35, 0.85, 0.2), 1.15, Color(0.34, 0.32, 0.28))
	_add_prop(ROCK_S, Vector3(0.15, 1.35, 0.1), 0.7, col.lerp(Color(0.45, 0.4, 0.35), 0.5))
	_add_prop(CLIFF, Vector3(0.0, 0.15, 0.35), 1.4, Color(0.32, 0.3, 0.28))


	_glow = MeshInstance3D.new()
	var core: = BoxMesh.new()
	core.size = Vector3(0.22, 1.1, 0.22)
	_glow.mesh = core
	_glow.position = Vector3(0.0, 1.25, 0.0)
	_glow.rotation_degrees = Vector3(8, 25, 12)
	var gm: = StandardMaterial3D.new()
	gm.albedo_color = Color(col.r, col.g, col.b, 0.65)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.emission_enabled = true
	gm.emission = col
	gm.emission_energy_multiplier = 2.2
	gm.roughness = 0.25
	_glow.material_override = gm
	_body.add_child(_glow)

	_light = OmniLight3D.new()
	_light.light_color = col
	_light.light_energy = 0.75
	_light.omni_range = 5.5
	_light.position = Vector3(0.0, 1.4, 0.0)
	_body.add_child(_light)


func _add_prop(path: String, at: Vector3, height: float, tint: Color) -> void :
	if not ResourceLoader.exists(path):
		return
	var n: Node3D = load(path).instantiate()
	_body.add_child(n)
	n.position = at
	n.rotation.y = randf() * TAU
	ModelUtils.scale_to_height(n, height)
	var rock_tex: Texture2D = null
	const ROCK_DIFF: = "res://assets/textures/stone/dark_rock_diff.jpg"
	if ResourceLoader.exists(ROCK_DIFF):
		rock_tex = load(ROCK_DIFF)
	for child in n.find_children("*", "MeshInstance3D"):
		var mi: = child as MeshInstance3D
		if mi == null:
			continue
		var mat: = StandardMaterial3D.new()
		mat.albedo_color = tint
		if rock_tex:
			mat.albedo_texture = rock_tex
		mat.roughness = 0.95
		mat.metallic = 0.02
		mi.material_override = mat


func _start_crawl_emergence() -> void :

	emerging = true
	_rest_y = 0.0
	_body.position.y = _emerge_from
	plate.visible = false
	AudioManager.play_sfx("stone_rise", -6.0, randf_range(0.9, 1.05))
	var tw: = create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "position:y", _rest_y, 1.85)

	tw.parallel().tween_method(_rumble_offset, 0.0, 1.0, 1.85)
	tw.tween_callback(_on_emerged)


func _rumble_offset(t: float) -> void :
	if _body == null:
		return
	var shake: = (1.0 - t) * 0.08
	_body.position.x = sin(t * 28.0) * shake
	_body.position.z = cos(t * 22.0) * shake


func _on_emerged() -> void :
	emerging = false
	if _body:
		_body.position.x = 0.0
		_body.position.z = 0.0
		_body.position.y = _rest_y
	if plate:
		plate.visible = true
	AudioManager.play_sfx("oracle_whisper", -10.0)


func _build_plate() -> void :
	plate = Node3D.new()
	plate.position.y = 2.55
	add_child(plate)

	name_label = Label3D.new()
	name_label.text = "%s  Lv.%d" % [str(cfg["name"]), stone_tier]
	if ResourceLoader.exists(NAME_FONT):
		var f: Font = load(NAME_FONT)
		if f:
			name_label.font = f
	name_label.font_size = 58
	name_label.pixel_size = 0.0036
	name_label.outline_size = 12
	name_label.outline_modulate = Color(0, 0, 0, 0.9)
	name_label.modulate = cfg["color"]
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.render_priority = 2
	plate.add_child(name_label)

	bar_bg = Sprite3D.new()
	_setup_bar(bar_bg, Color(0.03, 0.02, 0.02, 0.85), 0)
	bar_bg.position.y = -0.2
	plate.add_child(bar_bg)

	bar_fill = Sprite3D.new()
	var c: Color = cfg["color"]
	_setup_bar(bar_fill, Color(c.r, c.g, c.b, 0.95), 1)
	bar_fill.position.y = -0.2
	plate.add_child(bar_fill)
	_set_bar_fraction(1.0)


func _setup_bar(s: Sprite3D, col: Color, prio: int) -> void :
	s.texture = _get_bar_tex()
	s.pixel_size = 1.25 / 32.0
	s.modulate = col
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.render_priority = prio
	s.centered = true


func _set_bar_fraction(frac: float) -> void :
	frac = clampf(frac, 0.0, 1.0)
	var w: = int(round(32.0 * frac))
	if w <= 0:
		bar_fill.visible = false
		return
	bar_fill.visible = true
	bar_fill.region_enabled = true
	bar_fill.region_rect = Rect2(0, 0, w, 4)
	bar_fill.offset = Vector2( - (32 - w) * 0.5, 0)


func _process(delta: float) -> void :
	if dead:
		return
	_glow_time += delta
	_hit_spawn_cd = maxf(0.0, _hit_spawn_cd - delta)
	if emerging:
		return
	if _glow:
		_glow.rotation.y += delta * 0.35
		var mat: = _glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.8 + sin(_glow_time * 2.6) * 0.7
	if _light:
		_light.light_energy = 0.55 + sin(_glow_time * 2.0) * 0.3


func get_prompt() -> String:
	return ""


func interact() -> void :
	pass


func take_damage(amount: float, from_position: Vector3) -> void :
	if dead or emerging:
		return
	hp -= amount
	DamageNumbers.spawn(get_parent(), global_position + Vector3(0, 2.2, 0), int(amount))
	_set_bar_fraction(hp / max_hp)
	PartyShare.note_nearby(self, from_position, 6.0)
	PartyShare.note_nearby(self, global_position, 12.0)

	PartyShare.award_xp_and_gold(self, int(cfg["xp_hit"]), 0)
	AudioManager.play_sfx("oracle_pulse", -12.0, randf_range(0.95, 1.1))
	VfxHelper.spawn_hit(global_position + Vector3(0, 1.3, 0), get_parent())
	_try_spawn_guardians()
	if hp <= 0.0:
		_shatter()


func _try_spawn_guardians() -> void :
	if _hit_spawn_cd > 0.0:
		return
	if _spawned >= int(cfg["spawn_max"]):
		return
	_hit_spawn_cd = 1.15
	var ids: Array = cfg["spawn"]
	var pick: String = String(ids[randi() % ids.size()])
	var world: = get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var ang: = randf() * TAU
	var dist: = randf_range(3.5, 6.5)
	var wx: float = global_position.x + cos(ang) * dist
	var wz: float = global_position.z + sin(ang) * dist
	var wy: float = global_position.y
	if world.has_method("sample_height"):
		wy = world.sample_height(wx, wz) + 0.5
	var e: = EnemyScript.create(pick, Vector3(wx, wy, wz))
	world.add_child(e)
	_spawned += 1


func _shatter() -> void :
	dead = true
	destroyed = true
	collision_layer = 0
	GameState.register_stone_destroyed()
	PartyShare.note_nearby(self, global_position, 16.0)
	var gold_range: Array = cfg["gold"]
	var gold_amt: int = randi_range(int(gold_range[0]), int(gold_range[1]))
	PartyShare.award_xp_and_gold(self, int(cfg["xp_break"]), gold_amt)
	AudioManager.play_sfx("stone_shatter", -2.0)
	AudioManager.play_sfx("oracle_pulse", -4.0)
	VfxHelper.spawn_explosion(global_position + Vector3(0, 1.2, 0), get_parent())
	if is_instance_valid(_body):
		_body.visible = false
	if is_instance_valid(plate):
		plate.visible = false
	var t: = get_tree().create_timer(1.4)
	t.timeout.connect(queue_free)
