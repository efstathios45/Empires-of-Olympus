extends RefCounted





















const NpcScript = preload("res://scripts/npc.gd")

const TEMPLE: = "res://assets/environment/buildings/greek_temple.glb"
const TOWNHOUSE: = "res://assets/environment/buildings/greek_townhouse.glb"
const STOA: = "res://assets/environment/buildings/greek_stoa_colonnade.glb"
const STALL: = "res://assets/environment/buildings/agora_market_stall.glb"
const FOUNTAIN: = "res://assets/environment/structures/marble_fountain.glb"
const GATE_ARCH: = "res://assets/environment/structures/city_gate_arch.glb"
const BRAZIER: = "res://assets/environment/structures/brazier_flame.glb"
const COLUMN: = "res://assets/environment/structures/marble_column.glb"
const CART: = "res://assets/environment/obstacles/olive_cart.glb"
const DUMMY: = "res://assets/environment/obstacles/training_dummy.glb"
const ALTAR: = "res://assets/props/furniture/marble_altar.glb"
const STATUE: = "res://assets/props/decorations/greek_statue.glb"
const ANVIL: = "res://assets/props/tools/blacksmith_anvil.glb"
const AMPHORA: = "res://assets/props/containers/amphora.glb"

const MOSAIC_TEX: = "res://assets/textures/stone/greek_pebble_mosaic.png"

const MOSAIC_TILE_TEX: = "res://assets/textures/stone/old_mosaic_floor_cc0.png"
const FREE_VASE: = "res://assets/props/decorations/free_antique_ceramic_vase_01/antique_ceramic_vase_01.glb"
const FREE_BUST: = "res://assets/props/decorations/free_marble_bust_01/marble_bust_01.glb"


const TEMPLE_POS: = Vector2(0.0, -20.0)
const TEMPLE_H: = 13.5
const TEMPLE_HALF_X: = 8.35
const TEMPLE_HALF_Z: = 7.4
const TEMPLE_STEP_TOP: = 1.52

const PAVE_R: = 13.0
const COLUMN_RING_R: = 10.5


static func build(world) -> void :
	_paving(world)
	_temple_precinct(world)
	_fountain_court(world)
	_market_row(world)
	_stoa_and_houses(world)
	_south_gate(world)
	_smith_yard(world)
	_townsfolk(world)






static func _paving(world) -> void :
	var court_mat: = StandardMaterial3D.new()

	court_mat.albedo_color = Color(0.82, 0.74, 0.62)
	if ResourceLoader.exists(MOSAIC_TEX):
		court_mat.albedo_texture = load(MOSAIC_TEX)

	court_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	court_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	court_mat.roughness = 0.92
	court_mat.metallic = 0.0

	var road_mat: = StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.7, 0.62, 0.52)
	if ResourceLoader.exists(MOSAIC_TILE_TEX):
		road_mat.albedo_texture = load(MOSAIC_TILE_TEX)
	elif ResourceLoader.exists(MOSAIC_TEX):
		road_mat.albedo_texture = load(MOSAIC_TEX)
	road_mat.uv1_scale = Vector3(2.5, 5.0, 1.0)
	road_mat.roughness = 0.94
	road_mat.metallic = 0.0

	var gy: float = world.sample_height(0.0, 0.0)

	var disc: = MeshInstance3D.new()

	disc.mesh = _make_disc_mesh(PAVE_R, 64, 1.8)
	disc.material_override = court_mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(disc)
	disc.global_position = Vector3(0.0, gy + 0.02, 0.0)

	var road: = MeshInstance3D.new()
	var box: = BoxMesh.new()
	box.size = Vector3(7.0, 0.12, 13.0)
	road.mesh = box
	road.material_override = road_mat
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(road)
	road.global_position = Vector3(0.0, gy + 0.02, 19.0)




