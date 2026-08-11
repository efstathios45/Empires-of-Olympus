extends Node3D
## GameWorld — the land of Hellas: terrain, sky, the hub sanctuary, hunting
## grounds, oracle stones, the Minotaur's arena, spawns and interactables.

const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")
const HTerrainTextureSet = preload("res://addons/zylann.hterrain/hterrain_texture_set.gd")
const GrassField = preload("res://assets/grass/grass_field.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PlayerScript = preload("res://scripts/player.gd")
const NpcScript = preload("res://scripts/npc.gd")
const OracleStoneScript = preload("res://scripts/oracle_stone.gd")
const ChestScript = preload("res://scripts/treasure_chest.gd")
const CityPlazaScript = preload("res://scripts/world/city_plaza.gd")

const TERRAIN_SIZE := 513
const MAP_SCALE := Vector3(1.0, 26.0, 1.0)
const TERRAIN_OFFSET := Vector3(-256.0, 0.0, -256.0)
const WALL_HALF := 150.0

const HUB_POS := Vector2(0.0, 0.0)
## The city pad. Fully flat inside HUB_RADIUS * 0.5, blending out to HUB_RADIUS —
## wide enough for the whole agora (temple, stoa, market row, gate, townhouses).
const HUB_RADIUS := 50.0
const HUB_H := 0.45
## Paved/bare radius of the plaza: drives the splatmap, the grass mask, footstep
## surface and the town music zone. One number, one source of truth.
const PLAZA_R := HUB_RADIUS * 0.55
const ARENA_POS := Vector2(0.0, 105.0)
const ARENA_RADIUS := 26.0
const ARENA_H := 0.42

# Flattened tree-grove pads (x, z, radius, height). Counts kept lean for web:
# each grove is MultiMesh + impostor LOD, but every tree still pays transforms.
const GROVES := [
	{"c": Vector2(118.0, -58.0), "r": 26.0, "h": 0.52, "count": 14, "seed": 11},
	{"c": Vector2(-118.0, -88.0), "r": 28.0, "h": 0.50, "count": 16, "seed": 23},
	{"c": Vector2(-52.0, -136.0), "r": 24.0, "h": 0.48, "count": 12, "seed": 37},
	{"c": Vector2(96.0, 96.0), "r": 24.0, "h": 0.50, "count": 12, "seed": 51},
]

# Live creature budget per zone. Every quest species stays represented; the
# 40 s respawn tops the hunting grounds back up as the player clears them.
const ZONES := [
	{"c": Vector2(0.0, -80.0), "r": 17.0,
		"ids": ["wolf_enemy", "wolf_enemy", "wolf_black_enemy",
				"wolf_dire_enemy", "boar_enemy", "boar_enemy"]},
	{"c": Vector2(80.0, -20.0), "r": 17.0,
		"ids": ["satyr_enemy", "satyr_enemy", "satyr_enemy",
				"harpy_enemy", "harpy_enemy"]},
	{"c": Vector2(-80.0, 20.0), "r": 17.0,
		"ids": ["centaur_enemy", "centaur_enemy",
				"gorgon_enemy", "gorgon_enemy"]},
]

const RESPAWN_DELAY := 40.0
const BOSS_MUSIC_RANGE := 34.0
## Inside this radius of the plaza the town theme + market crowd take over.
const CITY_AUDIO_RANGE := 44.0
## Titan Seeds: random crawl-from-earth spawns (chance checked on this interval).
const STONE_SPAWN_INTERVAL := 22.0
const STONE_SPAWN_CHANCE := 0.38
const STONE_MAX_ALIVE := 5
const STONE_TIERS := [1, 1, 5, 5, 10, 15]

var _terrain: HTerrain = null
var _splatmap: Image = null
var _grass: MultiMeshInstance3D = null
var _sun: DirectionalLight3D = null
var player: Node3D = null
var interactables: Array[Node3D] = []
var _music_timer: float = 0.0
var _boss_node: Node3D = null
var _stone_timer: float = 8.0

## Adapter the grass field samples: heights as Vector3, plus a grass mask.
class GrassTerrain extends RefCounted:
	var _world: Node3D
	func _init(w: Node3D) -> void:
		_world = w
	func sample_height(x: float, z: float) -> Vector3:
		return Vector3(x, _world.sample_height(x, z), z)
	func grass_weight(x: float, z: float) -> float:
		return _world.grass_weight(x, z)

func _ready() -> void:
	add_to_group("game_world")
	_setup_environment()
	_generate_terrain(20260807)
	_build_bounds()
	_build_hub()
	_build_wilds()
	_build_arena()
	_spawn_player()
	_spawn_zones()
	_build_grass()
	_build_forests()
	_build_hud()
	# The player wakes up in the city, so boot straight into the town theme; the
	# 0.6 s poll in _process takes over from here.
	AudioManager.play_music("city")
	AudioManager.play_ambient("city_crowd")

# ── Environment ──────────────────────────────────────────────────────────

func _setup_environment() -> void:
	var env := Environment.new()
	if ResourceLoader.exists("res://assets/textures/skyboxes/olympus_sky_sky.tres"):
		env.sky = load("res://assets/textures/skyboxes/olympus_sky_sky.tres")
		env.background_mode = Environment.BG_SKY
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.06
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.92, 0.82, 0.66)
	env.fog_sun_scatter = 0.35
	env.fog_density = 0.004
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	_sun.light_color = Color(1.0, 0.93, 0.78)
	_sun.light_energy = 1.2
	_sun.shadow_enabled = true
	# Web budget: one orthogonal shadow split that only covers the ground the
	# player can actually see close up (was 4 splits over 180 m).
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 80.0
	_sun.directional_shadow_fade_start = 0.85
	add_child(_sun)

