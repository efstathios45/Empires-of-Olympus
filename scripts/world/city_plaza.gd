extends RefCounted
## CityPlaza — the layout of Thermopolis, the agora hub at the world origin.
##
## A pure layout script: it owns WHERE everything in the city centre stands and
## nothing else. Placement, grounding and collision live on GameWorld, which is
## passed in as `world`. The parameter is deliberately UNTYPED so this helper can
## call GameWorld's placement API without a hard type dependency (and so a single
## -script parse check of this file stays clean).
##
## Compass: north = -Z, south = +Z, east = +X, west = -X.
##   north  — the temple of Athena on its stepped stylobate, guarded, brazier-lit
##   centre — the marble fountain on a ψηφιδωτό pebble-mosaic court, six columns
##   east   — the market row: four stalls, carts, amphorae, merchants
##   west   — the stoa colonnade, townhouses closing the street edge
##   south  — the city gate arch, the road out to the wilds, gate guards
##   south-east — the smith's yard: anvil, training posts, cart
##
## Collision policy (this is what fixed the "invisible walls" complaint):
## every piece of large architecture is placed with tier 0 (NO automatic
## collider) and then given a hand-authored shape that hugs what you can see.
## Small props keep their tight tier-1 box. Backdrop pieces get nothing.

const NpcScript = preload("res://scripts/npc.gd")

const TEMPLE := "res://assets/environment/buildings/greek_temple.glb"
const TOWNHOUSE := "res://assets/environment/buildings/greek_townhouse.glb"
const STOA := "res://assets/environment/buildings/greek_stoa_colonnade.glb"
const STALL := "res://assets/environment/buildings/agora_market_stall.glb"
const FOUNTAIN := "res://assets/environment/structures/marble_fountain.glb"
const GATE_ARCH := "res://assets/environment/structures/city_gate_arch.glb"
const BRAZIER := "res://assets/environment/structures/brazier_flame.glb"
const COLUMN := "res://assets/environment/structures/marble_column.glb"
const CART := "res://assets/environment/obstacles/olive_cart.glb"
const DUMMY := "res://assets/environment/obstacles/training_dummy.glb"
const ALTAR := "res://assets/props/furniture/marble_altar.glb"
const STATUE := "res://assets/props/decorations/greek_statue.glb"
const ANVIL := "res://assets/props/tools/blacksmith_anvil.glb"
const AMPHORA := "res://assets/props/containers/amphora.glb"
## Ancient Greek pebble mosaic (ψηφιδωτό) for the fountain court.
const MOSAIC_TEX := "res://assets/textures/stone/greek_pebble_mosaic.png"
## Seamless CC0 mosaic tiles (Poly Haven) for the road out to the gate.
const MOSAIC_TILE_TEX := "res://assets/textures/stone/old_mosaic_floor_cc0.png"
const FREE_VASE := "res://assets/props/decorations/free_antique_ceramic_vase_01/antique_ceramic_vase_01.glb"
const FREE_BUST := "res://assets/props/decorations/free_marble_bust_01/marble_bust_01.glb"

# Temple: 13.5 m tall → 16.9 x 14.9 m footprint, stylobate top 1.52 m up.
const TEMPLE_POS := Vector2(0.0, -20.0)
const TEMPLE_H := 13.5
const TEMPLE_HALF_X := 8.35
const TEMPLE_HALF_Z := 7.40
const TEMPLE_STEP_TOP := 1.52

const PAVE_R := 13.0          # radius of the paved fountain circle
const COLUMN_RING_R := 10.5   # the six plaza columns


static func build(world) -> void:
	_paving(world)
	_temple_precinct(world)
	_fountain_court(world)
	_market_row(world)
	_stoa_and_houses(world)
	_south_gate(world)
	_smith_yard(world)
	_townsfolk(world)


