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
##   centre — the marble fountain in a paved circle ringed by six columns
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
const MARBLE_TEX := "res://assets/textures/stone/white_marble.png"

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
## Flat marble: the fountain circle plus the paved road running out to the gate.
## Purely decorative, so no collider and no shadow casting; the top sits 2 cm
## over the (flattened) pad so it can never z-fight the terrain.
static func _paving(world) -> void:
	# Ancient-Greek tesserae mosaic (ψηφιδωτό) in place of the old bright marble:
	# an earthy limestone/ochre field laced with terracotta / charcoal /
	# Aegean-blue lines and dark grout. Generated in code, no image asset needed.
	var mosaic := _make_mosaic_texture()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = mosaic
	mat.uv1_scale = Vector3(6.0, 6.0, 1.0)
	mat.roughness = 0.94
	mat.metallic = 0.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_texture = mosaic
	road_mat.uv1_scale = Vector3(2.2, 4.0, 1.0)
	road_mat.roughness = 0.94
	road_mat.metallic = 0.0
	road_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var gy: float = world.sample_height(0.0, 0.0)

	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = PAVE_R
	cyl.bottom_radius = PAVE_R
	cyl.height = 0.12
	cyl.radial_segments = 32
	cyl.rings = 1
	disc.mesh = cyl
	disc.material_override = mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(disc)
	disc.global_position = Vector3(0.0, gy - 0.04, 0.0)

	var road := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(7.0, 0.12, 13.0)
	road.mesh = box
	road.material_override = road_mat
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(road)
	road.global_position = Vector3(0.0, gy - 0.04, 19.0)