# ── Terrain ──────────────────────────────────────────────────────────────

func _generate_terrain(seed_val: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed_val
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.004
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	var detail := FastNoiseLite.new()
	detail.seed = seed_val + 100
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail.frequency = 0.02
	detail.fractal_octaves = 4

	var data = HTerrainData.new()
	data.resize(TERRAIN_SIZE)
	var heightmap: Image = data.get_image(HTerrainData.CHANNEL_HEIGHT)
	var normalmap: Image = data.get_image(HTerrainData.CHANNEL_NORMAL)
	var splatmap: Image = data.get_image(HTerrainData.CHANNEL_SPLAT)

	var edge_margin := TERRAIN_SIZE * 0.06

	# Pass 1: heights (flattened pads for the hub, arena and groves).
	for z in TERRAIN_SIZE:
		for x in TERRAIN_SIZE:
			var raw: float = (noise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5
			var det: float = (detail.get_noise_2d(float(x), float(z)) + 1.0) * 0.5 * 0.10
			var h: float = clampf(raw * 0.62 + det, 0.0, 1.0)
			var wx: float = float(x) + TERRAIN_OFFSET.x
			var wz: float = float(z) + TERRAIN_OFFSET.z
			h = _flatten_toward(h, HUB_H, Vector2(wx, wz).distance_to(HUB_POS), HUB_RADIUS)
			h = _flatten_toward(h, ARENA_H, Vector2(wx, wz).distance_to(ARENA_POS), ARENA_RADIUS)
			for g in GROVES:
				h = _flatten_toward(h, g["h"], Vector2(wx, wz).distance_to(g["c"]), g["r"])
			var fx := clampf(minf(float(x), float(TERRAIN_SIZE - 1 - x)) / edge_margin, 0.0, 1.0)
			var fz := clampf(minf(float(z), float(TERRAIN_SIZE - 1 - z)) / edge_margin, 0.0, 1.0)
			h = lerpf(0.30, h, fx * fz)
			heightmap.set_pixel(x, z, Color(h, 0, 0, 1))

	# Pass 2: normals + splatmap (grass flats, rock slopes, dirt high/roads).
	var norm_step := 3
	for z in TERRAIN_SIZE:
		for x in TERRAIN_SIZE:
			var h_c: float = heightmap.get_pixel(x, z).r
			var h_r: float = heightmap.get_pixel(mini(x + norm_step, TERRAIN_SIZE - 1), z).r
			var h_d: float = heightmap.get_pixel(x, mini(z + norm_step, TERRAIN_SIZE - 1)).r
			var dx: float = (h_c - h_r) * MAP_SCALE.y
			var dz: float = (h_c - h_d) * MAP_SCALE.y
			var normal := Vector3(dx, float(norm_step), dz).normalized()
			normalmap.set_pixel(x, z, HTerrainData.encode_normal(normal))
			var slope: float = normal.y
			var rock_w: float = clampf(smoothstep(0.86, 0.68, slope), 0.0, 1.0)
			var dirt_w: float = clampf(smoothstep(0.68, 0.82, h_c) * (1.0 - rock_w), 0.0, 1.0)
			# Worn dirt in the hub plaza and arena pit.
			var wx2: float = float(x) + TERRAIN_OFFSET.x
			var wz2: float = float(z) + TERRAIN_OFFSET.z
			if Vector2(wx2, wz2).distance_to(HUB_POS) < PLAZA_R:
				dirt_w = maxf(dirt_w, 0.85 * (1.0 - rock_w))
			if Vector2(wx2, wz2).distance_to(ARENA_POS) < ARENA_RADIUS * 0.8:
				dirt_w = maxf(dirt_w, 0.9 * (1.0 - rock_w))
			var grass_w: float = maxf(1.0 - rock_w - dirt_w, 0.0)
			splatmap.set_pixel(x, z, Color(grass_w, rock_w, dirt_w, 0.0))

	var full_rect := Rect2(0, 0, TERRAIN_SIZE, TERRAIN_SIZE)
	data.notify_region_change(full_rect, HTerrainData.CHANNEL_HEIGHT)
	data.notify_region_change(full_rect, HTerrainData.CHANNEL_NORMAL)
	data.notify_region_change(full_rect, HTerrainData.CHANNEL_SPLAT)
	_splatmap = splatmap

	_terrain = HTerrain.new()
	_terrain.map_scale = MAP_SCALE
	_terrain.position = TERRAIN_OFFSET
	_terrain.set_shader_type(HTerrain.SHADER_CLASSIC4)
	_terrain.set_texture_set(_build_texture_set())
	_terrain.set_data(data)
	add_child(_terrain)
	var uv := 14.0
	_terrain.set_shader_param("u_ground_uv_scale_per_texture", Color(uv, uv, uv, uv))
	_terrain.set_shader_param("u_depth_blending", false)
	_terrain.set_shader_param("u_tile_reduction", Color(0, 0, 0, 0))

func _flatten_toward(h: float, target: float, dist: float, radius: float) -> float:
	return lerpf(target, h, smoothstep(radius * 0.5, radius, dist))

func _build_texture_set() -> HTerrainTextureSet:
	var ts := HTerrainTextureSet.new()
	ts.set_mode(HTerrainTextureSet.MODE_TEXTURES)
	ts.insert_slot(-1)
	ts.insert_slot(-1)
	ts.insert_slot(-1)
	_set_slot(ts, 0, "res://assets/textures/nature/mediterranean_ground.png", 0.9)
	_set_slot(ts, 1, "res://assets/textures/stone/terrain_rock.png", 0.95)
	_set_slot(ts, 2, "res://assets/textures/nature/terrain_dirt.png", 0.85)
	return ts

func _set_slot(ts: HTerrainTextureSet, slot: int, path: String, roughness: float) -> void:
	if ResourceLoader.exists(path):
		ts.set_texture(slot, HTerrainTextureSet.TYPE_ALBEDO_BUMP, load(path))
	ts.set_texture(slot, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, _flat_normal(64, roughness))

func _flat_normal(size: int, roughness: float) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 1.0, roughness))
	return ImageTexture.create_from_image(img)

