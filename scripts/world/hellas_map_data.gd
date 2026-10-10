extends RefCounted
## Shared Hellas layout: capitals, dens, roads, olive orchards.
## Used by game_world (spawns / props) and HUD map (M key).


const MAP_WORLD_SPAN: = 720.0 ## playable ~±340; leave margin

## Capitals form a wide triangle — not a NE/SW corridor.
const CAPITALS: Array = [
	{
		"id": "athens", "name": "Athens", "empire": "athens",
		"pos": Vector2(0.0, 0.0), "r": 42.0,
		"col": Color(0.25, 0.45, 0.78, 0.92), "icon": "icon_laurel",
	},
	{
		"id": "sparta", "name": "Sparta", "empire": "sparta",
		"pos": Vector2(-280.0, 200.0), "r": 42.0,
		"col": Color(0.72, 0.2, 0.18, 0.92), "icon": "icon_shield",
	},
	{
		"id": "thebes", "name": "Thebes", "empire": "corinth",
		"pos": Vector2(270.0, -180.0), "r": 42.0,
		"col": Color(0.78, 0.62, 0.22, 0.92), "icon": "icon_laurel",
	},
]

const ARENA: Dictionary = {
	"name": "Minotaur's Arena", "pos": Vector2(90.0, 290.0), "r": 28.0,
	"col": Color(0.55, 0.12, 0.12, 0.9), "icon": "icon_skull",
}

