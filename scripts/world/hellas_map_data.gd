extends RefCounted
## Shared Hellas layout: capitals, giant dens between them, boss arena.
## Used by game_world (spawns) and HUD map (M key).


const MAP_WORLD_SPAN: = 720.0 ## playable ~±340; leave margin

const CAPITALS: Array = [
	{
		"id": "athens", "name": "Athens", "empire": "athens",
		"pos": Vector2(0.0, 0.0), "r": 42.0,
		"col": Color(0.25, 0.45, 0.78, 0.92), "icon": "icon_laurel",
	},
	{
		"id": "sparta", "name": "Sparta", "empire": "sparta",
		"pos": Vector2(-240.0, 210.0), "r": 42.0,
		"col": Color(0.72, 0.2, 0.18, 0.92), "icon": "icon_shield",
	},
	{
		"id": "thebes", "name": "Thebes", "empire": "corinth",
		"pos": Vector2(240.0, -190.0), "r": 42.0,
		"col": Color(0.78, 0.62, 0.22, 0.92), "icon": "icon_laurel",
	},
]

const ARENA: Dictionary = {
	"name": "Minotaur's Arena", "pos": Vector2(0.0, 280.0), "r": 28.0,
	"col": Color(0.55, 0.12, 0.12, 0.9), "icon": "icon_skull",
}

