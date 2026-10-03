extends MultiMeshInstance3D





















const SHADER_PATH: = "res://assets/grass/shaders/grass.gdshader"
const DEFAULT_LEAF: = "res://assets/grass/textures/tesana-grass.png"

const CELL_SIZE: = 3.5
const BLADE_WIDTH: = 0.75
const BLADE_HEIGHT: = 1.0
const SCALE_MIN: = 0.7
const SCALE_MAX: = 1.25



enum {MODE_NORMAL, MODE_BIG, MODE_XBIG, MODE_MAP, MODE_RIM}
const MODE_CORE: = {MODE_NORMAL: 12, MODE_BIG: 13, MODE_XBIG: 15, MODE_MAP: 11, MODE_RIM: 12}
const MODE_RADIUS: = {MODE_NORMAL: 12, MODE_BIG: 18, MODE_XBIG: 28, MODE_MAP: 45, MODE_RIM: 28}
const RIM_OUTER_DENSITY: = 20

const SLOT_POOL: = 720000
const FILL_CELLS_PER_FRAME: = 3
const REDENSIFY_PER_FRAME: = 2
const REDENSIFY_THRESHOLD: = 80


const TIERS: = {
	"performance": {"mode": MODE_NORMAL, "render_scale": 0.7}, 
	"balanced": {"mode": MODE_RIM, "render_scale": 0.7}, 
	"quality": {"mode": MODE_MAP, "render_scale": 0.85}, 
}

var terrain
var focus_node: Node3D
var grass_mode: = MODE_RIM
var clusters_per_cell: = 460





var grass_color: Color = Color(0.42, 0.66, 0.24)


const BLADE_DIR: = "res://assets/grass/blades/"
var blade: = "blade_full"
var shade: = "realistic"
var grass_type: = "uniform"


const SHADES: = {
	"realistic": {"cuts": 4.0, "soft": 0.65, "cloud": 0.22, "darken": 0.5}, 
	"stylized": {"cuts": 3.0, "soft": 0.3, "cloud": 0.4, "darken": 0.42}, 
	"cel": {"cuts": 2.0, "soft": 0.0, "cloud": 0.5, "darken": 0.38}, 
	"soft": {"cuts": 5.0, "soft": 0.85, "cloud": 0.18, "darken": 0.52}, 
}


const GRASS_TYPES: = {
	"uniform": {"density": 1.0, "patch": 0.0, "wmul": 1.0, "h_lo": 0.85, "h_hi": 1.2}, 
	"patchy": {"density": 1.15, "patch": 0.42, "wmul": 1.0, "h_lo": 0.85, "h_hi": 1.25}, 
	"sparse": {"density": 0.4, "patch": 0.0, "wmul": 1.05, "h_lo": 0.9, "h_hi": 1.3}, 
	"lawn": {"density": 1.3, "patch": 0.0, "wmul": 0.9, "h_lo": 0.6, "h_hi": 0.8}, 
	"wild": {"density": 0.95, "patch": 0.18, "wmul": 1.05, "h_lo": 1.0, "h_hi": 1.6}, 
}
var _type_noise: = FastNoiseLite.new()



var bounded: = true
var playable_half: = 92.0
var outer_half: = 0.0
var sparse_clusters: = 50
const TILE_SIZE: = 20.0
const TILE_VIEW_DIST: = 150.0
const OUTER_HALF_CAP: = 200.0
var _shared_mesh: ArrayMesh = null
var _tiles: Array[MultiMeshInstance3D] = []
var _active_outer: = 0.0





var sun: DirectionalLight3D = null
var environment: Environment = null
var _sun_ref_energy: = 0.0
var _ambient_ref: = 0.0

var _mat: ShaderMaterial
var _mm: MultiMesh
var _live: = {}
var _free: = PackedInt32Array()
var _free_top: = 0
var _frontier: = 0
var _live_blades: = 0
var _prev_focus_cell: = Vector2i(2147483647, 2147483647)
var _redensify_dirty: = true
var _fill_pending: = true


func build(leaf_tex: Texture2D = null, sun_travel_dir: = Vector3(0.5, -0.72, 0.45)) -> void :
	_type_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_type_noise.frequency = 0.08
	_type_noise.seed = 717
	if leaf_tex == null:
		var bp: = BLADE_DIR + blade + ".png"
		leaf_tex = load(bp) if ResourceLoader.exists(bp) else load(DEFAULT_LEAF)
	_mat = _build_material(leaf_tex, leaf_tex, sun_travel_dir)
	_shared_mesh = _make_blade_mesh()
	position = Vector3.ZERO
	_apply_method()