## World-space ground height (player/projectile/NPC API).
func sample_height(world_x: float, world_z: float) -> float:
	if _terrain == null or not _terrain.has_data():
		return 10.0
	var cell_x := clampf((world_x - TERRAIN_OFFSET.x) / MAP_SCALE.x, 0.0, float(TERRAIN_SIZE - 2))
	var cell_z := clampf((world_z - TERRAIN_OFFSET.z) / MAP_SCALE.z, 0.0, float(TERRAIN_SIZE - 2))
	var raw_h: float = _terrain.get_data().get_interpolated_height_at(Vector3(cell_x, 0.0, cell_z))
	return raw_h * MAP_SCALE.y + TERRAIN_OFFSET.y

## Grass density mask from the splatmap (bare in plaza/arena).
func grass_weight(world_x: float, world_z: float) -> float:
	if Vector2(world_x, world_z).distance_to(HUB_POS) < PLAZA_R:
		return 0.12
	if Vector2(world_x, world_z).distance_to(ARENA_POS) < ARENA_RADIUS * 0.8:
		return 0.08
	if _splatmap == null:
		return 1.0
	var ix := clampi(int(world_x - TERRAIN_OFFSET.x), 0, TERRAIN_SIZE - 1)
	var iz := clampi(int(world_z - TERRAIN_OFFSET.z), 0, TERRAIN_SIZE - 1)
	return _splatmap.get_pixel(ix, iz).r

