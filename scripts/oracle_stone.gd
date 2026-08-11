extends StaticBody3D
## Metin-style Oracle Stone — levitating, luminous crystal with HP.
## Hitting it grants a trickle of XP and wakes nearby guardians; shatter it
## for a larger reward. Tiers: 1 / 5 / 10 / 15.

const VfxHelper = preload("res://scripts/vfx_helper.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

const NAME_FONT := "res://assets/fonts/cinzel.ttf"

## Tier → look, durability, rewards, and which low-level packs it wakes.
const TIER_CFG := {
	1: {
		"name": "Ember Metin",
		"hp": 180, "xp_hit": 4, "xp_break": 90, "gold": [12, 24],
		"color": Color(1.0, 0.45, 0.15),
		"spawn": ["wolf_enemy", "wolf_black_enemy"],
		"spawn_max": 4,
	},
	5: {
		"name": "Verdant Metin",
		"hp": 420, "xp_hit": 8, "xp_break": 220, "gold": [28, 48],
		"color": Color(0.25, 0.95, 0.45),
		"spawn": ["boar_enemy", "wolf_dire_enemy"],
		"spawn_max": 5,
	},
	10: {
		"name": "Azure Metin",
		"hp": 780, "xp_hit": 14, "xp_break": 420, "gold": [50, 90],
		"color": Color(0.25, 0.55, 1.0),
		"spawn": ["satyr_enemy", "wolf_dire_enemy"],
		"spawn_max": 5,
	},
	15: {
		"name": "Void Metin",
		"hp": 1400, "xp_hit": 22, "xp_break": 900, "gold": [100, 180],
		"color": Color(0.75, 0.25, 1.0),
		"spawn": ["harpy_enemy", "satyr_enemy"],
		"spawn_max": 6,
	},
}

var stone_tier: int = 1
var hp: float = 180.0
var max_hp: float = 180.0
var dead: bool = false
var destroyed: bool = false
var cfg: Dictionary = {}

var _crystal: MeshInstance3D
var _aura: MeshInstance3D
var _light: OmniLight3D
var _glow_time: float = 0.0
var _spawned: int = 0
var _hit_spawn_cd: float = 0.0
var _base_y: float = 1.35

var plate: Node3D
var name_label: Label3D
var bar_bg: Sprite3D
var bar_fill: Sprite3D
static var _bar_tex: ImageTexture


static func create(at: Vector3, tier: int = 1) -> StaticBody3D:
	var s := StaticBody3D.new()
	s.set_script(load("res://scripts/oracle_stone.gd"))
	s.stone_tier = tier
	s.position = at
	return s


static func _get_bar_tex() -> ImageTexture:
	if _bar_tex == null:
		var img := Image.create_empty(32, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		_bar_tex = ImageTexture.create_from_image(img)
	return _bar_tex


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("oracle_stones")
	collision_layer = 4
	collision_mask = 0
	cfg = TIER_CFG.get(stone_tier, TIER_CFG[1])
	max_hp = float(cfg["hp"])
	hp = max_hp

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.95
	shape.shape = sphere
	shape.position.y = _base_y
	add_child(shape)

	_build_crystal()
	_build_plate()


func _build_crystal() -> void:
	var col: Color = cfg["color"]

	# Faceted crystal body (octahedron-ish via stretched sphere + emission).
	_crystal = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.55
	mesh.radial_segments = 6
	mesh.rings = 4
	_crystal.mesh = mesh
	_crystal.position.y = _base_y
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, 0.72)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.15
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.4
	mat.rim_enabled = true
	mat.rim = 0.55
	mat.rim_tint = 0.4
	_crystal.material_override = mat
	add_child(_crystal)

	# Soft ground aura disc.
	_aura = MeshInstance3D.new()
	var disc := TorusMesh.new()
	disc.inner_radius = 0.55
	disc.outer_radius = 1.15
	disc.rings = 12
	disc.ring_segments = 24
	_aura.mesh = disc
	_aura.position.y = 0.08
	var am := StandardMaterial3D.new()
	am.albedo_color = Color(col.r, col.g, col.b, 0.35)
	am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	am.emission_enabled = true
	am.emission = col
	am.emission_energy_multiplier = 1.2
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aura.material_override = am
	add_child(_aura)

	_light = OmniLight3D.new()
	_light.light_color = col
	_light.light_energy = 1.6
	_light.omni_range = 8.0
	_light.position.y = _base_y
	add_child(_light)


func _build_plate() -> void:
	plate = Node3D.new()
	plate.position.y = _base_y + 1.35
	add_child(plate)

	name_label = Label3D.new()
	name_label.text = "%s  Lv.%d" % [str(cfg["name"]), stone_tier]
	if ResourceLoader.exists(NAME_FONT):
		var f: Font = load(NAME_FONT)
		if f:
			name_label.font = f
	name_label.font_size = 56
	name_label.pixel_size = 0.0036
	name_label.outline_size = 12
	name_label.outline_modulate = Color(0, 0, 0, 0.85)
	name_label.modulate = cfg["color"]
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.render_priority = 2
	plate.add_child(name_label)

	bar_bg = Sprite3D.new()
	_setup_bar(bar_bg, Color(0.03, 0.02, 0.02, 0.8), 0)
	bar_bg.position.y = -0.18
	plate.add_child(bar_bg)

	bar_fill = Sprite3D.new()
	_setup_bar(bar_fill, Color(cfg["color"].r, cfg["color"].g, cfg["color"].b, 0.95), 1)
	bar_fill.position.y = -0.18
	plate.add_child(bar_fill)
	_set_bar_fraction(1.0)


func _setup_bar(s: Sprite3D, col: Color, prio: int) -> void:
	s.texture = _get_bar_tex()
	s.pixel_size = 1.2 / 32.0
	s.modulate = col
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.render_priority = prio
	s.centered = true


func _set_bar_fraction(frac: float) -> void:
	frac = clampf(frac, 0.0, 1.0)
	var w := int(round(32.0 * frac))
	if w <= 0:
		bar_fill.visible = false
		return
	bar_fill.visible = true
	bar_fill.region_enabled = true
	bar_fill.region_rect = Rect2(0, 0, w, 4)
	bar_fill.offset = Vector2(-(32 - w) * 0.5, 0)


func _process(delta: float) -> void:
	if dead:
		return
	_glow_time += delta
	_hit_spawn_cd = maxf(0.0, _hit_spawn_cd - delta)
	if _crystal:
		_crystal.rotation.y += delta * 0.55
		_crystal.position.y = _base_y + sin(_glow_time * 1.6) * 0.22
		var pulse := 1.8 + sin(_glow_time * 3.2) * 0.55
		var mat := _crystal.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = pulse
	if _light:
		_light.light_energy = 1.2 + sin(_glow_time * 2.4) * 0.5
		_light.position.y = _crystal.position.y if _crystal else _base_y
	if _aura:
		_aura.rotation.y -= delta * 0.35


func get_prompt() -> String:
	if dead:
		return ""
	return "Strike the %s" % str(cfg["name"])


func interact() -> void:
	# Stones are meant to be fought, not one-shot with E.
	pass


func take_damage(amount: float, _from_position: Vector3) -> void:
	if dead:
		return
	hp -= amount
	DamageNumbers.spawn(get_parent(), global_position + Vector3(0, _base_y + 0.8, 0), int(amount))
	_set_bar_fraction(hp / max_hp)
	# Trickle XP on every hit — Metin grind loop.
	GameState.add_xp(int(cfg["xp_hit"]))
	AudioManager.play_sfx("oracle_pulse", -10.0, randf_range(0.95, 1.1))
	VfxHelper.spawn_hit(global_position + Vector3(0, _base_y, 0), get_parent())
	_try_spawn_guardians()
	if hp <= 0.0:
		_shatter()


func _try_spawn_guardians() -> void:
	if _hit_spawn_cd > 0.0:
		return
	if _spawned >= int(cfg["spawn_max"]):
		return
	_hit_spawn_cd = 1.15
	var ids: Array = cfg["spawn"]
	var pick: String = String(ids[randi() % ids.size()])
	var world := get_tree().get_first_node_in_group("game_world")
	if world == null:
		return
	var ang := randf() * TAU
	var dist := randf_range(3.5, 6.5)
	var wx: float = global_position.x + cos(ang) * dist
	var wz: float = global_position.z + sin(ang) * dist
	var wy: float = global_position.y
	if world.has_method("sample_height"):
		wy = world.sample_height(wx, wz) + 0.5
	var e := EnemyScript.create(pick, Vector3(wx, wy, wz))
	world.add_child(e)
	_spawned += 1
	# Aggro immediately toward the player.
	if e.has_method("_find_player"):
		e.call_deferred("_find_player")


func _shatter() -> void:
	dead = true
	destroyed = true
	collision_layer = 0
	GameState.register_stone_destroyed()
	GameState.add_xp(int(cfg["xp_break"]))
	var gold_range: Array = cfg["gold"]
	GameState.add_gold(randi_range(int(gold_range[0]), int(gold_range[1])))
	AudioManager.play_sfx("oracle_pulse")
	AudioManager.play_sfx("oracle_whisper", -6.0)
	VfxHelper.spawn_explosion(global_position + Vector3(0, _base_y, 0), get_parent())
	if is_instance_valid(_crystal):
		_crystal.visible = false
	if is_instance_valid(_aura):
		_aura.visible = false
	if is_instance_valid(_light):
		_light.visible = false
	if is_instance_valid(plate):
		plate.visible = false
	var world := get_tree().get_first_node_in_group("game_world")
	if world and world.has_method("remove_interactable"):
		world.remove_interactable(self)
	var t := get_tree().create_timer(1.6)
	t.timeout.connect(queue_free)