func _apply_method() -> void :
	_teardown()
	if bounded:

		_mat.set_shader_parameter("view_fade_start", TILE_VIEW_DIST - 30.0)
		_mat.set_shader_parameter("view_fade_end", TILE_VIEW_DIST - 8.0)
		_build_static_grid()
	else:
		material_override = _mat
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		custom_aabb = AABB(Vector3(-3000, -300, -3000), Vector3(6000, 600, 6000))
		_alloc_field()
		set_grass_mode(grass_mode)



func _teardown() -> void :
	for t in _tiles:
		if is_instance_valid(t):
			t.queue_free()
	_tiles.clear()
	multimesh = null
	material_override = null
	_mm = null
	_live.clear()
	_live_blades = 0
	_free_top = 0
	_frontier = 0
	_fill_pending = true
	_prev_focus_cell = Vector2i(2147483647, 2147483647)



func set_tier(tier: String) -> void :
	var t: Dictionary = TIERS.get(tier, TIERS["balanced"])
	var vp: = get_viewport()
	if vp != null:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = float(t["render_scale"])
	if not bounded:
		set_grass_mode(int(t["mode"]))




func set_player_position(p: Vector3) -> void :
	if _mat != null:
		_mat.set_shader_parameter("player_position", p)


func _process(_dt: float) -> void :
	if _mat != null:
		_sync_sun_lighting()

	if not bounded and _mm != null:
		_update_cells()







func _sync_sun_lighting() -> void :
	if _mat == null or sun == null:
		return
	_mat.set_shader_parameter("sun_dir", - sun.global_transform.basis.z)
	if _sun_ref_energy <= 0.0:
		_sun_ref_energy = maxf(sun.light_energy, 0.01)
	var sun_scale: float = clampf(sun.light_energy / _sun_ref_energy, 0.0, 1.5)
	_mat.set_shader_parameter("sun_color", sun.light_color * sun_scale)
	if environment != null:
		if _ambient_ref <= 0.0:
			_ambient_ref = maxf(environment.ambient_light_energy, 0.01)
		var amb_scale: float = clampf(environment.ambient_light_energy / _ambient_ref, 0.0, 1.5)
		_mat.set_shader_parameter("ambient_color", Color(0.42, 0.48, 0.52) * amb_scale)




func _make_blade_mesh() -> ArrayMesh:
	var hw: = BLADE_WIDTH * 0.5
	var verts: = PackedVector3Array([
		Vector3( - hw, 0.0, 0.0), Vector3(hw, 0.0, 0.0), 
		Vector3(hw, BLADE_HEIGHT, 0.0), Vector3( - hw, BLADE_HEIGHT, 0.0), 
	])
	var uvs: = PackedVector2Array([
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), 
	])
	var normals: = PackedVector3Array([
		Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), 
	])
	var indices: = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var arr: = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh: = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _make_noise(freq: float, seed_val: int, simplex: = true) -> NoiseTexture2D:
	var noise: = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX if simplex else FastNoiseLite.TYPE_PERLIN
	noise.seed = seed_val
	noise.frequency = freq
	noise.fractal_octaves = 3
	var tex: = NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	return tex


func _make_cloud_noise() -> NoiseTexture2D:
	var noise: = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 33
	noise.frequency = 0.28
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 1
	var tex: = NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.noise = noise
	return tex