# ── Paving ───────────────────────────────────────────────────────────────
## ψηφιδωτό tessera pavement on the fountain court + tiled road to the gate.
## Purely decorative, so no collider and no shadow casting; the top sits 2 cm
## over the (flattened) pad so it can never z-fight the terrain.
static func _paving(world) -> void:
	var court_mat := StandardMaterial3D.new()
	# Warm, muted tint — never the old blown-out white marble.
	court_mat.albedo_color = Color(0.82, 0.74, 0.62)
	if ResourceLoader.exists(MOSAIC_TEX):
		court_mat.albedo_texture = load(MOSAIC_TEX)
	# Planar metres→UV on the disc; ~1.8 m per tile repeat reads as pavement.
	court_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	court_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	court_mat.roughness = 0.92
	court_mat.metallic = 0.0

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.70, 0.62, 0.52)
	if ResourceLoader.exists(MOSAIC_TILE_TEX):
		road_mat.albedo_texture = load(MOSAIC_TILE_TEX)
	elif ResourceLoader.exists(MOSAIC_TEX):
		road_mat.albedo_texture = load(MOSAIC_TEX)
	road_mat.uv1_scale = Vector3(2.5, 5.0, 1.0)
	road_mat.roughness = 0.94
	road_mat.metallic = 0.0

	var gy: float = world.sample_height(0.0, 0.0)

	var disc := MeshInstance3D.new()
	# Planar XZ UVs (metres) — NOT radial UVs (those turn any tile into a shield).
	disc.mesh = _make_disc_mesh(PAVE_R, 64, 1.8)
	disc.material_override = court_mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(disc)
	disc.global_position = Vector3(0.0, gy + 0.02, 0.0)

	var road := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(7.0, 0.12, 13.0)
	road.mesh = box
	road.material_override = road_mat
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(road)
	road.global_position = Vector3(0.0, gy + 0.02, 19.0)


## Flat circular mesh with planar XZ UVs so a tessera texture tiles as pavement.
## `metres_per_tile` controls how many world metres one texture repeat covers.
static func _make_disc_mesh(radius: float, segments: int, metres_per_tile: float = 2.0) -> ArrayMesh:
	var st := SurfaceTool.new()
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


# ── North: the temple precinct ───────────────────────────────────────────
static func _temple_precinct(world) -> void:
	var gy: float = world.sample_height(TEMPLE_POS.x, TEMPLE_POS.y)
	# yaw 180 turns the colonnaded front (model -Z) toward the plaza.
	var temple = world._place_glb(TEMPLE, TEMPLE_POS.x, TEMPLE_POS.y, TEMPLE_H, 180.0, 0)
	if temple != null:
		# ONE box, exactly the stepped stylobate: you can walk all the way to the
		# marble and around the whole building, and its top is walkable.
		world._add_box_collider(temple,
			Vector3(TEMPLE_HALF_X * 2.0, TEMPLE_STEP_TOP, TEMPLE_HALF_Z * 2.0),
			Vector3(0.0, TEMPLE_STEP_TOP * 0.5, 0.0))
		# ...and a hidden slope over the front steps so you can climb onto the
		# porch and walk between the columns instead of bumping into the plinth.
		var front_z: float = TEMPLE_POS.y + TEMPLE_HALF_Z
		world._add_ramp_collider(
			Vector3(0.0, gy + 0.02, front_z + 4.7),
			Vector3(0.0, gy + TEMPLE_STEP_TOP, front_z + 0.05), 4.4)

	# The altar of offerings — tight box only (no inflated AABB).
	var altar = world._place_glb(ALTAR, -4.6, -6.6, 2.2, 20.0, 0)
	if altar != null:
		world._add_box_collider(altar, Vector3(1.4, 1.1, 1.4), Vector3(0.0, 0.55, 0.0))
	# Bronze braziers flanking the steps.
	_brazier(world, -6.4, -10.6)
	_brazier(world, 6.4, -10.6)
	# Votive statues framing the approach.
	_statue(world, -11.6, -13.4, 200.0)
	_statue(world, 11.6, -13.4, 160.0)

	# Priestess Melite — the quest giver, by the altar.
	var priestess = NpcScript.create("priestess", "Priestess Melite",
		"res://assets/characters/quaternius_woman_formal/woman_formal.glb",
		"",
		Vector3(-7.4, 0.0, -5.8), 1.72, 130.0)
	priestess.idle_clip = "Idle_Neutral"
	priestess.greek_role = "oracle"
	world.add_child(priestess)
	world.add_interactable(priestess)