static func _make_disc_mesh(radius: float, segments: int, metres_per_tile: float = 2.0) -> ArrayMesh:
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(Vector3.ZERO)
	var inv: float = 1.0 / maxf(0.01, metres_per_tile)
	for i in range(segments + 1):
		var a: float = TAU * float(i) / float(segments)
		var x: float = cos(a) * radius
		var z: float = sin(a) * radius
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(x * inv, z * inv))
		st.add_vertex(Vector3(x, 0.0, z))
	for i in range(segments):
		st.add_index(0)
		st.add_index(i + 1)
		st.add_index(i + 2)
	return st.commit()



static func _temple_precinct(world) -> void :
	var gy: float = world.sample_height(TEMPLE_POS.x, TEMPLE_POS.y)

	var temple = world._place_glb(TEMPLE, TEMPLE_POS.x, TEMPLE_POS.y, TEMPLE_H, 180.0, 0)
	if temple != null:


		world._add_box_collider(temple, 
			Vector3(TEMPLE_HALF_X * 2.0, TEMPLE_STEP_TOP, TEMPLE_HALF_Z * 2.0), 
			Vector3(0.0, TEMPLE_STEP_TOP * 0.5, 0.0))


		var front_z: float = TEMPLE_POS.y + TEMPLE_HALF_Z
		world._add_ramp_collider(
			Vector3(0.0, gy + 0.02, front_z + 4.7), 
			Vector3(0.0, gy + TEMPLE_STEP_TOP, front_z + 0.05), 4.4)


	var altar = world._place_glb(ALTAR, -4.6, -6.6, 2.2, 20.0, 0)
	if altar != null:
		world._add_box_collider(altar, Vector3(1.4, 1.1, 1.4), Vector3(0.0, 0.55, 0.0))

	_brazier(world, -6.4, -10.6)
	_brazier(world, 6.4, -10.6)

	_statue(world, -11.6, -13.4, 200.0)
	_statue(world, 11.6, -13.4, 160.0)


	var priestess = NpcScript.create("priestess", "Priestess Melite", 
		"res://assets/characters/oracle_priestess/oracle_priestess.glb", 
		"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres", 
		Vector3(-7.4, 0.0, -5.8), 1.72, 130.0)
	world.add_child(priestess)
	world.add_interactable(priestess)



static func _fountain_court(world) -> void :
	var fountain = world._place_glb(FOUNTAIN, 0.0, 0.0, 2.6, 0.0, 0)
	if fountain != null:
		world._add_box_collider(fountain, Vector3(2.5, 1.25, 1.7), 
			Vector3(0.0, 0.62, 0.0))



	for i in 6:
		var a: float = TAU * float(i) / 6.0
		var cx: float = cos(a) * COLUMN_RING_R
		var cz: float = sin(a) * COLUMN_RING_R
		var col = world._place_glb(COLUMN, cx, cz, 6.2, 0.0, 0)
		if col != null:
			world._add_pillar_collider(col, 0.52, 6.2, Vector3.ZERO)

	_brazier(world, -8.6, 4.6)
	_brazier(world, 8.6, 4.6)


	var vase = world._place_glb(FREE_VASE, 6.8, -3.2, 0.95, 25.0, 0)
	if vase != null:
		world._add_pillar_collider(vase, 0.22, 0.95, Vector3.ZERO)
	var bust = world._place_glb(FREE_BUST, -7.2, 2.4, 1.15, 140.0, 0)
	if bust != null:
		world._add_pillar_collider(bust, 0.28, 1.15, Vector3.ZERO)



static func _market_row(world) -> void :

	for z in [-6.2, -1.6, 3.0, 7.6]:
		var stall = world._place_glb(STALL, 15.6, float(z), 3.0, 90.0, 0)
		if stall != null:

			world._add_box_collider(stall, Vector3(1.6, 1.6, 1.8), Vector3(0.0, 0.8, 0.0))
	_cart(world, 12.9, -9.2, 25.0)
	_cart(world, 17.4, 0.8, 200.0)
	for p in [Vector2(13.1, -6.6), Vector2(13.8, -5.5), Vector2(17.2, -4.4), 
			Vector2(13.3, 7.6), Vector2(17.4, 6.4), Vector2(13.6, 2.2)]:
		_amphora(world, p.x, p.y)