func _build_material(leaf_tex: Texture2D, accent_tex: Texture2D, sun_travel_dir: Vector3) -> ShaderMaterial:
	var mat: = ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("grass_tex", leaf_tex)
	mat.set_shader_parameter("accent_tex", accent_tex)
	mat.set_shader_parameter("grass_color", grass_color)

	mat.set_shader_parameter("patch_color2", grass_color.darkened(0.22))
	mat.set_shader_parameter("patch_color3", grass_color.lightened(0.18))

	var sh: Dictionary = SHADES.get(shade, SHADES["realistic"])
	mat.set_shader_parameter("toon_cuts", float(sh["cuts"]))
	mat.set_shader_parameter("toon_softness", float(sh["soft"]))
	mat.set_shader_parameter("base_darken", float(sh["darken"]))




	mat.set_shader_parameter("accent_freq", 0.0)
	mat.set_shader_parameter("patch_noise", _make_noise(0.01, 11))
	mat.set_shader_parameter("wind_noise", _make_noise(0.5, 22, false))
	mat.set_shader_parameter("cloud_noise", _make_cloud_noise())
	mat.set_shader_parameter("cloud_pattern", 9)
	mat.set_shader_parameter("wind_angle", 2.2253)
	mat.set_shader_parameter("cloud_speed", 0.0508)
	mat.set_shader_parameter("cloud_scale", 0.0251)
	mat.set_shader_parameter("wave_freq", 0.215)
	mat.set_shader_parameter("wave_amount", 0.7375)
	mat.set_shader_parameter("cloud_strength", float(SHADES.get(shade, SHADES["realistic"])["cloud"]))
	mat.set_shader_parameter("alpha_clip", 0.15)
	mat.set_shader_parameter("height_scale", 0.445)
	mat.set_shader_parameter("width_scale", 1.0)
	mat.set_shader_parameter("wind_speed", 0.03)
	mat.set_shader_parameter("wind_strength", 0.18)
	mat.set_shader_parameter("wind_zone_scale", 0.012)
	mat.set_shader_parameter("wind_calm_thresh", 0.34)
	mat.set_shader_parameter("wind_gust_freq", 0.03)
	mat.set_shader_parameter("wind_gust_speed", 1.1)
	mat.set_shader_parameter("wind_gust_amount", 0.6)
	mat.set_shader_parameter("player_position", Vector3(99999, 0, 99999))
	mat.set_shader_parameter("player_radius", 1.0)
	mat.set_shader_parameter("player_push", 0.7)
	mat.set_shader_parameter("sun_dir", sun_travel_dir)
	mat.set_shader_parameter("sun_color", Color(1.0, 0.96, 0.86))
	mat.set_shader_parameter("ambient_color", Color(0.42, 0.48, 0.52))
	mat.set_shader_parameter("wind_on", true)
	mat.set_shader_parameter("clouds_on", true)
	mat.set_shader_parameter("fade_on", true)
	mat.set_shader_parameter("use_texture", true)
	mat.set_shader_parameter("billboard_on", true)
	mat.set_shader_parameter("view_fade_start", 28.0)
	mat.set_shader_parameter("view_fade_end", 46.0)
	return mat




func _alloc_field() -> void :
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = _make_blade_mesh()
	_mm.instance_count = SLOT_POOL
	_mm.visible_instance_count = 0
	multimesh = _mm
	_live.clear()
	_live_blades = 0
	_free.resize(SLOT_POOL)
	_free_top = 0
	_frontier = 0


func _focus_xz() -> Vector2:
	if focus_node != null:
		return Vector2(focus_node.global_position.x, focus_node.global_position.z)
	return Vector2.ZERO


func _mode_radius() -> int:
	return int(MODE_RADIUS[grass_mode])


func _target_for_cell(dx: int, dz: int) -> int:
	var r: = _mode_radius()
	var d: = sqrt(float(dx * dx + dz * dz))
	if d > float(r):
		return 0
	var c: = float(clusters_per_cell)
	var core: = float(MODE_CORE[grass_mode])
	if d <= core:
		return int(c)
	var span: float = maxf(float(r) - core, 0.001)
	var t: float = clampf((d - core) / span, 0.0, 1.0)
	match grass_mode:
		MODE_BIG:
			return int(c * pow(1.0 - t, 1.3))
		MODE_XBIG:
			return int(c * pow(1.0 - t, 1.4))
		MODE_MAP:
			return int(c * pow(1.0 - t, 4.0))
		MODE_RIM:
			var floor_d: = float(RIM_OUTER_DENSITY)
			return int(floor_d + (c - floor_d) * pow(1.0 - t, 5.0))
	return int(c)


func _cell_seed(key: Vector2i) -> int:
	return int((key.x * 73856093) ^ (key.y * 19349663)) & 2147483647


func _sync_visible_count() -> void :
	if _mm != null and _mm.visible_instance_count != _frontier:
		_mm.visible_instance_count = _frontier


func _alloc_slot() -> int:
	if _free_top > 0:
		_free_top -= 1
		return _free[_free_top]
	if _frontier < SLOT_POOL:
		var s: = _frontier
		_frontier += 1
		return s
	return -1