## Dens scattered across the whole playable disk (not one war-road line).
const DENS: Array = [
	{
		"id": "lykaon_den",
		"name": "Lykaon Wolf Den",
		"pos": Vector2(-90.0, -100.0), "r": 38.0,
		"col": Color(0.45, 0.38, 0.22, 0.88), "icon": "icon_sword",
		"ids": [
			"wolf_enemy", "wolf_enemy", "wolf_enemy", "wolf_enemy",
			"wolf_black_enemy", "wolf_black_enemy", "wolf_dire_enemy", "wolf_dire_enemy",
			"boar_enemy", "boar_enemy", "boar_enemy",
		],
	},
	{
		"id": "west_boar_wallows",
		"name": "West Boar Wallows",
		"pos": Vector2(-180.0, 30.0), "r": 34.0,
		"col": Color(0.42, 0.36, 0.2, 0.85), "icon": "icon_sword",
		"ids": [
			"boar_enemy", "boar_enemy", "boar_enemy", "boar_enemy", "boar_enemy",
			"wolf_enemy", "wolf_enemy", "wolf_black_enemy", "satyr_enemy",
		],
	},
	{
		"id": "satyr_pass",
		"name": "Satyr Pass (Athens–Thebes)",
		"pos": Vector2(120.0, -70.0), "r": 40.0,
		"col": Color(0.34, 0.52, 0.28, 0.88), "icon": "icon_sword",
		"ids": [
			"satyr_enemy", "satyr_enemy", "satyr_enemy", "satyr_enemy", "satyr_enemy",
			"harpy_enemy", "harpy_enemy", "harpy_enemy", "harpy_enemy",
			"boar_enemy", "boar_enemy", "wolf_enemy", "gorgon_enemy",
		],
	},
	{
		"id": "centaur_march",
		"name": "Centaur March (Athens–Sparta)",
		"pos": Vector2(-160.0, 120.0), "r": 42.0,
		"col": Color(0.32, 0.4, 0.58, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_enemy", "centaur_enemy", "centaur_enemy", "centaur_enemy",
			"centaur_enemy", "gorgon_enemy", "gorgon_enemy", "gorgon_enemy",
			"wolf_dire_enemy", "boar_enemy", "boar_enemy", "harpy_enemy",
		],
	},
	{
		"id": "isthmus_war_camp",
		"name": "Isthmus War Camp (crossroads)",
		"pos": Vector2(40.0, 110.0), "r": 36.0,
		"col": Color(0.55, 0.35, 0.2, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_enemy", "centaur_enemy", "satyr_enemy", "satyr_enemy",
			"gorgon_enemy", "harpy_enemy", "harpy_enemy", "wolf_black_enemy",
			"wolf_dire_enemy", "boar_enemy", "boar_enemy",
		],
	},
	{
		"id": "eurotas_lair",
		"name": "Eurotas Beast Lair",
		"pos": Vector2(-250.0, 280.0), "r": 40.0,
		"col": Color(0.5, 0.28, 0.22, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_enemy", "centaur_enemy", "centaur_enemy", "centaur_enemy",
			"gorgon_enemy", "gorgon_enemy", "wolf_dire_enemy", "wolf_black_enemy",
			"boar_enemy", "boar_enemy", "harpy_enemy", "satyr_enemy",
		],
	},
	{
		"id": "cadmean_den",
		"name": "Cadmean Harpy Roost",
		"pos": Vector2(290.0, -270.0), "r": 40.0,
		"col": Color(0.4, 0.48, 0.28, 0.88), "icon": "icon_sword",
		"ids": [
			"harpy_enemy", "harpy_enemy", "harpy_enemy", "harpy_enemy",
			"satyr_enemy", "satyr_enemy", "satyr_enemy", "gorgon_enemy", "gorgon_enemy",
			"wolf_dire_enemy", "boar_enemy", "boar_enemy", "centaur_enemy",
		],
	},
	{
		"id": "arena_approach",
		"name": "Arena Approach",
		"pos": Vector2(70.0, 230.0), "r": 36.0,
		"col": Color(0.48, 0.22, 0.2, 0.88), "icon": "icon_skull",
		"ids": [
			"centaur_enemy", "centaur_enemy", "gorgon_enemy", "gorgon_enemy",
			"wolf_dire_enemy", "harpy_enemy", "satyr_enemy", "boar_enemy",
			"boar_enemy", "wolf_black_enemy",
		],
	},
	{
		"id": "isthmus_shore",
		"name": "Isthmus Shore",
		"pos": Vector2(160.0, 200.0), "r": 40.0,
		"col": Color(0.28, 0.45, 0.7, 0.88), "icon": "icon_sword",
		"ids": [
			"siren_enemy", "siren_enemy", "siren_enemy", "siren_enemy", "siren_enemy",
			"harpy_enemy", "harpy_enemy", "harpy_enemy", "wolf_black_enemy",
		],
	},
	{
		"id": "serpent_hollow",
		"name": "Serpent Hollow",
		"pos": Vector2(310.0, -60.0), "r": 40.0,
		"col": Color(0.35, 0.6, 0.3, 0.88), "icon": "icon_sword",
		"ids": [
			"gorgon_matron", "gorgon_matron", "gorgon_matron", "gorgon_matron",
			"gorgon_enemy", "gorgon_enemy", "satyr_enemy", "harpy_enemy",
		],
	},
	{
		"id": "taygetus_ridge",
		"name": "Taygetus Ridge",
		"pos": Vector2(-310.0, 90.0), "r": 42.0,
		"col": Color(0.7, 0.35, 0.25, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_champion", "centaur_champion", "centaur_champion", "centaur_champion",
			"satyr_enemy", "satyr_enemy", "satyr_enemy", "centaur_enemy", "gorgon_enemy",
		],
	},
	{
		"id": "boreas_crags",
		"name": "Boreas Crags",
		"pos": Vector2(-120.0, -290.0), "r": 40.0,
		"col": Color(0.55, 0.6, 0.78, 0.88), "icon": "icon_sword",
		"ids": [
			"harpy_matriarch", "harpy_matriarch", "harpy_matriarch", "harpy_matriarch",
			"harpy_matriarch", "harpy_enemy", "harpy_enemy", "siren_enemy",
		],
	},
	{
		"id": "acheron_gate",
		"name": "Acheron Gate",
		"pos": Vector2(240.0, 140.0), "r": 40.0,
		"col": Color(0.45, 0.15, 0.15, 0.9), "icon": "icon_sword",
		"ids": [
			"hellhound_enemy", "hellhound_enemy", "hellhound_enemy", "hellhound_enemy",
			"hellhound_enemy", "wolf_black_enemy", "wolf_black_enemy", "wolf_dire_enemy",
		],
	},
	{
		"id": "lerna_marsh",
		"name": "Lerna Marsh",
		"pos": Vector2(-220.0, -180.0), "r": 44.0,
		"col": Color(0.22, 0.5, 0.28, 0.9), "icon": "icon_skull",
		"ids": [
			"hydra_boss",
			"gorgon_matron", "gorgon_matron", "satyr_enemy", "satyr_enemy",
			"hellhound_enemy", "boar_enemy", "boar_enemy",
		],
	},
	{
		"id": "ossa_foot",
		"name": "Ossa Foot",
		"pos": Vector2(200.0, -20.0), "r": 40.0,
		"col": Color(0.5, 0.45, 0.4, 0.88), "icon": "icon_sword",
		"ids": [
			"titan_thrall", "titan_thrall", "titan_thrall", "titan_thrall",
			"centaur_champion", "gorgon_matron", "hellhound_enemy",
		],
	},
	{
		"id": "olympus_approach",
		"name": "Olympus Approach",
		"pos": Vector2(40.0, -310.0), "r": 42.0,
		"col": Color(0.75, 0.65, 0.3, 0.9), "icon": "icon_laurel",
		"ids": [
			"olympian_shade", "olympian_shade", "olympian_shade", "olympian_shade",
			"centaur_champion", "centaur_champion", "harpy_matriarch", "titan_thrall",
		],
	},
]