# ── Centre: the fountain court ───────────────────────────────────────────
static func _fountain_court(world) -> void:
	var fountain = world._place_glb(FOUNTAIN, 0.0, 0.0, 2.6, 0.0, 0)
	if fountain != null:
		world._add_box_collider(fountain, Vector3(2.5, 1.25, 1.7),
			Vector3(0.0, 0.62, 0.0))

	# Six columns ring the court. 10.5 m gaps — generous walking lanes, and the
	# north/south axes are left wide open for the temple and gate roads.
	for i in 6:
		var a: float = TAU * float(i) / 6.0
		var cx: float = cos(a) * COLUMN_RING_R
		var cz: float = sin(a) * COLUMN_RING_R
		var col = world._place_glb(COLUMN, cx, cz, 6.2, 0.0, 0)
		if col != null:
			world._add_pillar_collider(col, 0.52, 6.2, Vector3.ZERO)

	_brazier(world, -8.6, 4.6)
	_brazier(world, 8.6, 4.6)

	# Free CC0 Poly Haven props — tiny colliders so they don't wall the court.
	var vase = world._place_glb(FREE_VASE, 6.8, -3.2, 0.95, 25.0, 0)
	if vase != null:
		world._add_pillar_collider(vase, 0.22, 0.95, Vector3.ZERO)
	var bust = world._place_glb(FREE_BUST, -7.2, 2.4, 1.15, 140.0, 0)
	if bust != null:
		world._add_pillar_collider(bust, 0.28, 1.15, Vector3.ZERO)


# ── East: the market row ─────────────────────────────────────────────────
static func _market_row(world) -> void:
	# Four stalls facing west — footplate boxes only (no awning AABB walls).
	for z in [-6.2, -1.6, 3.0, 7.6]:
		var stall = world._place_glb(STALL, 15.6, float(z), 3.0, 90.0, 0)
		if stall != null:
			## Footplate only — awning must not wall the walkway.
			world._add_box_collider(stall, Vector3(1.6, 1.6, 1.8), Vector3(0.0, 0.8, 0.0))
	_cart(world, 12.9, -9.2, 25.0)
	_cart(world, 17.4, 0.8, 200.0)
	for p in [Vector2(13.1, -6.6), Vector2(13.8, -5.5), Vector2(17.2, -4.4),
			Vector2(13.3, 7.6), Vector2(17.4, 6.4), Vector2(13.6, 2.2)]:
		_amphora(world, p.x, p.y)


# ── West & perimeter: the stoa and the street edge ───────────────────────
static func _stoa_and_houses(world) -> void:
	# Stoa gallery faces the plaza — shallow footprint so walking lanes stay open.
	var stoa = world._place_glb(STOA, -17.6, 0.0, 7.0, 90.0, 0)
	if stoa != null:
		## Slim gallery footprint — leave the plaza walk lanes open.
		world._add_box_collider(stoa, Vector3(11.0, 5.5, 2.4),
			Vector3(0.0, 2.75, 0.0))

	# Townhouses: solid street wall with a tight footprint (not roof AABB).
	var houses := [
		[-25.5, -12.5, 8.0, 115.0],
		[-24.5, 12.2, 7.6, 65.0],
		[19.6, -17.6, 8.4, 205.0],
		[21.2, 13.6, 7.8, 300.0],
		[-9.6, 22.2, 8.0, 355.0],
	]
	for h in houses:
		var house = world._place_glb(TOWNHOUSE, float(h[0]), float(h[1]), float(h[2]), float(h[3]), 0)
		if house != null:
			# Footprint only — roof/eaves must not block the street.
			world._add_box_collider(house, Vector3(4.2, 4.8, 3.6),
				Vector3(0.0, 2.4, 0.0))
	_cart(world, -13.2, -9.4, 160.0)
	_amphora(world, -13.4, 5.6)
	_amphora(world, -12.9, 6.5)