func _fill_cell(key: Vector2i, dx: int, dz: int) -> void :
	var gt: Dictionary = GRASS_TYPES.get(grass_type, GRASS_TYPES["uniform"])
	var patch: float = float(gt["patch"])
	var target: = int(_target_for_cell(dx, dz) * float(gt["density"]))
	var ox: = float(key.x) * CELL_SIZE
	var oz: = float(key.y) * CELL_SIZE
	var crng: = RandomNumberGenerator.new()
	crng.seed = _cell_seed(key)
	var slots: = PackedInt32Array()
	var placed: = 0
	while placed < target:
		var wx: = ox + crng.randf_range(0.0, CELL_SIZE)
		var wz: = oz + crng.randf_range(0.0, CELL_SIZE)
		var s: = crng.randf_range(SCALE_MIN, SCALE_MAX) * float(gt["wmul"])
		var hmul: = crng.randf_range(float(gt["h_lo"]), float(gt["h_hi"]))
		var yaw: = crng.randf() * TAU
		placed += 1
		if patch > 0.0 and (_type_noise.get_noise_2d(wx, wz) + 1.0) * 0.5 < patch:
			continue
		if terrain != null and terrain.grass_weight(wx, wz) < 0.35:
			continue
		var slot: int = _alloc_slot()
		if slot < 0:
			break
		var wy: float = terrain.sample_height(wx, wz).y if terrain != null else 0.0
		var basis: = Basis(Vector3.UP, yaw).scaled(Vector3(s, s * hmul, s))
		_mm.set_instance_transform(slot, Transform3D(basis, Vector3(wx, wy + 0.05, wz)))
		slots.append(slot)
	_live[key] = {"slots": slots, "target": target}
	_live_blades += slots.size()


func _free_cell(key: Vector2i) -> void :
	var entry: Dictionary = _live[key]
	var slots: PackedInt32Array = entry["slots"]
	var hidden: = Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	for slot in slots:
		_mm.set_instance_transform(slot, hidden)
		_free[_free_top] = slot
		_free_top += 1
	_live_blades -= slots.size()
	_live.erase(key)


func _update_cells() -> void :
	if _mm == null:
		return
	var fp: = _focus_xz()
	var pc: = Vector2i(int(floor(fp.x / CELL_SIZE)), int(floor(fp.y / CELL_SIZE)))
	var r: = _mode_radius()
	var r2: = r * r

	if pc != _prev_focus_cell:
		_prev_focus_cell = pc
		_redensify_dirty = true
		_fill_pending = true
		var to_free: Array = []
		for key in _live:
			var dx: int = key.x - pc.x
			var dz: int = key.y - pc.y
			if dx * dx + dz * dz > r2:
				to_free.append(key)
		for key in to_free:
			_free_cell(key)

	if _fill_pending:
		var candidates: Array = []
		for dz in range( - r, r + 1):
			for dx in range( - r, r + 1):
				if dx * dx + dz * dz > r2:
					continue
				var key: = Vector2i(pc.x + dx, pc.y + dz)
				if not _live.has(key):
					candidates.append(Vector2i(dx, dz))
		if candidates.is_empty():
			_fill_pending = false
		else:
			candidates.sort_custom( func(a, b): return (a.x * a.x + a.y * a.y) < (b.x * b.x + b.y * b.y))
			var filled: = 0
			for off in candidates:
				if _frontier >= SLOT_POOL and _free_top <= 0:
					break
				_fill_cell(Vector2i(pc.x + off.x, pc.y + off.y), off.x, off.y)
				filled += 1
				if filled >= FILL_CELLS_PER_FRAME:
					break

	if _redensify_dirty:
		_redensify(pc)

	_sync_visible_count()


func _redensify(pc: Vector2i) -> void :
	if grass_mode == MODE_NORMAL:
		_redensify_dirty = false
		return
	var stale: Array = []
	for key in _live:
		var dx: int = key.x - pc.x
		var dz: int = key.y - pc.y
		var want: = _target_for_cell(dx, dz)
		var have: int = _live[key]["target"]
		if abs(want - have) > REDENSIFY_THRESHOLD:
			stale.append({"key": key, "d2": dx * dx + dz * dz})
	if stale.is_empty():
		_redensify_dirty = false
		return
	stale.sort_custom( func(a, b): return a["d2"] < b["d2"])
	var n: int = mini(REDENSIFY_PER_FRAME, stale.size())
	for i in n:
		var key: Vector2i = stale[i]["key"]
		_free_cell(key)
		_fill_cell(key, key.x - pc.x, key.y - pc.y)