## Ancient Greek / Roman-style road polylines (waypoints in XZ).
const ROADS: Array = [
	{
		"name": "Sacred Way (Athens–Sparta)",
		"pts": [
			Vector2(0.0, 0.0), Vector2(-80.0, 55.0), Vector2(-160.0, 120.0), Vector2(-280.0, 200.0),
		],
	},
	{
		"name": "Boeotian Road (Athens–Thebes)",
		"pts": [
			Vector2(0.0, 0.0), Vector2(70.0, -35.0), Vector2(120.0, -70.0),
			Vector2(200.0, -20.0), Vector2(270.0, -180.0),
		],
	},
	{
		"name": "Isthmus Road (Sparta–Thebes)",
		"pts": [
			Vector2(-280.0, 200.0), Vector2(-160.0, 120.0), Vector2(40.0, 110.0),
			Vector2(160.0, 200.0), Vector2(240.0, 140.0), Vector2(270.0, -180.0),
		],
	},
	{
		"name": "Arena Road",
		"pts": [
			Vector2(0.0, 0.0), Vector2(40.0, 110.0), Vector2(70.0, 230.0), Vector2(90.0, 290.0),
		],
	},
	{
		"name": "Northern Way (Boreas–Olympus)",
		"pts": [
			Vector2(0.0, 0.0), Vector2(-90.0, -100.0), Vector2(-120.0, -290.0), Vector2(40.0, -310.0),
		],
	},
	{
		"name": "Lerna Road",
		"pts": [
			Vector2(0.0, 0.0), Vector2(-180.0, 30.0), Vector2(-220.0, -180.0),
		],
	},
	{
		"name": "Taygetus Spur",
		"pts": [
			Vector2(-280.0, 200.0), Vector2(-310.0, 90.0),
		],
	},
	{
		"name": "Cadmean Spur",
		"pts": [
			Vector2(270.0, -180.0), Vector2(290.0, -270.0),
		],
	},
	{
		"name": "Serpent Spur",
		"pts": [
			Vector2(270.0, -180.0), Vector2(310.0, -60.0),
		],
	},
	{
		"name": "Eurotas Spur",
		"pts": [
			Vector2(-280.0, 200.0), Vector2(-250.0, 280.0),
		],
	},
]

