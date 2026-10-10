extends Node3D



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
const CityWallsScript = preload("res://scripts/world/city_walls.gd")
const HellasMapData = preload("res://scripts/world/hellas_map_data.gd")

## Larger Hellas: ~768 m heightmap, playable ~±340 m.
const TERRAIN_SIZE: = 769
const MAP_SCALE: = Vector3(1.0, 26.0, 1.0)
const TERRAIN_OFFSET: = Vector3(-384.0, 0.0, -384.0)
const WALL_HALF: = 340.0

## Capitals — Athens keeps the mosaic quest; Sparta / Thebes are full sister cities.
const CITIES: = [
	{"id": "athens", "empire": "athens", "c": Vector2(0.0, 0.0), "theme": "athens", "mosaic": true},
	{"id": "sparta", "empire": "sparta", "c": Vector2(-240.0, 210.0), "theme": "sparta", "mosaic": false},
	{"id": "thebes", "empire": "corinth", "c": Vector2(240.0, -190.0), "theme": "thebes", "mosaic": false},
]

const HUB_POS: = Vector2(0.0, 0.0)
const HUB_RADIUS: = 50.0
const HUB_H: = 0.45
const CITY_WALL_R: = 38.0
const DEN_H: = 0.48

const PLAZA_R: = HUB_RADIUS * 0.55
const SANCTUARY_R: = PLAZA_R
const ARENA_POS: = Vector2(0.0, 280.0)
const ARENA_RADIUS: = 26.0
const ARENA_H: = 0.42

const GROVES: = [
	{"c": Vector2(118.0, -58.0), "r": 26.0, "h": 0.52, "count": 14, "seed": 11},
	{"c": Vector2(-118.0, -88.0), "r": 28.0, "h": 0.5, "count": 16, "seed": 23},
	{"c": Vector2(-52.0, -136.0), "r": 24.0, "h": 0.48, "count": 12, "seed": 37},
	{"c": Vector2(96.0, 96.0), "r": 24.0, "h": 0.5, "count": 12, "seed": 51},
	{"c": Vector2(-280.0, 140.0), "r": 26.0, "h": 0.5, "count": 14, "seed": 67},
	{"c": Vector2(-160.0, 280.0), "r": 24.0, "h": 0.48, "count": 12, "seed": 71},
	{"c": Vector2(280.0, -100.0), "r": 26.0, "h": 0.5, "count": 14, "seed": 83},
	{"c": Vector2(150.0, -280.0), "r": 24.0, "h": 0.48, "count": 12, "seed": 97},
	{"c": Vector2(0.0, -200.0), "r": 22.0, "h": 0.5, "count": 10, "seed": 101},
]

## Giant dens between hostile capitals — filled from HellasMapData at ready.
var ZONES: Array = []

const RESPAWN_DELAY: = 40.0
const BOSS_MUSIC_RANGE: = 34.0
const CITY_AUDIO_RANGE: = 48.0

const STONE_SPAWN_INTERVAL: = 18.0
const STONE_SPAWN_CHANCE: = 0.42
const STONE_MAX_ALIVE: = 10
const STONE_TIERS: = [1, 1, 5, 5, 10, 15]

var _terrain: HTerrain = null
var _splatmap: Image = null
var _grass: MultiMeshInstance3D = null
var _sun: DirectionalLight3D = null
var _world_env: WorldEnvironment = null
var player: Node3D = null
var interactables: Array[Node3D] = []
var _music_timer: float = 0.0
var _boss_node: Node3D = null
var _stone_timer: float = 8.0
var _autosave_timer: float = 45.0
var _fps_label: Label = null


class GrassTerrain extends RefCounted:
	var _world: Node3D
	func _init(w: Node3D) -> void :
		_world = w
	func sample_height(x: float, z: float) -> Vector3:
		return Vector3(x, _world.sample_height(x, z), z)
	func grass_weight(x: float, z: float) -> float:
		return _world.grass_weight(x, z)

func _ready() -> void :
	add_to_group("game_world")
	ZONES = HellasMapData.zones_for_spawns()
	_setup_environment()
	_generate_terrain(20260807)
	_build_bounds()
	_build_hub()
	_build_dens()
	_build_wilds()
	_build_arena()
	_spawn_player()
	## Guests skip local mob spawns — host pushes the shared instance roster.
	if NetSession == null or NetSession.should_spawn_world_mobs_locally():
		_spawn_zones()
	_build_grass()
	_build_forests()
	_build_hud()
	if DisplaySettings:
		if not DisplaySettings.settings_changed.is_connected(_on_display_settings_changed):
			DisplaySettings.settings_changed.connect(_on_display_settings_changed)
		apply_display_quality(DisplaySettings.quality_preset())
		_sync_fps_overlay()

	AudioManager.play_music("city")
	AudioManager.play_ambient("city_crowd")

	call_deferred("_try_pending_net_join")


func _try_pending_net_join() -> void :
	if NetSession == null:
		return
	var msg: = NetSession.try_pending_join()
	if msg != "" and ChatSystem:
		ChatSystem.call("_push_system", msg)