## Surface under a world point, for footsteps: "stone" | "dirt" | "grass".
## Cheap by design — two squared-distance tests and at most one splat read.
func ground_kind(x: float, z: float) -> String:
	var p := Vector2(x, z)
	if p.distance_squared_to(HUB_POS) < PLAZA_R * PLAZA_R:
		return "stone"
	var arena_r: float = ARENA_RADIUS * 0.9
	if p.distance_squared_to(ARENA_POS) < arena_r * arena_r:
		return "dirt"
	if _splatmap != null:
		var ix := clampi(int(x - TERRAIN_OFFSET.x), 0, TERRAIN_SIZE - 1)
		var iz := clampi(int(z - TERRAIN_OFFSET.z), 0, TERRAIN_SIZE - 1)
		var px := _splatmap.get_pixel(ix, iz)
		if px.b > 0.45 or px.g > 0.5:
			return "dirt"
	return "grass"

func get_respawn_point() -> Vector3:
	return Vector3(0.0, sample_height(0.0, 7.0) + 1.0, 7.0)

# ── Bounds ───────────────────────────────────────────────────────────────

func _build_bounds() -> void:
	var h := 40.0
	var t := 2.0
	var spans := [
		[Vector3(0, h * 0.5, -WALL_HALF), Vector3(WALL_HALF * 2 + 8, h, t)],
		[Vector3(0, h * 0.5, WALL_HALF), Vector3(WALL_HALF * 2 + 8, h, t)],
		[Vector3(-WALL_HALF, h * 0.5, 0), Vector3(t, h, WALL_HALF * 2 + 8)],
		[Vector3(WALL_HALF, h * 0.5, 0), Vector3(t, h, WALL_HALF * 2 + 8)],
	]
	for s in spans:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = s[1]
		shape.shape = box
		body.add_child(shape)
		body.position = s[0]
		add_child(body)

# ── Placement helpers ────────────────────────────────────────────────────

## Place a GLB on the terrain.
##
## Order matters and is fixed: instantiate → add_child → scale → position →
## rotate → ground → ONLY THEN collision, so any generated shape matches the
## final visual instead of the raw import.
##
## `tier`:
##   0 — NO automatic collider. For big walk-past architecture (temple, stoa,
##       gate) whose collider is hand-authored below, and for pure backdrop
##       (arena gate, distant ruins) which needs none at all. An automatic hull
##       around a building wraps its roof and interior too, which is what walled
##       players out of the city.
##   1 — one tight box on the combined mesh AABB. Right for boxy props and
##       solid blocks: crates, carts, stalls, altars, townhouses.
##   2 — per-part convex hulls. ONLY for irregular solid lumps (boulders).
func _place_glb(path: String, wx: float, wz: float, height_m: float, yaw_deg: float, tier: int = 1) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	# exists() only proves the file is there — a model whose import products are
	# missing still loads as null, and the world must survive that.
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_warning("game_world: could not load %s" % path)
		return null
	var obj: Node3D = scene.instantiate()
	add_child(obj)
	if height_m > 0.0:
		ModelUtils.scale_to_height(obj, height_m)
	var y := sample_height(wx, wz)
	obj.global_position = Vector3(wx, y, wz)
	obj.rotation.y = deg_to_rad(yaw_deg)
	# World-root parent is at y=0, so pass terrain height as the offset above parent.
	ModelUtils.ground_model(obj, y)
	if tier == 1:
		ModelUtils.add_collision(obj)
	elif tier == 2:
		ModelUtils.add_per_part_convex_collision(obj)
	return obj