## Small olive orchards + lone cypress clumps — Mediterranean spacing, not forest.
const OLIVE_ORCHARDS: Array = [
	{"c": Vector2(55.0, -45.0), "r": 12.0, "count": 5, "seed": 11, "kind": "olive"},
	{"c": Vector2(-70.0, 40.0), "r": 11.0, "count": 4, "seed": 17, "kind": "olive"},
	{"c": Vector2(95.0, 55.0), "r": 13.0, "count": 5, "seed": 23, "kind": "olive"},
	{"c": Vector2(-140.0, -60.0), "r": 12.0, "count": 4, "seed": 29, "kind": "olive"},
	{"c": Vector2(150.0, -140.0), "r": 14.0, "count": 6, "seed": 31, "kind": "olive"},
	{"c": Vector2(-200.0, 160.0), "r": 12.0, "count": 5, "seed": 37, "kind": "olive"},
	{"c": Vector2(210.0, -220.0), "r": 11.0, "count": 4, "seed": 41, "kind": "olive"},
	{"c": Vector2(-50.0, 180.0), "r": 12.0, "count": 4, "seed": 43, "kind": "olive"},
	{"c": Vector2(30.0, -170.0), "r": 13.0, "count": 5, "seed": 47, "kind": "olive"},
	{"c": Vector2(-250.0, -40.0), "r": 11.0, "count": 4, "seed": 53, "kind": "olive"},
	{"c": Vector2(180.0, 80.0), "r": 12.0, "count": 5, "seed": 59, "kind": "olive"},
	{"c": Vector2(-100.0, 250.0), "r": 10.0, "count": 3, "seed": 61, "kind": "olive"},
	{"c": Vector2(100.0, -250.0), "r": 11.0, "count": 4, "seed": 67, "kind": "olive"},
	{"c": Vector2(-300.0, 160.0), "r": 10.0, "count": 3, "seed": 71, "kind": "olive"},
	{"c": Vector2(250.0, 40.0), "r": 12.0, "count": 4, "seed": 73, "kind": "olive"},
	{"c": Vector2(-40.0, -240.0), "r": 10.0, "count": 3, "seed": 79, "kind": "cypress"},
	{"c": Vector2(130.0, 150.0), "r": 9.0, "count": 3, "seed": 83, "kind": "cypress"},
	{"c": Vector2(-170.0, -140.0), "r": 10.0, "count": 3, "seed": 89, "kind": "cypress"},
	{"c": Vector2(60.0, 260.0), "r": 9.0, "count": 2, "seed": 97, "kind": "cypress"},
	{"c": Vector2(-220.0, 240.0), "r": 10.0, "count": 3, "seed": 101, "kind": "cypress"},
]


static func zones_for_spawns() -> Array:
	var out: Array = []
	for d in DENS:
		out.append({
			"c": d["pos"],
			"r": d["r"],
			"ids": d["ids"],
			"name": d["name"],
		})
	return out


static func map_regions() -> Array:
	var out: Array = []
	for c in CAPITALS:
		out.append({
			"name": String(c["name"]),
			"pos": c["pos"],
			"r": c["r"],
			"col": c["col"],
			"icon": c["icon"],
			"kind": "capital",
		})
	for d in DENS:
		out.append({
			"name": String(d["name"]),
			"pos": d["pos"],
			"r": float(d["r"]),
			"col": d["col"],
			"icon": d["icon"],
			"kind": "den",
		})
	out.append({
		"name": String(ARENA["name"]),
		"pos": ARENA["pos"],
		"r": float(ARENA["r"]),
		"col": ARENA["col"],
		"icon": ARENA["icon"],
		"kind": "boss",
	})
	return out


static func capital_for_empire(empire_id: String) -> Dictionary:
	for c in CAPITALS:
		if String(c.get("empire", "")) == empire_id:
			return c
	return CAPITALS[0]


static func city_defs() -> Array:
	## game_world CITIES shape with themes / mosaic flag.
	return [
		{"id": "athens", "empire": "athens", "c": CAPITALS[0]["pos"], "theme": "athens", "mosaic": true},
		{"id": "sparta", "empire": "sparta", "c": CAPITALS[1]["pos"], "theme": "sparta", "mosaic": false},
		{"id": "thebes", "empire": "corinth", "c": CAPITALS[2]["pos"], "theme": "thebes", "mosaic": false},
	]


static func road_segment_samples(step_m: float = 3.0) -> Array:
	## Flat list of {pos, yaw, road} along every road for splat / mesh placement.
	var out: Array = []
	for road in ROADS:
		var pts: Array = road["pts"]
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var seg_len: float = a.distance_to(b)
			var n: int = maxi(1, int(ceil(seg_len / step_m)))
			var yaw: float = atan2(-(b.x - a.x), -(b.y - a.y))
			for s in n + 1:
				var t: float = float(s) / float(n)
				out.append({
					"pos": a.lerp(b, t),
					"yaw": yaw,
					"name": String(road.get("name", "")),
				})
	return out


static func dist_to_nearest_road(p: Vector2) -> float:
	var best: = INF
	for road in ROADS:
		var pts: Array = road["pts"]
		for i in pts.size() - 1:
			best = minf(best, _dist_point_segment(p, pts[i], pts[i + 1]))
	return best


static func _dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: = b - a
	var len_sq: = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t: = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)