func _setup_environment() -> void :
	var env: = Environment.new()



	var sky_ok: = false
	if ResourceLoader.exists("res://assets/textures/skyboxes/olympus_sky_sky.tres"):
		var sky_res = load("res://assets/textures/skyboxes/olympus_sky_sky.tres")
		if sky_res is Sky:
			env.sky = sky_res
			sky_ok = true
	if not sky_ok:
		var proc: = ProceduralSkyMaterial.new()
		proc.sky_top_color = Color(0.45, 0.62, 0.88)
		proc.sky_horizon_color = Color(0.95, 0.82, 0.62)
		proc.ground_bottom_color = Color(0.35, 0.28, 0.18)
		proc.ground_horizon_color = Color(0.78, 0.62, 0.42)
		proc.sun_angle_max = 30.0
		var sky: = Sky.new()
		sky.sky_material = proc
		env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.06
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_bloom = 0.06
	env.fog_enabled = true
	env.fog_light_color = Color(0.92, 0.82, 0.66)
	env.fog_sun_scatter = 0.28
	## Larger Hellas — keep atmosphere but let distant capitals read.
	env.fog_density = 0.0022
	_world_env = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	_sun.light_color = Color(1.0, 0.93, 0.78)
	_sun.light_energy = 1.2
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_max_distance = 90.0
	_sun.directional_shadow_fade_start = 0.85
	add_child(_sun)


func apply_display_quality(preset: Dictionary) -> void:
	if _sun != null:
		_sun.directional_shadow_max_distance = float(preset.get("shadow_dist", 90.0))
	if _world_env != null and _world_env.environment != null:
		_world_env.environment.glow_enabled = bool(preset.get("glow", true))
	if _grass != null:
		_grass.playable_half = float(preset.get("grass_half", 96.0))
		_grass.clusters_per_cell = int(preset.get("grass_clusters", 80))
		_grass.outer_half = mini(WALL_HALF, _grass.playable_half * 2.4)
		_grass.set_tier(String(preset.get("grass", "balanced")))
	_sync_fps_overlay()


func _on_display_settings_changed() -> void:
	if DisplaySettings:
		apply_display_quality(DisplaySettings.quality_preset())


func _sync_fps_overlay() -> void:
	var show: = DisplaySettings != null and DisplaySettings.show_fps
	if show and _fps_label == null:
		_fps_label = Label.new()
		_fps_label.name = "FpsOverlay"
		_fps_label.add_theme_font_size_override("font_size", 18)
		_fps_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.7))
		_fps_label.position = Vector2(16, 120)
		_fps_label.z_index = 80
		add_child(_fps_label)
	if _fps_label != null:
		_fps_label.visible = show