static func _stoa_and_houses(world) -> void :

	var stoa = world._place_glb(STOA, -17.6, 0.0, 7.0, 90.0, 0)
	if stoa != null:

		world._add_box_collider(stoa, Vector3(11.0, 5.5, 2.4), 
			Vector3(0.0, 2.75, 0.0))


	var houses: = [
		[-25.5, -12.5, 8.0, 115.0], 
		[-24.5, 12.2, 7.6, 65.0], 
		[19.6, -17.6, 8.4, 205.0], 
		[21.2, 13.6, 7.8, 300.0], 
		[-9.6, 22.2, 8.0, 355.0], 
	]
	for h in houses:
		var house = world._place_glb(TOWNHOUSE, float(h[0]), float(h[1]), float(h[2]), float(h[3]), 0)
		if house != null:

			world._add_box_collider(house, Vector3(4.2, 4.8, 3.6), 
				Vector3(0.0, 2.4, 0.0))
	_cart(world, -13.2, -9.4, 160.0)
	_amphora(world, -13.4, 5.6)
	_amphora(world, -12.9, 6.5)



static func _south_gate(world) -> void :
	var gate = world._place_glb(GATE_ARCH, 0.0, 26.0, 9.0, 0.0, 0)
	if gate != null:

		world._add_box_collider(gate, Vector3(2.6, 8.5, 2.2), Vector3(3.2, 4.25, 0.0))
		world._add_box_collider(gate, Vector3(2.6, 8.5, 2.2), Vector3(-3.2, 4.25, 0.0))
	_brazier(world, -4.8, 24.4)
	_brazier(world, 4.8, 24.4)



static func _smith_yard(world) -> void :
	var anvil = world._place_glb(ANVIL, 10.6, 15.6, 1.1, 110.0, 0)
	if anvil != null:
		world._add_box_collider(anvil, Vector3(1.1, 0.9, 0.7), Vector3(0.0, 0.45, 0.0))
	_dummy(world, 13.4, 17.6, 15.0)
	_dummy(world, 12.2, 20.2, -25.0)
	_cart(world, 8.3, 19.4, 40.0)
	_amphora(world, 9.0, 17.3)
	_amphora(world, 11.9, 19.8)


	var smith = NpcScript.create("smith", "Brontes the Smith", 
		"res://assets/characters/blacksmith_npc/blacksmith_npc.glb", 
		"res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres", 
		Vector3(9.4, 0.0, 14.2), 1.8, 150.0)
	world.add_child(smith)
	world.add_interactable(smith)



static func _brazier(world, x: float, z: float) -> void :
	var b = world._place_glb(BRAZIER, x, z, 1.6, 0.0, 0)
	if b != null:
		world._add_pillar_collider(b, 0.42, 1.6, Vector3.ZERO)

static func _statue(world, x: float, z: float, yaw: float) -> void :
	var s = world._place_glb(STATUE, x, z, 3.4, yaw, 0)
	if s != null:
		world._add_pillar_collider(s, 0.52, 3.4, Vector3.ZERO)

static func _dummy(world, x: float, z: float, yaw: float) -> void :
	var d = world._place_glb(DUMMY, x, z, 2.0, yaw, 0)
	if d != null:
		world._add_pillar_collider(d, 0.3, 2.0, Vector3.ZERO)

static func _cart(world, x: float, z: float, yaw: float) -> void :
	var c = world._place_glb(CART, x, z, 1.4, yaw, 0)
	if c != null:
		world._add_box_collider(c, Vector3(1.6, 1.2, 2.2), Vector3(0.0, 0.6, 0.0))

static func _amphora(world, x: float, z: float) -> void :
	var a = world._place_glb(AMPHORA, x, z, 0.9, randf() * 360.0, 0)
	if a != null:
		world._add_pillar_collider(a, 0.22, 0.9, Vector3.ZERO)