# ── Hand-authored colliders ──────────────────────────────────────────────
# All three parent the body to the WORLD, never to the model: the models are
# uniformly rescaled by scale_to_height, and a scaled CollisionShape3D is not
# something Godot supports cleanly. `offset` is given in the model's own frame
# (its -Z is its front) and in METRES, so it reads straight off the layout.

## An upright cylinder hugging a column / statue / post / brazier base.
func _add_pillar_collider(at: Node3D, radius: float, height: float,
		offset: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := _new_static_body()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position.y = height * 0.5
	body.add_child(shape)
	add_child(body)
	body.rotation.y = at.rotation.y
	body.global_position = at.global_position + Basis(Vector3.UP, at.rotation.y) * offset
	return body

## A box hugging a building footprint. `size` is the FULL box size in metres.
func _add_box_collider(at: Node3D, size: Vector3,
		offset: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := _new_static_body()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.rotation.y = at.rotation.y
	body.global_position = at.global_position + Basis(Vector3.UP, at.rotation.y) * offset
	return body

## A sloped slab the player can walk up: temple steps, kerbs, terraces.
## `bottom` and `top` are world points ON the finished walking surface.
func _add_ramp_collider(bottom: Vector3, top: Vector3, width: float,
		thickness: float = 0.6) -> StaticBody3D:
	var flat := Vector3(top.x - bottom.x, 0.0, top.z - bottom.z)
	var run: float = flat.length()
	if run < 0.05:
		return null
	var rise: float = top.y - bottom.y
	var pitch: float = atan2(rise, run)
	var body := _new_static_body()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, thickness, sqrt(run * run + rise * rise))
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	# Dropping a tilted slab straight down by t / cos(pitch) offsets it by exactly
	# t along its own normal, so the top face lands on the bottom→top line.
	var mid: Vector3 = (bottom + top) * 0.5
	body.global_position = mid - Vector3.UP * (thickness * 0.5 / maxf(cos(pitch), 0.2))
	body.rotation = Vector3(pitch, atan2(-flat.x, -flat.z), 0.0)
	return body

func _new_static_body() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	return body

func add_interactable(n: Node3D) -> void:
	interactables.append(n)

func remove_interactable(n: Node3D) -> void:
	interactables.erase(n)

func get_nearest_interactable(pos: Vector3, max_dist: float = 3.4) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for n in interactables:
		if not is_instance_valid(n):
			continue
		var d: float = n.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = n
	return best

# ── The city ─────────────────────────────────────────────────────────────

## The whole agora — temple precinct, fountain court, market row, stoa, gate,
## smith's yard and townsfolk — is laid out in scripts/world/city_plaza.gd.
func _build_hub() -> void:
	CityPlazaScript.build(self)

# ── Hunting grounds, ruins, stones, chests ───────────────────────────────

func _build_wilds() -> void:
	# Backdrop ruins: silhouette only, deliberately NO collider. Hulling a broken
	# wall seals its gaps and reads to the player as an invisible wall.
	_place_glb("res://assets/environment/structures/broken_ruins.glb", 70.0, -32.0, 6.5, 40.0, 0)
	_place_glb("res://assets/environment/structures/broken_ruins.glb", 94.0, -6.0, 5.0, 160.0, 0)
	_place_glb("res://assets/environment/structures/broken_ruins.glb", -70.0, 34.0, 5.5, -60.0, 0)

	# Boulders on rocky slopes.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var placed := 0
	var attempts := 0
	while placed < 12 and attempts < 300:
		attempts += 1
		var wx := rng.randf_range(-WALL_HALF + 10.0, WALL_HALF - 10.0)
		var wz := rng.randf_range(-WALL_HALF + 10.0, WALL_HALF - 10.0)
		if Vector2(wx, wz).distance_to(HUB_POS) < HUB_RADIUS + 6.0:
			continue
		if _splatmap != null:
			var ix := clampi(int(wx - TERRAIN_OFFSET.x), 0, TERRAIN_SIZE - 1)
			var iz := clampi(int(wz - TERRAIN_OFFSET.z), 0, TERRAIN_SIZE - 1)
			if _splatmap.get_pixel(ix, iz).g < 0.35:
				continue
		_place_glb("res://assets/environment/rocks/cliff_rock.glb", wx, wz,
			rng.randf_range(1.8, 4.2), rng.randf() * 360.0, 2)
		placed += 1

	# Seed the wilds with a few Titan Seeds; more crawl up at random over time.
	for entry in [
		[Vector2(40.0, -70.0), 1],
		[Vector2(-70.0, -25.0), 5],
		[Vector2(35.0, 55.0), 10],
	]:
		_spawn_oracle_stone(entry[0] as Vector2, int(entry[1]))

	# Hidden treasure.
	for pos in [Vector2(30.0, -58.0), Vector2(-62.0, 10.0), Vector2(18.0, 88.0)]:
		var chest := ChestScript.create(Vector3(pos.x, sample_height(pos.x, pos.y), pos.y))
		add_child(chest)
		add_interactable(chest)

# ── The Minotaur's arena ─────────────────────────────────────────────────

func _build_arena() -> void:
	# The gate is a 12 m backdrop the player walks under — no collider at all.
	_place_glb("res://assets/environment/structures/arena_gate.glb", 0.0, 82.0, 12.0, 180.0, 0)
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.4
		var col := _place_glb("res://assets/environment/structures/marble_column.glb",
			ARENA_POS.x + cos(a) * 21.0, ARENA_POS.y + sin(a) * 21.0, 6.0, randf() * 360.0, 0)
		if col != null:
			_add_pillar_collider(col, 0.5, 6.0)

	var boss := EnemyScript.create("minotaur_boss",
		Vector3(ARENA_POS.x, sample_height(ARENA_POS.x, ARENA_POS.y), ARENA_POS.y))
	add_child(boss)
	_boss_node = boss
	boss.enemy_died.connect(_on_boss_died)

func _on_boss_died(_id: String, _pos: Vector3) -> void:
	# The fanfare plays out; _update_music picks the zone track back up the poll
	# after it finishes, so no timer is needed to restore it.
	AudioManager.play_music_once("victory")
	# The beast rises again after a while for glory-seekers.
	var t := get_tree().create_timer(120.0)
	t.timeout.connect(_respawn_boss)

func _respawn_boss() -> void:
	if is_instance_valid(_boss_node):
		return
	var boss := EnemyScript.create("minotaur_boss",
		Vector3(ARENA_POS.x, sample_height(ARENA_POS.x, ARENA_POS.y), ARENA_POS.y))
	add_child(boss)
	_boss_node = boss
	boss.enemy_died.connect(_on_boss_died)

# ── Player & enemies ─────────────────────────────────────────────────────

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	add_child(player)
	player.add_to_group("player")
	player.global_position = get_respawn_point()

func _spawn_zones() -> void:
	for zi in ZONES.size():
		var zone: Dictionary = ZONES[zi]
		for id in zone["ids"]:
			_spawn_enemy_in_zone(id, zi)

func _spawn_enemy_in_zone(enemy_id: String, zone_idx: int) -> void:
	var zone: Dictionary = ZONES[zone_idx]
	var c: Vector2 = zone["c"]
	var a := randf() * TAU
	var r := float(zone["r"]) * sqrt(randf())
	var wx: float = c.x + cos(a) * r
	var wz: float = c.y + sin(a) * r
	var e := EnemyScript.create(enemy_id, Vector3(wx, sample_height(wx, wz) + 0.5, wz))
	add_child(e)
	e.set_meta("zone_idx", zone_idx)
	e.enemy_died.connect(_on_zone_enemy_died)

func _on_zone_enemy_died(enemy_id: String, pos: Vector3) -> void:
	# Find which zone this enemy belonged to via nearest zone centre.
	var best := 0
	var best_d := 1e9
	for zi in ZONES.size():
		var c: Vector2 = ZONES[zi]["c"]
		var d := Vector2(pos.x, pos.z).distance_squared_to(c)
		if d < best_d:
			best_d = d
			best = zi
	var t := get_tree().create_timer(RESPAWN_DELAY)
	t.timeout.connect(_spawn_enemy_in_zone.bind(enemy_id, best))

# ── Grass & forests ──────────────────────────────────────────────────────

func _build_grass() -> void:
	_grass = GrassField.new()
	_grass.terrain = GrassTerrain.new(self)
	_grass.focus_node = player
	_grass.sun = _sun
	# Web budget. The bounded field is built ONCE, so its cost is (cells x
	# clusters_per_cell) blades held in MultiMesh tiles forever — lush grass over
	# the whole 300x300 m map was ~2.6 M billboards and minutes of build time.
	# Lush belt around the roads and hunting grounds, sparse scrub out to the
	# walls, and the "patchy" type both thins it and breaks it into natural
	# clumps instead of a uniform carpet.
	_grass.playable_half = 92.0
	_grass.outer_half = WALL_HALF
	_grass.clusters_per_cell = 140
	_grass.sparse_clusters = 22
	_grass.grass_type = "patchy"
	_grass.grass_color = Color(0.55, 0.58, 0.27)  # sun-dried Mediterranean gold-green
	add_child(_grass)
	var leaf_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/grass/textures/tesana-grass.png"):
		leaf_tex = load("res://assets/grass/textures/tesana-grass.png")
	_grass.build(leaf_tex, -_sun.global_transform.basis.z)
	# For the bounded field the tier only picks the 3D render scale; the density
	# knobs above are build-time (see grass_field.gd set_tier).
	_grass.set_tier("performance")

func _build_forests() -> void:
	if not ResourceLoader.exists("res://assets/trees/leaf_atlas.gdshader"):
		return
	var leaf_shader: Shader = load("res://assets/trees/leaf_atlas.gdshader")
	var atlas: Texture2D = load("res://assets/trees/foliage/savanna_dry.png")
	var leaf_mat := TreeForest.make_leaf_material(leaf_shader, atlas, {
		"tint_color": Vector3(0.98, 0.92, 0.62), "tint_strength": 0.22,
	})
	var bark_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/trees/bark/acacia_bark.png"):
		bark_tex = load("res://assets/trees/bark/acacia_bark.png")
	var bark_mat := TreeForest.make_bark_material(Color(0.45, 0.36, 0.28), bark_tex)

	var params := TreeFactory.DEFAULTS.duplicate()
	params.merge({
		"branch_mode": 0, "droop": 0.0, "length_falloff": 0.0,
		"cluster_flatten": 0.85, "cluster_along": 0.1,
		"trunk_height": 9.0, "trunk_radius": 0.24,
		"branch_start": 0.55, "upward_bias": 0.35, "leaf_card_size": 1.7,
	}, true)

	for g in GROVES:
		var forest := TreeForest.new()
		add_child(forest)
		var c: Vector2 = g["c"]
		var base_y: float = sample_height(c.x, c.y)
		forest.global_position = Vector3(c.x, base_y, c.y)
		# Per-tree terrain snap — stops trunks floating on slopes at grove edges.
		var height_fn := func(lx: float, lz: float) -> float:
			return sample_height(c.x + lx, c.y + lz) - base_y
		forest.setup(params, 2, leaf_mat, bark_mat, int(g["count"]), float(g["r"]), {
			"seed": int(g["seed"]), "scale_jitter": 0.3,
			"variant_jitter": {"trunk_height": 0.2, "leaf_card_size": 0.15},
			"lod_distance": 34.0, "lod_blend_band": 14.0,
			"cast_leaf_shadows": false,
			"height_sampler": height_fn,
		})
		forest.build()

	# A few hero trees with trunk colliders near the paths.
	for pos in [Vector2(20.0, -40.0), Vector2(-25.0, -52.0), Vector2(52.0, 8.0),
			Vector2(-45.0, 45.0), Vector2(15.0, 40.0), Vector2(-18.0, 68.0)]:
		var y := sample_height(pos.x, pos.y)
		var xform := Transform3D(Basis(Vector3.UP, randf() * TAU), Vector3(pos.x, y, pos.y))
		var tree := TreeForest.spawn_tree(self, params, 2, leaf_mat, bark_mat, xform)
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.32
		cyl.height = 5.0
		shape.shape = cyl
		shape.position.y = 2.5
		body.add_child(shape)
		tree.add_child(body)

# ── HUD ──────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	var hud_path := "res://scenes/ui/hud.tscn"
	if not ResourceLoader.exists(hud_path):
		return
	var hud: Node = load(hud_path).instantiate()
	add_child(hud)
	hud.add_to_group("hud")
	if hud.has_method("setup"):
		hud.setup(player, self)

# ── Per-frame ────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _grass != null and player != null and is_instance_valid(player):
		_grass.set_player_position(player.global_position)

	_music_timer -= delta
	if _music_timer <= 0.0:
		_music_timer = 0.6
		_update_music()

	_stone_timer -= delta
	if _stone_timer <= 0.0:
		_stone_timer = STONE_SPAWN_INTERVAL
		if randf() < STONE_SPAWN_CHANCE:
			_try_random_stone_spawn()


func _alive_oracle_stones() -> int:
	var n := 0
	for s in get_tree().get_nodes_in_group("oracle_stones"):
		if is_instance_valid(s) and not s.get("dead"):
			n += 1
	return n


func _spawn_oracle_stone(pos: Vector2, tier: int) -> void:
	var stone := OracleStoneScript.create(
		Vector3(pos.x, sample_height(pos.x, pos.y), pos.y), tier)
	add_child(stone)


func _try_random_stone_spawn() -> void:
	if _alive_oracle_stones() >= STONE_MAX_ALIVE:
		return
	# Prefer wilds away from the plaza and arena.
	for _i in 12:
		var wx := randf_range(-95.0, 95.0)
		var wz := randf_range(-95.0, 95.0)
		if Vector2(wx, wz).distance_to(HUB_POS) < HUB_RADIUS + 18.0:
			continue
		if Vector2(wx, wz).distance_to(ARENA_POS) < 28.0:
			continue
		var tier: int = int(STONE_TIERS[randi() % STONE_TIERS.size()])
		_spawn_oracle_stone(Vector2(wx, wz), tier)
		return


## Zone soundtrack, polled every 0.6 s from _process. Priority: the Minotaur
## first, then the city, then the open country. AudioManager.play_music /
## play_ambient both no-op when the same stream is already running, so crossing
## a boundary can never restart a track.
func _update_music() -> void:
	if player == null or not is_instance_valid(player):
		return
	var flat := Vector2(player.global_position.x, player.global_position.z)
	var boss_alive: bool = _boss_node != null and is_instance_valid(_boss_node) and not _boss_node.get("dead")
	var near_boss: bool = flat.distance_to(ARENA_POS) < BOSS_MUSIC_RANGE
	var music := "exploration"
	var ambient := "wind"
	if boss_alive and near_boss:
		music = "boss"
	elif flat.distance_to(HUB_POS) < CITY_AUDIO_RANGE:
		music = "city"
		ambient = "city_crowd"
	# A jingle (victory / defeat) leaves the player busy but current_music stale,
	# so "still playing" is what protects it; once it ends the zone track resumes.
	# This also re-arms the loop, since the imported tracks are single-shot.
	if AudioManager.current_music != music or not AudioManager.music_player.playing:
		AudioManager.play_music(music)
	AudioManager.play_ambient(ambient)