func _generate_terrain(seed_val: int) -> void :
	var noise: = FastNoiseLite.new()
	noise.seed = seed_val
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.004
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	var detail: = FastNoiseLite.new()
	detail.seed = seed_val + 100
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail.frequency = 0.02
	detail.fractal_octaves = 4

	var data = HTerrainData.new()
	data.resize(TERRAIN_SIZE)
	var heightmap: Image = data.get_image(HTerrainData.CHANNEL_HEIGHT)
	var normalmap: Image = data.get_image(HTerrainData.CHANNEL_NORMAL)
	var splatmap: Image = data.get_image(HTerrainData.CHANNEL_SPLAT)

	var edge_margin: = TERRAIN_SIZE * 0.06


	for z in TERRAIN_SIZE:
		for x in TERRAIN_SIZE:
			var raw: float = (noise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5
			var det: float = (detail.get_noise_2d(float(x), float(z)) + 1.0) * 0.5 * 0.1
			var h: float = clampf(raw * 0.62 + det, 0.0, 1.0)
			var wx: float = float(x) + TERRAIN_OFFSET.x
			var wz: float = float(z) + TERRAIN_OFFSET.z
			for city in CITIES:
				h = _flatten_toward(h, HUB_H, Vector2(wx, wz).distance_to(city["c"]), HUB_RADIUS)
			h = _flatten_toward(h, ARENA_H, Vector2(wx, wz).distance_to(ARENA_POS), ARENA_RADIUS)
			for den in HellasMapData.DENS:
				h = _flatten_toward(h, DEN_H, Vector2(wx, wz).distance_to(den["pos"]), float(den["r"]) + 6.0)
			for g in GROVES:
				h = _flatten_toward(h, g["h"], Vector2(wx, wz).distance_to(g["c"]), g["r"])
			var fx: = clampf(minf(float(x), float(TERRAIN_SIZE - 1 - x)) / edge_margin, 0.0, 1.0)
			var fz: = clampf(minf(float(z), float(TERRAIN_SIZE - 1 - z)) / edge_margin, 0.0, 1.0)
			h = lerpf(0.3, h, fx * fz)
			heightmap.set_pixel(x, z, Color(h, 0, 0, 1))


	var norm_step: = 3
	for z in TERRAIN_SIZE:
		for x in TERRAIN_SIZE:
			var h_c: float = heightmap.get_pixel(x, z).r
			var h_r: float = heightmap.get_pixel(mini(x + norm_step, TERRAIN_SIZE - 1), z).r
			var h_d: float = heightmap.get_pixel(x, mini(z + norm_step, TERRAIN_SIZE - 1)).r
			var dx: float = (h_c - h_r) * MAP_SCALE.y
			var dz: float = (h_c - h_d) * MAP_SCALE.y
			var normal: = Vector3(dx, float(norm_step), dz).normalized()
			normalmap.set_pixel(x, z, HTerrainData.encode_normal(normal))
			var slope: float = normal.y
			var rock_w: float = clampf(smoothstep(0.86, 0.68, slope), 0.0, 1.0)
			var dirt_w: float = clampf(smoothstep(0.68, 0.82, h_c) * (1.0 - rock_w), 0.0, 1.0)

			var wx2: float = float(x) + TERRAIN_OFFSET.x
			var wz2: float = float(z) + TERRAIN_OFFSET.z
			for city in CITIES:
				if Vector2(wx2, wz2).distance_to(city["c"]) < PLAZA_R:
					dirt_w = maxf(dirt_w, 0.85 * (1.0 - rock_w))
					break
			if Vector2(wx2, wz2).distance_to(ARENA_POS) < ARENA_RADIUS * 0.8:
				dirt_w = maxf(dirt_w, 0.9 * (1.0 - rock_w))
			for den in HellasMapData.DENS:
				var dd: float = Vector2(wx2, wz2).distance_to(den["pos"])
				var dr: float = float(den["r"])
				if dd < dr:
					dirt_w = maxf(dirt_w, 0.88 * (1.0 - rock_w) * (1.0 - dd / dr))
			var grass_w: float = maxf(1.0 - rock_w - dirt_w, 0.0)
			splatmap.set_pixel(x, z, Color(grass_w, rock_w, dirt_w, 0.0))

	var full_rect: = Rect2(0, 0, TERRAIN_SIZE, TERRAIN_SIZE)
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
	var uv: = 14.0
	_terrain.set_shader_param("u_ground_uv_scale_per_texture", Color(uv, uv, uv, uv))
	_terrain.set_shader_param("u_depth_blending", false)
	_terrain.set_shader_param("u_tile_reduction", Color(0, 0, 0, 0))

func _flatten_toward(h: float, target: float, dist: float, radius: float) -> float:
	return lerpf(target, h, smoothstep(radius * 0.5, radius, dist))

func _build_texture_set() -> HTerrainTextureSet:
	var ts: = HTerrainTextureSet.new()
	ts.set_mode(HTerrainTextureSet.MODE_TEXTURES)
	ts.insert_slot(-1)
	ts.insert_slot(-1)
	ts.insert_slot(-1)
	_set_slot(ts, 0, "res://assets/textures/nature/mediterranean_ground.png", 0.9)
	_set_slot(ts, 1, "res://assets/textures/stone/terrain_rock.png", 0.95)
	_set_slot(ts, 2, "res://assets/textures/nature/terrain_dirt.png", 0.85)
	return ts

func _set_slot(ts: HTerrainTextureSet, slot: int, path: String, roughness: float) -> void :
	if ResourceLoader.exists(path):
		ts.set_texture(slot, HTerrainTextureSet.TYPE_ALBEDO_BUMP, load(path))
	ts.set_texture(slot, HTerrainTextureSet.TYPE_NORMAL_ROUGHNESS, _flat_normal(64, roughness))

func _flat_normal(size: int, roughness: float) -> ImageTexture:
	var img: = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 1.0, roughness))
	return ImageTexture.create_from_image(img)


func sample_height(world_x: float, world_z: float) -> float:
	if _terrain == null or not _terrain.has_data():
		return 10.0
	var cell_x: = clampf((world_x - TERRAIN_OFFSET.x) / MAP_SCALE.x, 0.0, float(TERRAIN_SIZE - 2))
	var cell_z: = clampf((world_z - TERRAIN_OFFSET.z) / MAP_SCALE.z, 0.0, float(TERRAIN_SIZE - 2))
	var raw_h: float = _terrain.get_data().get_interpolated_height_at(Vector3(cell_x, 0.0, cell_z))
	return raw_h * MAP_SCALE.y + TERRAIN_OFFSET.y


func grass_weight(world_x: float, world_z: float) -> float:
	var p: = Vector2(world_x, world_z)
	for city in CITIES:
		if p.distance_to(city["c"]) < PLAZA_R:
			return 0.12
	if p.distance_to(ARENA_POS) < ARENA_RADIUS * 0.8:
		return 0.08
	for den in HellasMapData.DENS:
		if p.distance_to(den["pos"]) < float(den["r"]) * 0.85:
			return 0.1
	if _splatmap == null:
		return 1.0
	var ix: = clampi(int(world_x - TERRAIN_OFFSET.x), 0, TERRAIN_SIZE - 1)
	var iz: = clampi(int(world_z - TERRAIN_OFFSET.z), 0, TERRAIN_SIZE - 1)
	return _splatmap.get_pixel(ix, iz).r