const MERCHANT_GLB: = "res://assets/characters/citizen_merchant/citizen_merchant.glb"
const MERCHANT_LIB: = "res://assets/characters/citizen_merchant/citizen_merchant_animations.tres"
const WOMAN_GLB: = "res://assets/characters/citizen_woman/citizen_woman.glb"
const WOMAN_LIB: = "res://assets/characters/citizen_woman/citizen_woman_animations.tres"
const GUARD_GLB: = "res://assets/characters/city_guard/city_guard.glb"
const GUARD_LIB: = "res://assets/characters/city_guard/city_guard_animations.tres"

static func _townsfolk(world) -> void :
	var folk: = [
		{"kind": "merchant", "name": "Hesiod the Oil Merchant", 
			"at": Vector3(13.9, 0.0, -3.8), "yaw": 100.0, "idle": "Idle_Neutral", 
			"line": "Finest olive oil in Hellas — pressed this very morning!"}, 
		{"kind": "merchant", "name": "Kleon the Potter", 
			"at": Vector3(13.9, 0.0, 5.4), "yaw": 80.0, "idle": "Idle_Neutral", 
			"line": "Amphorae, hero! Sturdy enough to outlive your grandchildren."}, 
		{"kind": "merchant", "name": "Xanthos the Fruit-Seller", 
			"at": Vector3(17.0, 0.0, 9.8), "yaw": 130.0, "idle": "Idle_Neutral", 
			"line": "Figs, dates, honey cakes! Coin first, glory later."}, 
		{"kind": "woman", "name": "Thalia", "at": Vector3(2.9, 0.0, 3.2), 
			"yaw": 205.0, "idle": "Idle_Neutral", 
			"line": "They say the priestess had another vision at dawn. Awful omens."}, 
		{"kind": "woman", "name": "Eirene", "at": Vector3(-2.6, 0.0, 4.6), 
			"yaw": 25.0, "idle": "Idle_Neutral", 
			"line": "The fountain runs cold as Boreas' breath. Blessed be Athena."}, 
		{"kind": "woman", "name": "Old Myrrine", "at": Vector3(-11.4, 0.0, 8.2), 
			"yaw": 90.0, "idle": "Idle_Neutral", 
			"line": "In my day the agora had twice the stalls. And better bread."}, 
		{"kind": "guard", "name": "Guard Lysandros", "at": Vector3(-3.4, 0.0, 22.0), 
			"yaw": 0.0, "idle": "Idle_Sword", 
			"line": "Wolves beyond that gate, and worse. Sharpen your spear first."}, 
		{"kind": "guard", "name": "Guard Nikanor", "at": Vector3(3.4, 0.0, 22.0), 
			"yaw": 0.0, "idle": "Idle_Neutral", 
			"line": "The Minotaur's arena lies south. Nobody who goes comes back."}, 
		{"kind": "guard", "name": "Sentry Damon", "at": Vector3(-4.2, 0.0, -10.6), 
			"yaw": 175.0, "idle": "Idle_Sword", 
			"line": "Mind the sacred steps, stranger. Athena watches this square."}, 
	]
	var idx: = 0
	for f in folk:
		var kind: String = String(f["kind"])
		var glb: String = MERCHANT_GLB
		var lib: String = MERCHANT_LIB
		var height: float = 1.78
		if kind == "woman":
			glb = WOMAN_GLB
			lib = WOMAN_LIB
			height = 1.68
		elif kind == "guard":
			glb = GUARD_GLB
			lib = GUARD_LIB
			height = 1.84
		if not ResourceLoader.exists(glb):
			continue
		idx += 1
		var n = NpcScript.create_flavour("citizen_%d" % idx, String(f["name"]), 
			glb, lib, f["at"], height, float(f["yaw"]), 
			String(f["idle"]), String(f["line"]))
		world.add_child(n)
		world.add_interactable(n)