## Giant dens sitting on the roads / marches between hostile capitals.
const DENS: Array = [
	{
		"id": "lykaon_den",
		"name": "Lykaon Wolf Den",
		"pos": Vector2(0.0, -95.0), "r": 38.0,
		"col": Color(0.45, 0.38, 0.22, 0.88), "icon": "icon_sword",
		"ids": [
			"wolf_enemy", "wolf_enemy", "wolf_enemy", "wolf_enemy",
			"wolf_black_enemy", "wolf_black_enemy", "wolf_dire_enemy", "wolf_dire_enemy",
			"boar_enemy", "boar_enemy", "boar_enemy",
		],
	},
	{
		"id": "centaur_march",
		"name": "Centaur March (Athens–Sparta)",
		"pos": Vector2(-130.0, 115.0), "r": 42.0,
		"col": Color(0.32, 0.4, 0.58, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_enemy", "centaur_enemy", "centaur_enemy", "centaur_enemy",
			"centaur_enemy", "gorgon_enemy", "gorgon_enemy", "gorgon_enemy",
			"wolf_dire_enemy", "boar_enemy", "boar_enemy", "harpy_enemy",
		],
	},
	{
		"id": "eurotas_lair",
		"name": "Eurotas Beast Lair",
		"pos": Vector2(-250.0, 265.0), "r": 40.0,
		"col": Color(0.5, 0.28, 0.22, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_enemy", "centaur_enemy", "centaur_enemy", "centaur_enemy",
			"gorgon_enemy", "gorgon_enemy", "wolf_dire_enemy", "wolf_black_enemy",
			"boar_enemy", "boar_enemy", "harpy_enemy", "satyr_enemy",
		],
	},
	{
		"id": "satyr_pass",
		"name": "Satyr Pass (Athens–Thebes)",
		"pos": Vector2(130.0, -105.0), "r": 42.0,
		"col": Color(0.34, 0.52, 0.28, 0.88), "icon": "icon_sword",
		"ids": [
			"satyr_enemy", "satyr_enemy", "satyr_enemy", "satyr_enemy", "satyr_enemy",
			"harpy_enemy", "harpy_enemy", "harpy_enemy", "harpy_enemy",
			"boar_enemy", "boar_enemy", "wolf_enemy", "gorgon_enemy",
		],
	},
	{
		"id": "cadmean_den",
		"name": "Cadmean Harpy Roost",
		"pos": Vector2(255.0, -255.0), "r": 40.0,
		"col": Color(0.4, 0.48, 0.28, 0.88), "icon": "icon_sword",
		"ids": [
			"harpy_enemy", "harpy_enemy", "harpy_enemy", "harpy_enemy",
			"satyr_enemy", "satyr_enemy", "satyr_enemy", "gorgon_enemy", "gorgon_enemy",
			"wolf_dire_enemy", "boar_enemy", "boar_enemy", "centaur_enemy",
		],
	},
	{
		"id": "isthmus_war_camp",
		"name": "Isthmus War Camp (crossroads)",
		"pos": Vector2(-15.0, 85.0), "r": 36.0,
		"col": Color(0.55, 0.35, 0.2, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_enemy", "centaur_enemy", "satyr_enemy", "satyr_enemy",
			"gorgon_enemy", "harpy_enemy", "harpy_enemy", "wolf_black_enemy",
			"wolf_dire_enemy", "boar_enemy", "boar_enemy",
		],
	},
	{
		"id": "arena_approach",
		"name": "Arena Approach",
		"pos": Vector2(0.0, 210.0), "r": 36.0,
		"col": Color(0.48, 0.22, 0.2, 0.88), "icon": "icon_skull",
		"ids": [
			"centaur_enemy", "centaur_enemy", "gorgon_enemy", "gorgon_enemy",
			"wolf_dire_enemy", "harpy_enemy", "satyr_enemy", "boar_enemy",
			"boar_enemy", "wolf_black_enemy",
		],
	},
	{
		"id": "west_boar_wallows",
		"name": "West Boar Wallows",
		"pos": Vector2(-90.0, -40.0), "r": 34.0,
		"col": Color(0.42, 0.36, 0.2, 0.85), "icon": "icon_sword",
		"ids": [
			"boar_enemy", "boar_enemy", "boar_enemy", "boar_enemy", "boar_enemy",
			"wolf_enemy", "wolf_enemy", "wolf_black_enemy", "satyr_enemy",
		],
	},
	## Mid / high chain dens (Melite trials → ~30).
	{
		"id": "isthmus_shore",
		"name": "Isthmus Shore",
		"pos": Vector2(-20.0, 140.0), "r": 40.0,
		"col": Color(0.28, 0.45, 0.7, 0.88), "icon": "icon_sword",
		"ids": [
			"siren_enemy", "siren_enemy", "siren_enemy", "siren_enemy", "siren_enemy",
			"harpy_enemy", "harpy_enemy", "harpy_enemy", "wolf_black_enemy",
		],
	},
	{
		"id": "serpent_hollow",
		"name": "Serpent Hollow",
		"pos": Vector2(300.0, -280.0), "r": 40.0,
		"col": Color(0.35, 0.6, 0.3, 0.88), "icon": "icon_sword",
		"ids": [
			"gorgon_matron", "gorgon_matron", "gorgon_matron", "gorgon_matron",
			"gorgon_enemy", "gorgon_enemy", "satyr_enemy", "harpy_enemy",
		],
	},
	{
		"id": "taygetus_ridge",
		"name": "Taygetus Ridge",
		"pos": Vector2(-300.0, 300.0), "r": 42.0,
		"col": Color(0.7, 0.35, 0.25, 0.88), "icon": "icon_sword",
		"ids": [
			"centaur_champion", "centaur_champion", "centaur_champion", "centaur_champion",
			"satyr_enemy", "satyr_enemy", "satyr_enemy", "centaur_enemy", "gorgon_enemy",
		],
	},
	{
		"id": "boreas_crags",
		"name": "Boreas Crags",
		"pos": Vector2(0.0, -220.0), "r": 40.0,
		"col": Color(0.55, 0.6, 0.78, 0.88), "icon": "icon_sword",
		"ids": [
			"harpy_matriarch", "harpy_matriarch", "harpy_matriarch", "harpy_matriarch",
			"harpy_matriarch", "harpy_enemy", "harpy_enemy", "siren_enemy",
		],
	},
	{
		"id": "acheron_gate",
		"name": "Acheron Gate",
		"pos": Vector2(180.0, 120.0), "r": 40.0,
		"col": Color(0.45, 0.15, 0.15, 0.9), "icon": "icon_sword",
		"ids": [
			"hellhound_enemy", "hellhound_enemy", "hellhound_enemy", "hellhound_enemy",
			"hellhound_enemy", "wolf_black_enemy", "wolf_black_enemy", "wolf_dire_enemy",
		],
	},
	{
		"id": "lerna_marsh",
		"name": "Lerna Marsh",
		"pos": Vector2(-180.0, -160.0), "r": 44.0,
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
		"pos": Vector2(220.0, 80.0), "r": 40.0,
		"col": Color(0.5, 0.45, 0.4, 0.88), "icon": "icon_sword",
		"ids": [
			"titan_thrall", "titan_thrall", "titan_thrall", "titan_thrall",
			"centaur_champion", "gorgon_matron", "hellhound_enemy",
		],
	},
	{
		"id": "olympus_approach",
		"name": "Olympus Approach",
		"pos": Vector2(0.0, -300.0), "r": 42.0,
		"col": Color(0.75, 0.65, 0.3, 0.9), "icon": "icon_laurel",
		"ids": [
			"olympian_shade", "olympian_shade", "olympian_shade", "olympian_shade",
			"centaur_champion", "centaur_champion", "harpy_matriarch", "titan_thrall",
		],
	},
]


static func zones_for_spawns() -> Array:
	## game_world ZONES shape: {c, r, ids}
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
	## Capitals + dens + arena for the M-key map.
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