# ── South: the city gate ─────────────────────────────────────────────────
static func _south_gate(world) -> void:
	var gate = world._place_glb(GATE_ARCH, 0.0, 26.0, 9.0, 0.0, 0)
	if gate != null:
		# Two piers only — archway stays walkable (~3.4 m clear).
		world._add_box_collider(gate, Vector3(2.6, 8.5, 2.2), Vector3(3.2, 4.25, 0.0))
		world._add_box_collider(gate, Vector3(2.6, 8.5, 2.2), Vector3(-3.2, 4.25, 0.0))
	_brazier(world, -4.8, 24.4)
	_brazier(world, 4.8, 24.4)


# ── South-east: the smith's yard ─────────────────────────────────────────
static func _smith_yard(world) -> void:
	var anvil = world._place_glb(ANVIL, 10.6, 15.6, 1.1, 110.0, 0)
	if anvil != null:
		world._add_box_collider(anvil, Vector3(1.1, 0.9, 0.7), Vector3(0.0, 0.45, 0.0))
	_dummy(world, 13.4, 17.6, 15.0)
	_dummy(world, 12.2, 20.2, -25.0)
	_cart(world, 8.3, 19.4, 40.0)
	_amphora(world, 9.0, 17.3)
	_amphora(world, 11.9, 19.8)

	# Brontes the smith — refinement and wares.
	var smith = NpcScript.create("smith", "Brontes the Smith",
		"res://assets/characters/quaternius_smith_worker/smith_worker.glb",
		"",
		Vector3(9.4, 0.0, 14.2), 1.8, 150.0)
	smith.idle_clip = "Idle_Neutral"
	smith.greek_role = "smith"
	world.add_child(smith)
	world.add_interactable(smith)


# ── Small-prop shorthands ────────────────────────────────────────────────
static func _brazier(world, x: float, z: float) -> void:
	var b = world._place_glb(BRAZIER, x, z, 1.6, 0.0, 0)
	if b != null:
		world._add_pillar_collider(b, 0.42, 1.6, Vector3.ZERO)

static func _statue(world, x: float, z: float, yaw: float) -> void:
	var s = world._place_glb(STATUE, x, z, 3.4, yaw, 0)
	if s != null:
		world._add_pillar_collider(s, 0.52, 3.4, Vector3.ZERO)

static func _dummy(world, x: float, z: float, yaw: float) -> void:
	var d = world._place_glb(DUMMY, x, z, 2.0, yaw, 0)
	if d != null:
		world._add_pillar_collider(d, 0.3, 2.0, Vector3.ZERO)

static func _cart(world, x: float, z: float, yaw: float) -> void:
	var c = world._place_glb(CART, x, z, 1.4, yaw, 0)
	if c != null:
		world._add_box_collider(c, Vector3(1.6, 1.2, 2.2), Vector3(0.0, 0.6, 0.0))

static func _amphora(world, x: float, z: float) -> void:
	var a = world._place_glb(AMPHORA, x, z, 0.9, randf() * 360.0, 0)
	if a != null:
		world._add_pillar_collider(a, 0.22, 0.9, Vector3.ZERO)