func _fill_ring_now() -> void :
	var fp: = _focus_xz()
	var pc: = Vector2i(int(floor(fp.x / CELL_SIZE)), int(floor(fp.y / CELL_SIZE)))
	var r: = _mode_radius()
	var r2: = r * r
	var candidates: Array = []
	for dz in range( - r, r + 1):
		for dx in range( - r, r + 1):
			if dx * dx + dz * dz <= r2:
				candidates.append(Vector2i(dx, dz))
	candidates.sort_custom( func(a, b): return (a.x * a.x + a.y * a.y) < (b.x * b.x + b.y * b.y))
	for off in candidates:
		if _frontier >= SLOT_POOL and _free_top <= 0:
			break
		var key: = Vector2i(pc.x + off.x, pc.y + off.y)
		if not _live.has(key):
			_fill_cell(key, off.x, off.y)
	_fill_pending = false
	_sync_visible_count()


func set_grass_mode(mode: int) -> void :
	grass_mode = mode
	var reach: = float(_mode_radius()) * CELL_SIZE
	if _mat != null:
		_mat.set_shader_parameter("view_fade_start", reach - CELL_SIZE * 2.5)
		_mat.set_shader_parameter("view_fade_end", reach - CELL_SIZE * 0.5)
	_rebuild()


func _rebuild() -> void :
	if _mm == null:
		return
	_live.clear()
	_live_blades = 0
	_free_top = 0
	_frontier = 0
	_fill_ring_now()







func _build_static_grid() -> void :
	_active_outer = outer_half if outer_half > 0.0 else minf(playable_half * 2.0, OUTER_HALF_CAP)
	_active_outer = maxf(_active_outer, playable_half)
	var n: = int(ceil((_active_outer * 2.0) / TILE_SIZE))
	for ti in n:
		for tj in n:
			var tx: = - _active_outer + (float(ti) + 0.5) * TILE_SIZE
			var tz: = - _active_outer + (float(tj) + 0.5) * TILE_SIZE
			_build_tile(tx, tz)





func _build_tile(tx: float, tz: float) -> void :
	var half: = TILE_SIZE * 0.5
	var x0: = tx - half
	var z0: = tz - half
	var x1: = tx + half
	var z1: = tz + half
	var gi0: = int(floor(x0 / CELL_SIZE))
	var gi1: = int(floor(x1 / CELL_SIZE))
	var gj0: = int(floor(z0 / CELL_SIZE))
	var gj1: = int(floor(z1 / CELL_SIZE))
	var transforms: Array[Transform3D] = []
	for gi in range(gi0, gi1 + 1):
		for gj in range(gj0, gj1 + 1):
			var cell_ox: = float(gi) * CELL_SIZE
			var cell_oz: = float(gj) * CELL_SIZE
			var ccx: = cell_ox + CELL_SIZE * 0.5
			var ccz: = cell_oz + CELL_SIZE * 0.5
			var count: int
			if absf(ccx) <= playable_half and absf(ccz) <= playable_half:
				count = clusters_per_cell
			elif absf(ccx) <= _active_outer and absf(ccz) <= _active_outer:
				count = sparse_clusters
			else:
				continue
			var gt: Dictionary = GRASS_TYPES.get(grass_type, GRASS_TYPES["uniform"])
			var patch: float = float(gt["patch"])
			count = int(count * float(gt["density"]))
			var crng: = RandomNumberGenerator.new()
			crng.seed = _cell_seed(Vector2i(gi, gj))
			for _b in count:
				var wx: = cell_ox + crng.randf_range(0.0, CELL_SIZE)
				var wz: = cell_oz + crng.randf_range(0.0, CELL_SIZE)
				var s: = crng.randf_range(SCALE_MIN, SCALE_MAX) * float(gt["wmul"])
				var hmul: = crng.randf_range(float(gt["h_lo"]), float(gt["h_hi"]))
				var yaw: = crng.randf() * TAU
				if wx < x0 or wx >= x1 or wz < z0 or wz >= z1:
					continue
				if patch > 0.0 and (_type_noise.get_noise_2d(wx, wz) + 1.0) * 0.5 < patch:
					continue
				if terrain != null and terrain.grass_weight(wx, wz) < 0.35:
					continue
				var wy: float = terrain.sample_height(wx, wz).y if terrain != null else 0.0
				var basis: = Basis(Vector3.UP, yaw).scaled(Vector3(s, s * hmul, s))
				transforms.append(Transform3D(basis, Vector3(wx - tx, wy + 0.05, wz - tz)))
	if transforms.is_empty():
		return
	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _shared_mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi: = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.position = Vector3(tx, 0.0, tz)
	mmi.custom_aabb = AABB(Vector3( - half - 1.0, -60.0, - half - 1.0), Vector3(TILE_SIZE + 2.0, 120.0, TILE_SIZE + 2.0))
	mmi.visibility_range_end = TILE_VIEW_DIST
	add_child(mmi)
	_tiles.append(mmi)