func ground_kind(x: float, z: float) -> String:
	var p: = Vector2(x, z)
	for city in CITIES:
		if p.distance_squared_to(city["c"]) < PLAZA_R * PLAZA_R:
			return "stone"
	var arena_r: float = ARENA_RADIUS * 0.9
	if p.distance_squared_to(ARENA_POS) < arena_r * arena_r:
		return "dirt"
	for den in HellasMapData.DENS:
		var dr: float = float(den["r"]) * 0.9
		if p.distance_squared_to(den["pos"]) < dr * dr:
			return "dirt"
	if _splatmap != null:
		var ix: = clampi(int(x - TERRAIN_OFFSET.x), 0, TERRAIN_SIZE - 1)
		var iz: = clampi(int(z - TERRAIN_OFFSET.z), 0, TERRAIN_SIZE - 1)
		var px: = _splatmap.get_pixel(ix, iz)
		if px.b > 0.45 or px.g > 0.5:
			return "dirt"
	return "grass"


func city_for_empire(empire_id: String = "") -> Dictionary:
	var emp: = empire_id if empire_id != "" else String(GameState.empire)
	## Corinth starts in Thebes; unknown → Athens.
	for city in CITIES:
		if String(city.get("empire", "")) == emp:
			return city
	return CITIES[0]


func nearest_city(pos: Vector2) -> Dictionary:
	var best: Dictionary = CITIES[0]
	var best_d: = INF
	for city in CITIES:
		var d: = pos.distance_squared_to(city["c"])
		if d < best_d:
			best_d = d
			best = city
	return best


func get_respawn_point() -> Vector3:
	var city: = city_for_empire()
	var c: Vector2 = city["c"]
	var x: = c.x
	var z: = c.y + 7.0
	return Vector3(x, sample_height(x, z) + 1.0, z)


func is_sanctuary(pos: Vector3) -> bool:
	var p: = Vector2(pos.x, pos.z)
	for city in CITIES:
		if p.distance_squared_to(city["c"]) < SANCTUARY_R * SANCTUARY_R:
			return true
	return false



func would_enter_sanctuary(from: Vector3, to: Vector3) -> bool:
	if is_sanctuary(to):
		return true

	var mid: = (from + to) * 0.5
	return is_sanctuary(mid)



func _build_bounds() -> void :
	var h: = 40.0
	var t: = 2.0
	var spans: = [
		[Vector3(0, h * 0.5, - WALL_HALF), Vector3(WALL_HALF * 2 + 8, h, t)], 
		[Vector3(0, h * 0.5, WALL_HALF), Vector3(WALL_HALF * 2 + 8, h, t)], 
		[Vector3( - WALL_HALF, h * 0.5, 0), Vector3(t, h, WALL_HALF * 2 + 8)], 
		[Vector3(WALL_HALF, h * 0.5, 0), Vector3(t, h, WALL_HALF * 2 + 8)], 
	]
	for s in spans:
		var body: = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: = CollisionShape3D.new()
		var box: = BoxShape3D.new()
		box.size = s[1]
		shape.shape = box
		body.add_child(shape)
		body.position = s[0]
		add_child(body)


















func _place_glb(path: String, wx: float, wz: float, height_m: float, yaw_deg: float, tier: int = 1) -> Node3D:
	if not ResourceLoader.exists(path):
		return null


	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_warning("game_world: could not load %s" % path)
		return null
	var obj: Node3D = scene.instantiate()
	add_child(obj)
	if height_m > 0.0:
		ModelUtils.scale_to_height(obj, height_m)
	var y: = sample_height(wx, wz)
	obj.global_position = Vector3(wx, y, wz)
	obj.rotation.y = deg_to_rad(yaw_deg)

	ModelUtils.ground_model(obj, y)
	if tier == 1:
		ModelUtils.add_collision(obj)
	elif tier == 2:
		ModelUtils.add_per_part_convex_collision(obj)
	return obj