# ── Townsfolk ────────────────────────────────────────────────────────────
## Nine citizens: merchants at the stalls, neighbours gossiping by the fountain,
## guards on the gate and the temple steps. Decoration only — an idle clip each
## and one remark on E. Missing models are skipped silently.
## Quaternius modular bases + GreekLook paint (bronze / crimson / linen).
const MERCHANT_A := "res://assets/characters/quaternius_merchant_farmer/merchant_farmer.glb"
const MERCHANT_B := "res://assets/characters/quaternius_citizen_beach/citizen_beach.glb"
const MERCHANT_C := "res://assets/characters/quaternius_citizen_casual/citizen_casual.glb"
const WOMAN_A := "res://assets/characters/quaternius_woman_worker/woman_worker.glb"
const WOMAN_B := "res://assets/characters/quaternius_woman_casual/woman_casual.glb"
const WOMAN_C := "res://assets/characters/quaternius_woman_formal/woman_formal.glb"
const GUARD_A := "res://assets/characters/quaternius_hero_king/hero_king.glb"
const GUARD_B := "res://assets/characters/quaternius_guard_adventurer/guard_adventurer.glb"
const GUARD_C := "res://assets/characters/quaternius_hero_king/hero_king.glb"

static func _townsfolk(world) -> void:
	var folk := [
		{"glb": MERCHANT_A, "name": "Hesiod the Oil Merchant",
			"at": Vector3(13.9, 0.0, -3.8), "yaw": 100.0, "idle": "Idle_Neutral",
			"height": 1.78, "role": "merchant",
			"line": "Finest olive oil in Hellas — pressed this very morning!"},
		{"glb": MERCHANT_B, "name": "Kleon the Potter",
			"at": Vector3(13.9, 0.0, 5.4), "yaw": 80.0, "idle": "Idle",
			"height": 1.78, "role": "merchant",
			"line": "Amphorae, hero! Sturdy enough to outlive your grandchildren."},
		{"glb": MERCHANT_C, "name": "Xanthos the Fruit-Seller",
			"at": Vector3(17.0, 0.0, 9.8), "yaw": 130.0, "idle": "Wave",
			"height": 1.76, "role": "merchant",
			"line": "Figs, dates, honey cakes! Coin first, glory later."},
		{"glb": WOMAN_A, "name": "Thalia", "at": Vector3(2.9, 0.0, 3.2),
			"yaw": 205.0, "idle": "Idle_Neutral", "height": 1.68, "role": "citizen",
			"line": "They say the priestess had another vision at dawn. Awful omens."},
		{"glb": WOMAN_B, "name": "Eirene", "at": Vector3(-2.6, 0.0, 4.6),
			"yaw": 25.0, "idle": "Idle", "height": 1.68, "role": "citizen",
			"line": "The fountain runs cold as Boreas' breath. Blessed be Athena."},
		{"glb": WOMAN_C, "name": "Old Myrrine", "at": Vector3(-11.4, 0.0, 8.2),
			"yaw": 90.0, "idle": "Interact", "height": 1.66, "role": "citizen",
			"line": "In my day the agora had twice the stalls. And better bread."},
		{"glb": GUARD_A, "name": "Guard Lysandros", "at": Vector3(-3.4, 0.0, 22.0),
			"yaw": 0.0, "idle": "Idle_Sword", "height": 1.84, "role": "guard",
			"line": "Wolves beyond that gate, and worse. Sharpen your spear first."},
		{"glb": GUARD_B, "name": "Guard Nikanor", "at": Vector3(3.4, 0.0, 22.0),
			"yaw": 0.0, "idle": "Idle_Sword", "height": 1.84, "role": "guard",
			"line": "The Minotaur's arena lies south. Nobody who goes comes back."},
		{"glb": GUARD_C, "name": "Sentry Damon", "at": Vector3(-4.2, 0.0, -10.6),
			"yaw": 175.0, "idle": "Idle_Neutral", "height": 1.78, "role": "guard",
			"line": "Mind the sacred steps, stranger. Athena watches this square."},
	]
	var idx := 0
	for f in folk:
		var glb: String = String(f["glb"])
		if not ResourceLoader.exists(glb):
			continue
		idx += 1
		var n = NpcScript.create_flavour("citizen_%d" % idx, String(f["name"]),
			glb, "", f["at"], float(f["height"]), float(f["yaw"]),
			String(f["idle"]), String(f["line"]))
		n.greek_role = String(f.get("role", "citizen"))
		world.add_child(n)
		world.add_interactable(n)