## Build a seamless ancient-Greek mosaic texture from small tesserae: a muted
## limestone/ochre field, banded every few tiles with terracotta / charcoal /
## Aegean-blue lines, all separated by dark grout. 256px across 16 tiles so it
## tiles cleanly. Deliberately earthy and mid-toned — no white glare.
static func _make_mosaic_texture() -> ImageTexture:
	var size := 256
	var tile := 16          # tesserae edge in px (16 across → seamless)
	var gap := 3            # grout width in px
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	img.fill(Color(0.11, 0.09, 0.08))   # grout
	var field := [Color(0.66, 0.58, 0.44), Color(0.74, 0.62, 0.40)]  # limestone, ochre
	var accent := [Color(0.17, 0.32, 0.45), Color(0.20, 0.17, 0.15), Color(0.60, 0.29, 0.18)]  # blue, charcoal, terracotta
	var n := size / tile
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260811
	for j in n:
		for i in n:
			var col: Color
			if i % 4 == 0 or j % 4 == 0:
				col = accent[(i + j) % accent.size()]
			else:
				col = field[(i + j) % field.size()]
			var jit := rng.randf_range(-0.05, 0.05)
			col = Color(clampf(col.r + jit, 0.0, 1.0), clampf(col.g + jit, 0.0, 1.0), clampf(col.b + jit, 0.0, 1.0))
			for py in range(j * tile + gap, j * tile + tile):
				for px in range(i * tile + gap, i * tile + tile):
					img.set_pixel(px, py, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


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

	# The altar of offerings, off the temple axis so the steps stay clear (and
	# clear of the west plaza column at (-5.25, -9.09)).
	world._place_glb(ALTAR, -4.6, -6.6, 2.2, 20.0, 1)
	# Bronze braziers flanking the steps.
	_brazier(world, -6.4, -10.6)
	_brazier(world, 6.4, -10.6)
	# Votive statues framing the approach.
	_statue(world, -11.6, -13.4, 200.0)
	_statue(world, 11.6, -13.4, 160.0)

	# Priestess Melite — the quest giver, by the altar.
	var priestess = NpcScript.create("priestess", "Priestess Melite",
		"res://assets/characters/oracle_priestess/oracle_priestess.glb",
		"res://assets/characters/oracle_priestess/oracle_priestess_animations.tres",
		Vector3(-7.4, 0.0, -5.8), 1.75, 130.0)
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


# ── East: the market row ─────────────────────────────────────────────────
static func _market_row(world) -> void:
	# Four awninged stalls facing west into the plaza (yaw 90 aims model -Z at -X).
	for z in [-6.2, -1.6, 3.0, 7.6]:
		world._place_glb(STALL, 15.6, float(z), 3.0, 90.0, 1)
	# Loaded carts and stacked amphorae make it read as a working agora.
	world._place_glb(CART, 12.9, -9.2, 1.4, 25.0, 1)
	world._place_glb(CART, 17.4, 0.8, 1.4, 200.0, 1)
	for p in [Vector2(13.1, -6.6), Vector2(13.8, -5.5), Vector2(17.2, -4.4),
			Vector2(13.3, 7.6), Vector2(17.4, 6.4), Vector2(13.6, 2.2)]:
		world._place_glb(AMPHORA, p.x, p.y, 0.9, randf() * 360.0, 1)


# ── West & perimeter: the stoa and the street edge ───────────────────────
static func _stoa_and_houses(world) -> void:
	# The stoa runs north-south along the west edge, its gallery facing the plaza.
	var stoa = world._place_glb(STOA, -17.6, 0.0, 7.0, 90.0, 0)
	if stoa != null:
		# One box on the visible footprint (14.3 x 5.6 m) — no interior hulls, so
		# nothing invisible reaches into the plaza.
		world._add_box_collider(stoa, Vector3(14.3, 7.0, 5.5),
			Vector3(0.0, 3.5, 0.0))

	# Five townhouses close the plaza off like a real street front. A townhouse
	# is a solid block, so the automatic tight box (tier 1) is exactly right.
	var houses := [
		[-25.5, -12.5, 8.0, 115.0],
		[-24.5, 12.2, 7.6, 65.0],
		[19.6, -17.6, 8.4, 205.0],
		[21.2, 13.6, 7.8, 300.0],
		[-9.6, 22.2, 8.0, 355.0],
	]
	for h in houses:
		world._place_glb(TOWNHOUSE, float(h[0]), float(h[1]), float(h[2]), float(h[3]), 1)
	world._place_glb(CART, -13.2, -9.4, 1.4, 160.0, 1)
	world._place_glb(AMPHORA, -13.4, 5.6, 0.9, 40.0, 1)
	world._place_glb(AMPHORA, -12.9, 6.5, 0.9, 210.0, 1)


# ── South: the city gate ─────────────────────────────────────────────────
static func _south_gate(world) -> void:
	var gate = world._place_glb(GATE_ARCH, 0.0, 26.0, 9.0, 0.0, 0)
	if gate != null:
		# Two piers only — the archway stays walkable (3.1 m clear opening).
		world._add_box_collider(gate, Vector3(3.1, 9.0, 2.8), Vector3(3.15, 4.5, 0.0))
		world._add_box_collider(gate, Vector3(3.1, 9.0, 2.8), Vector3(-3.15, 4.5, 0.0))
	_brazier(world, -4.8, 24.4)
	_brazier(world, 4.8, 24.4)


# ── South-east: the smith's yard ─────────────────────────────────────────
static func _smith_yard(world) -> void:
	world._place_glb(ANVIL, 10.6, 15.6, 1.1, 110.0, 1)
	_dummy(world, 13.4, 17.6, 15.0)
	_dummy(world, 12.2, 20.2, -25.0)
	world._place_glb(CART, 8.3, 19.4, 1.4, 40.0, 1)
	world._place_glb(AMPHORA, 9.0, 17.3, 0.9, 90.0, 1)
	world._place_glb(AMPHORA, 11.9, 19.8, 0.9, 300.0, 1)

	# Brontes the smith — refinement and wares.
	var smith = NpcScript.create("smith", "Brontes the Smith",
		"res://assets/characters/blacksmith_npc/blacksmith_npc.glb",
		"res://assets/characters/blacksmith_npc/blacksmith_npc_animations.tres",
		Vector3(9.4, 0.0, 14.2), 1.8, 150.0)
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


# ── Townsfolk ────────────────────────────────────────────────────────────
## Nine citizens: merchants at the stalls, neighbours gossiping by the fountain,
## guards on the gate and the temple steps. Decoration only — an idle clip each
## and one remark on E. Missing models are skipped silently.
const MERCHANT_GLB := "res://assets/characters/citizen_merchant/citizen_merchant.glb"
const MERCHANT_LIB := "res://assets/characters/citizen_merchant/citizen_merchant_animations.tres"
const WOMAN_GLB := "res://assets/characters/citizen_woman/citizen_woman.glb"
const WOMAN_LIB := "res://assets/characters/citizen_woman/citizen_woman_animations.tres"
const GUARD_GLB := "res://assets/characters/city_guard/city_guard.glb"
const GUARD_LIB := "res://assets/characters/city_guard/city_guard_animations.tres"

static func _townsfolk(world) -> void:
	var folk := [
		{"kind": "merchant", "name": "Hesiod the Oil Merchant",
			"at": Vector3(13.9, 0.0, -3.8), "yaw": 100.0, "idle": "ual2_Idle_FoldArms",
			"line": "Finest olive oil in Hellas — pressed this very morning!"},
		{"kind": "merchant", "name": "Kleon the Potter",
			"at": Vector3(13.9, 0.0, 5.4), "yaw": 80.0, "idle": "ual1_Idle",
			"line": "Amphorae, hero! Sturdy enough to outlive your grandchildren."},
		{"kind": "merchant", "name": "Xanthos the Fruit-Seller",
			"at": Vector3(17.0, 0.0, 9.8), "yaw": 130.0, "idle": "ual1_Idle_Talking",
			"line": "Figs, dates, honey cakes! Coin first, glory later."},
		{"kind": "woman", "name": "Thalia", "at": Vector3(2.9, 0.0, 3.2),
			"yaw": 205.0, "idle": "ual1_Idle_Talking",
			"line": "They say the priestess had another vision at dawn. Awful omens."},
		{"kind": "woman", "name": "Eirene", "at": Vector3(-2.6, 0.0, 4.6),
			"yaw": 25.0, "idle": "ual1_Idle_LookAround",
			"line": "The fountain runs cold as Boreas' breath. Blessed be Athena."},
		{"kind": "woman", "name": "Old Myrrine", "at": Vector3(-11.4, 0.0, 8.2),
			"yaw": 90.0, "idle": "ual1_Idle_LookAround",
			"line": "In my day the agora had twice the stalls. And better bread."},
		{"kind": "guard", "name": "Guard Lysandros", "at": Vector3(-3.4, 0.0, 22.0),
			"yaw": 0.0, "idle": "ual2_Idle_Rail",
			"line": "Wolves beyond that gate, and worse. Sharpen your spear first."},
		{"kind": "guard", "name": "Guard Nikanor", "at": Vector3(3.4, 0.0, 22.0),
			"yaw": 0.0, "idle": "ual1_Idle",
			"line": "The Minotaur's arena lies south. Nobody who goes comes back."},
		{"kind": "guard", "name": "Sentry Damon", "at": Vector3(-4.2, 0.0, -10.6),
			"yaw": 175.0, "idle": "ual2_Idle_Rail",
			"line": "Mind the sacred steps, stranger. Athena watches this square."},
	]
	var idx := 0
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