func _add_pillar_collider(at: Node3D, radius: float, height: float, 
		offset: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body: = _new_static_body()
	var shape: = CollisionShape3D.new()
	var cyl: = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position.y = height * 0.5
	body.add_child(shape)
	add_child(body)
	body.rotation.y = at.rotation.y
	body.global_position = at.global_position + Basis(Vector3.UP, at.rotation.y) * offset
	return body


func _add_box_collider(at: Node3D, size: Vector3, 
		offset: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body: = _new_static_body()
	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.rotation.y = at.rotation.y
	body.global_position = at.global_position + Basis(Vector3.UP, at.rotation.y) * offset
	return body



func _add_ramp_collider(bottom: Vector3, top: Vector3, width: float, 
		thickness: float = 0.6) -> StaticBody3D:
	var flat: = Vector3(top.x - bottom.x, 0.0, top.z - bottom.z)
	var run: float = flat.length()
	if run < 0.05:
		return null
	var rise: float = top.y - bottom.y
	var pitch: float = atan2(rise, run)
	var body: = _new_static_body()
	var shape: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = Vector3(width, thickness, sqrt(run * run + rise * rise))
	shape.shape = box
	body.add_child(shape)
	add_child(body)


	var mid: Vector3 = (bottom + top) * 0.5
	body.global_position = mid - Vector3.UP * (thickness * 0.5 / maxf(cos(pitch), 0.2))
	body.rotation = Vector3(pitch, atan2( - flat.x, - flat.z), 0.0)
	return body

func _new_static_body() -> StaticBody3D:
	var body: = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	return body

func add_interactable(n: Node3D) -> void :
	interactables.append(n)

func remove_interactable(n: Node3D) -> void :
	interactables.erase(n)

func get_nearest_interactable(pos: Vector3, max_dist: float = 3.4) -> Node3D:
	var best: Node3D = null
	var best_d: = max_dist
	for n in interactables:
		if not is_instance_valid(n):
			continue
		var d: float = n.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = n
	return best





func _build_hub() -> void :
	for city in CITIES:
		var c: Vector2 = city["c"]
		CityPlazaScript.build(self, c, {
			"id": String(city["id"]),
			"theme": String(city["theme"]),
			"mosaic": bool(city.get("mosaic", false)),
		})
		CityWallsScript.build(self, c, CITY_WALL_R, String(city["theme"]))
	if not GameState.mosaic_changed.is_connected(apply_player_mosaic):
		GameState.mosaic_changed.connect(apply_player_mosaic)
	apply_player_mosaic()


## Giant beast dens between the three hostile capitals — rock rings + ruin camps.
func _build_dens() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.seed = 404
	for den in HellasMapData.DENS:
		var c: Vector2 = den["pos"]
		var r: float = float(den["r"])
		## Central ruin camp — dens read as giant bases, not loose packs.
		_place_glb("res://assets/environment/structures/broken_ruins.glb",
			c.x, c.y, 9.0, rng.randf() * 360.0, 0)
		_place_glb("res://assets/environment/structures/broken_ruins.glb",
			c.x + rng.randf_range(-4.0, 4.0), c.y + rng.randf_range(-4.0, 4.0),
			6.5, rng.randf() * 360.0, 0)
		## Outer rock ring so dens read as fortresses from the roads.
		var ring_n: = 10 + int(r / 8.0)
		for i in ring_n:
			var a: float = TAU * float(i) / float(ring_n) + rng.randf_range(-0.12, 0.12)
			var rr: float = r * rng.randf_range(0.82, 1.05)
			_place_glb("res://assets/environment/rocks/cliff_rock.glb",
				c.x + cos(a) * rr, c.y + sin(a) * rr,
				rng.randf_range(3.2, 5.8), rng.randf() * 360.0, 2)
		## Inner scatter — dens feel packed.
		for _j in 5:
			var a2: float = rng.randf() * TAU
			var rr2: float = r * rng.randf_range(0.25, 0.55)
			_place_glb("res://assets/environment/rocks/cliff_rock.glb",
				c.x + cos(a2) * rr2, c.y + sin(a2) * rr2,
				rng.randf_range(1.6, 3.2), rng.randf() * 360.0, 2)
		## Broken columns mark the dens on the horizon.
		for k in 3:
			var a3: float = TAU * float(k) / 3.0 + 0.35
			var col: = _place_glb("res://assets/environment/structures/marble_column.glb",
				c.x + cos(a3) * (r * 0.45), c.y + sin(a3) * (r * 0.45),
				rng.randf_range(4.5, 6.5), rng.randf() * 360.0, 0)
			if col != null:
				_add_pillar_collider(col, 0.45, 5.5)


## Apply the logged-in player's sealed/draft Psifidoto to the Athens agora disc.
func apply_player_mosaic() -> void :
	var disc: MeshInstance3D = null
	for n in get_tree().get_nodes_in_group("plaza_mosaic_disc"):
		if n is MeshInstance3D:
			## Prefer Athens; fall back to first disc.
			if String(n.get_meta("city_id", "")) == "athens" or disc == null:
				disc = n as MeshInstance3D
			if String(n.get_meta("city_id", "")) == "athens":
				break
	if disc == null:
		return
	var mat: = disc.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		disc.material_override = mat
	var tex: Texture2D = GameState.mosaic_floor_texture()
	if tex != null:
		mat.albedo_texture = tex
		mat.albedo_color = Color(1, 1, 1, 1)
		mat.uv1_scale = Vector3.ONE
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	else:
		# Restore pebble underlay when the player has no art yet.
		const MOSAIC_TEX: = "res://assets/textures/stone/greek_pebble_mosaic.png"
		mat.albedo_color = Color(0.82, 0.74, 0.62)
		if ResourceLoader.exists(MOSAIC_TEX):
			mat.albedo_texture = load(MOSAIC_TEX)
		mat.uv1_scale = Vector3.ONE
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 0.92
	mat.metallic = 0.0


func _build_wilds() -> void :
	## Ruins along the roads between capitals.
	for entry in [
		[70.0, -32.0, 6.5, 40.0],
		[94.0, -6.0, 5.0, 160.0],
		[-70.0, 34.0, 5.5, -60.0],
		[-150.0, 130.0, 6.0, 25.0],
		[-200.0, 180.0, 5.5, -40.0],
		[150.0, -120.0, 6.0, 110.0],
		[210.0, -160.0, 5.5, 200.0],
		[40.0, 220.0, 5.0, 15.0],
		[-40.0, -180.0, 5.5, 90.0],
	]:
		_place_glb("res://assets/environment/structures/broken_ruins.glb",
			float(entry[0]), float(entry[1]), float(entry[2]), float(entry[3]), 0)

	var rng: = RandomNumberGenerator.new()
	rng.seed = 99
	var placed: = 0
	var attempts: = 0
	while placed < 36 and attempts < 800:
		attempts += 1
		var wx: = rng.randf_range(-WALL_HALF + 10.0, WALL_HALF - 10.0)
		var wz: = rng.randf_range(-WALL_HALF + 10.0, WALL_HALF - 10.0)
		var near_city: = false
		for city in CITIES:
			if Vector2(wx, wz).distance_to(city["c"]) < HUB_RADIUS + 8.0:
				near_city = true
				break
		if near_city:
			continue
		var near_den: = false
		for den in HellasMapData.DENS:
			if Vector2(wx, wz).distance_to(den["pos"]) < float(den["r"]) + 6.0:
				near_den = true
				break
		if near_den:
			continue
		if _splatmap != null:
			var ix: = clampi(int(wx - TERRAIN_OFFSET.x), 0, TERRAIN_SIZE - 1)
			var iz: = clampi(int(wz - TERRAIN_OFFSET.z), 0, TERRAIN_SIZE - 1)
			if _splatmap.get_pixel(ix, iz).g < 0.35:
				continue
		_place_glb("res://assets/environment/rocks/cliff_rock.glb", wx, wz,
			rng.randf_range(1.8, 4.2), rng.randf() * 360.0, 2)
		placed += 1

	for entry in [
		[Vector2(40.0, -70.0), 1],
		[Vector2(-70.0, -25.0), 5],
		[Vector2(35.0, 55.0), 10],
		[Vector2(-200.0, 240.0), 5],
		[Vector2(-280.0, 180.0), 10],
		[Vector2(200.0, -220.0), 5],
		[Vector2(280.0, -150.0), 15],
		[Vector2(0.0, 230.0), 10],
	]:
		_spawn_oracle_stone(entry[0] as Vector2, int(entry[1]))

	for pos in [
		Vector2(30.0, -58.0), Vector2(-62.0, 10.0), Vector2(18.0, 88.0),
		Vector2(-220.0, 250.0), Vector2(-260.0, 190.0),
		Vector2(220.0, -230.0), Vector2(260.0, -170.0),
		Vector2(10.0, 240.0),
	]:
		var chest: = ChestScript.create(Vector3(pos.x, sample_height(pos.x, pos.y), pos.y))
		add_child(chest)
		add_interactable(chest)


func _build_arena() -> void :
	## Approach gate north of the pit (toward Athens).
	_place_glb("res://assets/environment/structures/arena_gate.glb",
		ARENA_POS.x, ARENA_POS.y - 23.0, 12.0, 180.0, 0)
	for i in 5:
		var a: = TAU * float(i) / 5.0 + 0.4
		var col: = _place_glb("res://assets/environment/structures/marble_column.glb", 
			ARENA_POS.x + cos(a) * 21.0, ARENA_POS.y + sin(a) * 21.0, 6.0, randf() * 360.0, 0)
		if col != null:
			_add_pillar_collider(col, 0.5, 6.0)

	## Guests receive the boss as a host proxy — one shared instance.
	if NetSession and not NetSession.should_spawn_world_mobs_locally():
		return
	var boss: = EnemyScript.create("minotaur_boss", 
		Vector3(ARENA_POS.x, sample_height(ARENA_POS.x, ARENA_POS.y), ARENA_POS.y))
	add_child(boss)
	_boss_node = boss
	boss.enemy_died.connect(_on_boss_died)
	if NetSession and NetSession.is_hosting():
		NetSession.host_register_enemy(boss)

func _on_boss_died(_id: String, _pos: Vector3) -> void :


	AudioManager.play_music_once("victory")

	## Only the host schedules the shared boss respawn.
	if NetSession and NetSession.is_online() and not NetSession.is_hosting():
		return
	var t: = get_tree().create_timer(120.0)
	t.timeout.connect(_respawn_boss)

func _respawn_boss() -> void :
	if is_instance_valid(_boss_node):
		return
	if NetSession and not NetSession.should_spawn_world_mobs_locally():
		return
	var boss: = EnemyScript.create("minotaur_boss", 
		Vector3(ARENA_POS.x, sample_height(ARENA_POS.x, ARENA_POS.y), ARENA_POS.y))
	add_child(boss)
	_boss_node = boss
	boss.enemy_died.connect(_on_boss_died)
	if NetSession and NetSession.is_hosting():
		NetSession.host_register_enemy(boss)



func _spawn_player() -> void :
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	add_child(player)
	player.add_to_group("player")
	player.global_position = get_respawn_point()

	var save: = AccountSystem.read_local_save()
	if typeof(save.get("pos", null)) == TYPE_DICTIONARY:
		var p: Dictionary = save["pos"]
		var x: = float(p.get("x", player.global_position.x))
		var z: = float(p.get("z", player.global_position.z))
		player.global_position = Vector3(x, sample_height(x, z) + 1.0, z)

func _spawn_zones() -> void :
	for zi in ZONES.size():
		var zone: Dictionary = ZONES[zi]
		for id in zone["ids"]:
			_spawn_enemy_in_zone(id, zi)

func _spawn_enemy_in_zone(enemy_id: String, zone_idx: int) -> void :
	if NetSession and not NetSession.should_spawn_world_mobs_locally():
		return
	var zone: Dictionary = ZONES[zone_idx]
	var c: Vector2 = zone["c"]
	var a: = randf() * TAU
	var r: = float(zone["r"]) * sqrt(randf())
	var wx: float = c.x + cos(a) * r
	var wz: float = c.y + sin(a) * r
	var e: = EnemyScript.create(enemy_id, Vector3(wx, sample_height(wx, wz) + 0.5, wz))
	add_child(e)
	e.set_meta("zone_idx", zone_idx)
	e.enemy_died.connect(_on_zone_enemy_died)
	if NetSession and NetSession.is_hosting():
		NetSession.host_register_enemy(e)

func _on_zone_enemy_died(enemy_id: String, pos: Vector3) -> void :
	## Only the host (or offline) respawns into the shared world.
	if NetSession and NetSession.is_online() and not NetSession.is_hosting():
		return
	var best: = 0
	var best_d: = 1000000000.0
	for zi in ZONES.size():
		var c: Vector2 = ZONES[zi]["c"]
		var d: = Vector2(pos.x, pos.z).distance_squared_to(c)
		if d < best_d:
			best_d = d
			best = zi
	var t: = get_tree().create_timer(RESPAWN_DELAY)
	t.timeout.connect(_spawn_enemy_in_zone.bind(enemy_id, best))



func _build_grass() -> void :
	_grass = GrassField.new()
	_grass.terrain = GrassTerrain.new(self)
	_grass.focus_node = player
	_grass.sun = _sun
	var preset: Dictionary = DisplaySettings.quality_preset() if DisplaySettings else {}
	_grass.playable_half = float(preset.get("grass_half", 96.0))
	_grass.outer_half = mini(WALL_HALF, _grass.playable_half * 2.4)
	_grass.clusters_per_cell = int(preset.get("grass_clusters", 80))
	_grass.sparse_clusters = 14
	_grass.grass_type = "patchy"
	_grass.grass_color = Color(0.55, 0.58, 0.27)
	add_child(_grass)
	var leaf_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/grass/textures/tesana-grass.png"):
		leaf_tex = load("res://assets/grass/textures/tesana-grass.png")
	_grass.build(leaf_tex, - _sun.global_transform.basis.z)
	_grass.set_tier(String(preset.get("grass", "balanced")))

func _build_forests() -> void :
	if not ResourceLoader.exists("res://assets/trees/leaf_atlas.gdshader"):
		return
	var leaf_shader: Shader = load("res://assets/trees/leaf_atlas.gdshader")
	var atlas: Texture2D = load("res://assets/trees/foliage/savanna_dry.png")
	var leaf_mat: = TreeForest.make_leaf_material(leaf_shader, atlas, {
		"tint_color": Vector3(0.98, 0.92, 0.62), "tint_strength": 0.22, 
	})
	var bark_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/trees/bark/acacia_bark.png"):
		bark_tex = load("res://assets/trees/bark/acacia_bark.png")
	var bark_mat: = TreeForest.make_bark_material(Color(0.45, 0.36, 0.28), bark_tex)

	var params: = TreeFactory.DEFAULTS.duplicate()
	params.merge({
		"branch_mode": 0, "droop": 0.0, "length_falloff": 0.0, 
		"cluster_flatten": 0.85, "cluster_along": 0.1, 
		"trunk_height": 9.0, "trunk_radius": 0.24, 
		"branch_start": 0.55, "upward_bias": 0.35, "leaf_card_size": 1.7, 
	}, true)

	for g in GROVES:
		var forest: = TreeForest.new()
		add_child(forest)
		var c: Vector2 = g["c"]
		var base_y: float = sample_height(c.x, c.y)
		forest.global_position = Vector3(c.x, base_y, c.y)

		var height_fn: = func(lx: float, lz: float) -> float:
			return sample_height(c.x + lx, c.y + lz) - base_y
		forest.setup(params, 2, leaf_mat, bark_mat, int(g["count"]), float(g["r"]), {
			"seed": int(g["seed"]), "scale_jitter": 0.3, 
			"variant_jitter": {"trunk_height": 0.2, "leaf_card_size": 0.15}, 
			"lod_distance": 34.0, "lod_blend_band": 14.0, 
			"cast_leaf_shadows": false, 
			"height_sampler": height_fn, 
		})
		forest.build()


	for pos in [
		Vector2(20.0, -40.0), Vector2(-25.0, -52.0), Vector2(52.0, 8.0),
		Vector2(-45.0, 45.0), Vector2(15.0, 40.0), Vector2(-18.0, 68.0),
		Vector2(-200.0, 180.0), Vector2(-260.0, 240.0), Vector2(-170.0, 230.0),
		Vector2(200.0, -150.0), Vector2(260.0, -220.0), Vector2(170.0, -210.0),
		Vector2(30.0, 200.0), Vector2(-40.0, -150.0),
	]:
		var y: = sample_height(pos.x, pos.y)
		var xform: = Transform3D(Basis(Vector3.UP, randf() * TAU), Vector3(pos.x, y, pos.y))
		var tree: = TreeForest.spawn_tree(self, params, 2, leaf_mat, bark_mat, xform)
		var body: = StaticBody3D.new()
		body.collision_layer = 1
		var shape: = CollisionShape3D.new()
		var cyl: = CylinderShape3D.new()
		cyl.radius = 0.32
		cyl.height = 5.0
		shape.shape = cyl
		shape.position.y = 2.5
		body.add_child(shape)
		tree.add_child(body)



func _build_hud() -> void :
	var hud_path: = "res://scenes/ui/hud.tscn"
	if not ResourceLoader.exists(hud_path):
		return
	var hud: Node = load(hud_path).instantiate()
	add_child(hud)
	hud.add_to_group("hud")
	if hud.has_method("setup"):
		hud.setup(player, self)



func _process(delta: float) -> void :
	if _grass != null and player != null and is_instance_valid(player):
		_grass.set_player_position(player.global_position)

	if _fps_label != null and _fps_label.visible:
		_fps_label.text = "%d FPS · %s · max %s" % [
			Engine.get_frames_per_second(),
			DisplaySettings.quality_label() if DisplaySettings else "?",
			DisplaySettings.max_fps_label() if DisplaySettings else "?",
		]

	_music_timer -= delta
	if _music_timer <= 0.0:
		_music_timer = 0.6
		_update_music()

	_stone_timer -= delta
	if _stone_timer <= 0.0:
		_stone_timer = STONE_SPAWN_INTERVAL
		if randf() < STONE_SPAWN_CHANCE:
			_try_random_stone_spawn()

	if AccountSystem.is_logged_in():
		_autosave_timer -= delta
		if _autosave_timer <= 0.0:
			_autosave_timer = 45.0
			_autosave()


func _autosave() -> void :
	if not AccountSystem.is_logged_in():
		return
	var extra: = {}
	if player != null and is_instance_valid(player):
		extra["pos"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z,
		}
	## Host pushes shared world; guests still save personal + last host snapshot locally.
	if NetSession.is_hosting():
		GameState.ensure_world_host_identity()
		NetSession.broadcast_world_save()
	AccountSystem.save_game(extra)


func _alive_oracle_stones() -> int:
	var n: = 0
	for s in get_tree().get_nodes_in_group("oracle_stones"):
		if is_instance_valid(s) and not s.get("dead"):
			n += 1
	return n


func _spawn_oracle_stone(pos: Vector2, tier: int) -> void :
	if NetSession and not NetSession.should_spawn_world_mobs_locally():
		return
	var stone: = OracleStoneScript.create(
		Vector3(pos.x, sample_height(pos.x, pos.y), pos.y), tier)
	add_child(stone)
	if NetSession and NetSession.is_hosting():
		NetSession.host_register_stone(stone)


func _try_random_stone_spawn() -> void :
	if NetSession and not NetSession.should_spawn_world_mobs_locally():
		return
	if _alive_oracle_stones() >= STONE_MAX_ALIVE:
		return

	for _i in 16:
		var wx: = randf_range(-WALL_HALF + 20.0, WALL_HALF - 20.0)
		var wz: = randf_range(-WALL_HALF + 20.0, WALL_HALF - 20.0)
		var blocked: = false
		for city in CITIES:
			if Vector2(wx, wz).distance_to(city["c"]) < HUB_RADIUS + 18.0:
				blocked = true
				break
		if blocked:
			continue
		if Vector2(wx, wz).distance_to(ARENA_POS) < 28.0:
			continue
		var tier: int = int(STONE_TIERS[randi() % STONE_TIERS.size()])
		_spawn_oracle_stone(Vector2(wx, wz), tier)
		return






func _update_music() -> void :
	if player == null or not is_instance_valid(player):
		return
	var flat: = Vector2(player.global_position.x, player.global_position.z)
	var boss_alive: bool = _boss_node != null and is_instance_valid(_boss_node) and not _boss_node.get("dead")
	var near_boss: bool = flat.distance_to(ARENA_POS) < BOSS_MUSIC_RANGE
	var music: = "exploration"
	var ambient: = "wind"
	if boss_alive and near_boss:
		music = "boss"
	else:
		var city: = nearest_city(flat)
		if flat.distance_to(city["c"]) < CITY_AUDIO_RANGE:
			music = "city"
			ambient = "city_crowd"



	if AudioManager.current_music != music or not AudioManager.music_player.playing:
		AudioManager.play_music(music)
	AudioManager.play_ambient(ambient)
