extends Node
## GameState — persistent RPG state: empire, class, level, gold, inventory,
## refinement, quests, clan. Autoload. All systems read/write through here.

signal stats_changed
signal gold_changed(new_gold: int)
signal xp_changed(new_xp: int, xp_needed: int, level: int)
signal level_up(new_level: int)
signal inventory_changed
signal weapon_refined(new_level: int)
signal quest_advanced(quest_id: String, step: int)
signal clan_changed
signal potions_changed

# ── Empires ──────────────────────────────────────────────────────────────
const EMPIRES := {
	"sparta": {
		"name": "Sparta",
		"desc": "Honor through steel. The phalanx never breaks.",
		"bonus_desc": "+15% physical damage, +10% defense",
		"dmg_mult": 1.15, "def_mult": 1.10, "spell_mult": 1.0,
		"gold_mult": 1.0, "speed_mult": 1.0,
		"color": Color(0.62, 0.16, 0.16),
	},
	"athens": {
		"name": "Athens",
		"desc": "Wisdom is the sharpest blade.",
		"bonus_desc": "+20% skill power, faster mana flow",
		"dmg_mult": 1.0, "def_mult": 1.0, "spell_mult": 1.20,
		"gold_mult": 1.0, "speed_mult": 1.0, "mana_regen": 1.5,
		"color": Color(0.20, 0.38, 0.62),
	},
	"corinth": {
		"name": "Corinth",
		"desc": "Gold flows where Corinthian ships sail.",
		"bonus_desc": "+25% gold, +10% move speed",
		"dmg_mult": 1.0, "def_mult": 1.0, "spell_mult": 1.0,
		"gold_mult": 1.25, "speed_mult": 1.10,
		"color": Color(0.72, 0.58, 0.24),
	},
}

# ── Classes ──────────────────────────────────────────────────────────────
const CLASSES := {
	"hoplite": {
		"name": "Hoplite",
		"desc": "Spear and shield. A wall of bronze that strikes back.",
		"weapon": "res://assets/props/weapons/dory_spear.glb",
		"weapon_name": "Dory Spear",
		"base_dmg": 14.0, "base_hp": 130, "base_mp": 60,
		"attack_range": 3.2, "attack_arc": 1.9,
		"skill_name": "Spear of Achilles",
		"skill_desc": "A devastating thrust that pierces all foes before you.",
		"skill_mp": 25, "skill_mult": 2.6, "skill_cd": 8.0,
		"ranged": false,
	},
	"toxotes": {
		"name": "Toxotes",
		"desc": "Cretan bow. Death arrives before the whisper of the string.",
		"weapon": "res://assets/props/weapons/cretan_bow.glb",
		"weapon_name": "Cretan Bow",
		"base_dmg": 11.0, "base_hp": 100, "base_mp": 80,
		"attack_range": 22.0, "attack_arc": 0.5,
		"skill_name": "Artemis Volley",
		"skill_desc": "Loose a fan of five arrows blessed by the Huntress.",
		"skill_mp": 30, "skill_mult": 1.4, "skill_cd": 9.0,
		"ranged": true, "projectile_speed": 26.0,
	},
	"magos": {
		"name": "Magos",
		"desc": "Theurgist of storm and shadow. Olympus answers his call.",
		"weapon": "res://assets/props/weapons/theurgist_staff.glb",
		"weapon_name": "Theurgist Staff",
		"base_dmg": 12.0, "base_hp": 90, "base_mp": 110,
		"attack_range": 18.0, "attack_arc": 0.6,
		"skill_name": "Zeus's Thunderbolt",
		"skill_desc": "Call down heaven's wrath in a burst of divine lightning.",
		"skill_mp": 35, "skill_mult": 3.0, "skill_cd": 10.0,
		"ranged": true, "projectile_speed": 20.0,
	},
}

# ── Tempering (Olympian forge gamble) ────────────────────────────────────
# Hephaestus's forge table: chance to raise a weapon from +N to +(N+1).
const REFINE_BASE_RATES := [0.95, 0.90, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.30]
const REFINE_MAX := 9
const REFINE_GOLD_COST := [20, 35, 55, 85, 130, 200, 320, 500, 800]
# Damage multiplier per temper level.
const REFINE_DMG_BONUS := 0.12

const SCROLLS := {
	"hephaestus": {
		"name": "Papyrus of Hephaestus",
		"desc": "Tempers at the base forge rate. The honest hammer.",
		"price": 60,
	},
	"titan": {
		"name": "Titan's Ember",
		"desc": "Locks temper chance at a fixed 75%. Titan-forged certainty.",
		"price": 150,
	},
	"oracle": {
		"name": "Pythia's Ward",
		"desc": "Failure cannot downgrade or shatter the weapon.",
		"price": 220,
	},
}

# ── Item catalog (Diablo/PoE-style grid footprints + vendor sell prices) ──
# Sell prices sit well below buy prices (~30–40% for shop goods; loot trash
# lands in the ~15–200 gold band, matching early-Act Diablo vendor trash).
# Weapons / spears / bows occupy 1×2 cells; helmets, shields, potions, mats,
# scrolls occupy 1×1.
const BAG_W := 6
const BAG_H := 6

const ITEM_DEFS := {
	"health_potion": {
		"name": "Health Potion", "desc": "Restores 60 HP.", "kind": "consumable",
		"w": 1, "h": 1, "stackable": true, "price": 25, "sell": 10,
		"icon": "res://assets/ui/icon_potion.png", "glb": "",
		"color": Color(0.75, 0.18, 0.22),
	},
	"mana_potion": {
		"name": "Mana Potion", "desc": "Restores 40 MP.", "kind": "consumable",
		"w": 1, "h": 1, "stackable": true, "price": 25, "sell": 10,
		"icon": "res://assets/ui/icon_mana.png", "glb": "",
		"color": Color(0.22, 0.35, 0.78),
	},
	"hephaestus": {
		"name": "Papyrus of Hephaestus", "desc": "Tempers at the base forge rate.",
		"kind": "scroll", "w": 1, "h": 1, "stackable": true, "price": 60, "sell": 22,
		"icon": "res://assets/ui/icon_scroll.png", "glb": "",
		"color": Color(0.72, 0.55, 0.25),
	},
	"titan": {
		"name": "Titan's Ember", "desc": "Locks temper chance at a fixed 75%.",
		"kind": "scroll", "w": 1, "h": 1, "stackable": true, "price": 150, "sell": 55,
		"icon": "res://assets/ui/icon_gem.png", "glb": "",
		"color": Color(0.55, 0.35, 0.75),
	},
	"oracle": {
		"name": "Pythia's Ward", "desc": "Failure cannot downgrade or shatter the blade.",
		"kind": "scroll", "w": 1, "h": 1, "stackable": true, "price": 220, "sell": 80,
		"icon": "res://assets/ui/icon_scroll.png", "glb": "",
		"color": Color(0.35, 0.65, 0.55),
	},
	"mat_wolf_pelt": {
		"name": "Wolf Pelt", "desc": "Rough hide from a wild wolf.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 18,
		"icon": "res://assets/ui/items/icon_mat_wolf_pelt.png", "glb": "",
		"color": Color(0.45, 0.38, 0.32),
	},
	"mat_boar_tusk": {
		"name": "Boar Tusk", "desc": "Curved ivory from a boar.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 28,
		"icon": "res://assets/ui/items/icon_mat_boar_tusk.png", "glb": "",
		"color": Color(0.82, 0.76, 0.62),
	},
	"mat_satyr_horn": {
		"name": "Satyr Horn", "desc": "Trophy of a vineyard raider.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 42,
		"icon": "res://assets/ui/items/icon_mat_satyr_horn.png", "glb": "",
		"color": Color(0.55, 0.42, 0.22),
	},
	"mat_harpy_feather": {
		"name": "Harpy Feather", "desc": "Iridescent wing feather.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 48,
		"icon": "res://assets/ui/items/icon_mat_harpy_feather.png", "glb": "",
		"color": Color(0.55, 0.62, 0.78),
	},
	"mat_centaur_hoof": {
		"name": "Centaur Hoof", "desc": "Hardened hoof of a warrior.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 85,
		"icon": "res://assets/ui/items/icon_mat_centaur_hoof.png", "glb": "",
		"color": Color(0.35, 0.28, 0.22),
	},
	"mat_gorgon_venom": {
		"name": "Gorgon Venom", "desc": "Vial of petrifying venom.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 110,
		"icon": "res://assets/ui/icon_gem.png", "glb": "",
		"color": Color(0.25, 0.65, 0.35),
	},
	"mat_minotaur_horn": {
		"name": "Minotaur Horn", "desc": "Horn of the Labyrinth beast.",
		"kind": "material", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 180,
		"icon": "res://assets/ui/icon_skull.png", "glb": "",
		"color": Color(0.55, 0.18, 0.15),
	},
	"xiphos": {
		"name": "Xiphos", "desc": "Short leaf-blade sword. Vendor trash or trophy.",
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 240, "sell": 110,
		"icon": "res://assets/ui/items/icon_xiphos.png",
		"glb": "res://assets/props/gear/xiphos_sword.glb",
		"color": Color(0.7, 0.72, 0.78),
	},
	"bronze_knife": {
		"name": "Bronze Machaira", "desc": "Curved fighting knife.",
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 90, "sell": 45,
		"icon": "res://assets/ui/items/icon_machaira.png",
		"glb": "res://assets/props/gear/xiphos_sword.glb",
		"color": Color(0.72, 0.52, 0.28),
	},
	"kontos": {
		"name": "Kontos Lance", "desc": "Long cavalry spear.",
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 280, "sell": 130,
		"icon": "res://assets/ui/items/icon_kontos.png",
		"glb": "res://assets/props/gear/kontos_spear.glb",
		"color": Color(0.62, 0.55, 0.4),
	},
	"hunting_bow": {
		"name": "Cretan Bow", "desc": "Hunting bow recovered from the wilds.",
		"kind": "weapon", "w": 1, "h": 2, "stackable": false, "price": 210, "sell": 95,
		"icon": "res://assets/ui/items/icon_bow.png",
		"glb": "res://assets/props/weapons/cretan_bow.glb",
		"color": Color(0.45, 0.32, 0.2),
	},
	"aspis": {
		"name": "Aspis (Hoplon)", "desc": "Round bronze-rimmed shield.",
		"kind": "shield", "w": 1, "h": 1, "stackable": false, "price": 180, "sell": 85,
		"icon": "res://assets/ui/items/icon_aspis.png",
		"glb": "res://assets/props/gear/aspis_shield.glb",
		"color": Color(0.75, 0.55, 0.2),
	},
	"tower_shield": {
		"name": "Tower Aspis", "desc": "Heavy rectangular shield.",
		"kind": "shield", "w": 1, "h": 1, "stackable": false, "price": 320, "sell": 150,
		"icon": "res://assets/ui/items/icon_tower_shield.png",
		"glb": "res://assets/props/gear/tower_shield.glb",
		"color": Color(0.55, 0.45, 0.3),
	},
	"corinthian_helm": {
		"name": "Corinthian Helmet", "desc": "Bronze helm with crest.",
		"kind": "helmet", "w": 1, "h": 1, "stackable": false, "price": 200, "sell": 100,
		"icon": "res://assets/ui/items/icon_corinthian_helm.png",
		"glb": "res://assets/props/gear/corinthian_helmet.glb",
		"color": Color(0.78, 0.58, 0.22),
	},
	"leather_cuirass": {
		"name": "Leather Cuirass", "desc": "Boiled-leather torso armor.",
		"kind": "armor", "w": 1, "h": 1, "stackable": false, "price": 160, "sell": 70,
		"icon": "res://assets/ui/items/icon_leather_cuirass.png", "glb": "",
		"color": Color(0.42, 0.28, 0.18),
	},
	"bronze_thorax": {
		"name": "Bronze Thorax", "desc": "Muscle cuirass of polished bronze.",
		"kind": "armor", "w": 1, "h": 1, "stackable": false, "price": 380, "sell": 175,
		"icon": "res://assets/ui/items/icon_bronze_thorax.png", "glb": "",
		"color": Color(0.7, 0.5, 0.22),
		"min_level": 8,
	},
	"leather_boots": {
		"name": "Leather Sandals", "desc": "Traveler's boots bound with rawhide.",
		"kind": "boots", "w": 1, "h": 1, "stackable": false, "price": 70, "sell": 30,
		"icon": "res://assets/ui/items/icon_leather_sandals.png", "glb": "",
		"color": Color(0.48, 0.32, 0.18),
		"min_level": 1, "def": 2.0, "hp": 4.0,
	},
	"bronze_greaves": {
		"name": "Bronze Greaves", "desc": "Shin-guards of hammered bronze.",
		"kind": "boots", "w": 1, "h": 1, "stackable": false, "price": 190, "sell": 85,
		"icon": "res://assets/ui/items/icon_bronze_greaves.png", "glb": "",
		"color": Color(0.72, 0.52, 0.24),
		"min_level": 5, "def": 5.0, "hp": 10.0,
	},
	"olive_necklace": {
		"name": "Olive Pendant", "desc": "Athena's leaf on a leather cord.",
		"kind": "necklace", "w": 1, "h": 1, "stackable": false, "price": 120, "sell": 50,
		"icon": "res://assets/ui/items/icon_olive_necklace.png", "glb": "",
		"color": Color(0.55, 0.7, 0.35),
		"min_level": 2, "hp": 12.0, "atk": 1.0,
	},
	"gold_torque": {
		"name": "Gold Torque", "desc": "Heavy neck-ring of beaten gold.",
		"kind": "necklace", "w": 1, "h": 1, "stackable": false, "price": 340, "sell": 150,
		"icon": "res://assets/ui/items/icon_gold_torque.png", "glb": "",
		"color": Color(0.9, 0.75, 0.28),
		"min_level": 8, "hp": 22.0, "atk": 3.0,
	},
	"bronze_earring": {
		"name": "Bronze Earring", "desc": "A soldier's simple bronze hoop.",
		"kind": "earring", "w": 1, "h": 1, "stackable": false, "price": 55, "sell": 22,
		"icon": "res://assets/ui/items/icon_bronze_earring.png", "glb": "",
		"color": Color(0.7, 0.5, 0.25),
		"min_level": 1, "atk": 1.5,
	},
	"silver_earring": {
		"name": "Silver Earring", "desc": "Temple silver, cold to the touch.",
		"kind": "earring", "w": 1, "h": 1, "stackable": false, "price": 160, "sell": 70,
		"icon": "res://assets/ui/items/icon_silver_earring.png", "glb": "",
		"color": Color(0.78, 0.8, 0.85),
		"min_level": 5, "atk": 3.0, "hp": 6.0,
	},
	"leather_bracelet": {
		"name": "Leather Bracelet", "desc": "Wrist-wrap for a spearman.",
		"kind": "bracelet", "w": 1, "h": 1, "stackable": false, "price": 45, "sell": 18,
		"icon": "res://assets/ui/items/icon_leather_bracelet.png", "glb": "",
		"color": Color(0.5, 0.35, 0.2),
		"min_level": 1, "def": 1.5,
	},
	"bronze_bracelet": {
		"name": "Bronze Bracelet", "desc": "Coiled bronze for the sword-arm.",
		"kind": "bracelet", "w": 1, "h": 1, "stackable": false, "price": 140, "sell": 60,
		"icon": "res://assets/ui/items/icon_bronze_bracelet.png", "glb": "",
		"color": Color(0.68, 0.48, 0.22),
		"min_level": 4, "def": 3.0, "atk": 1.5,
	},
	"gold_coin": {
		"name": "Drachmae", "desc": "Loose coins from a fallen foe.",
		"kind": "gold", "w": 1, "h": 1, "stackable": true, "price": 0, "sell": 0,
		"icon": "res://assets/ui/icon_gold.png", "glb": "",
		"color": Color(1.0, 0.84, 0.28),
	},
}

## Shop catalogue kept for Brontes (buy prices only).
const SHOP_ITEMS := {
	"health_potion": {"name": "Health Potion", "desc": "Restores 60 HP.", "price": 25, "icon": "res://assets/ui/icon_potion.png"},
	"mana_potion": {"name": "Mana Potion", "desc": "Restores 40 MP.", "price": 25, "icon": "res://assets/ui/icon_mana.png"},
	"hephaestus": {"name": "Papyrus of Hephaestus", "desc": "Tempers at the base forge rate.", "price": 60, "icon": "res://assets/ui/icon_scroll.png"},
	"titan": {"name": "Titan's Ember", "desc": "Locks temper chance at a fixed 75%.", "price": 150, "icon": "res://assets/ui/icon_gem.png"},
	"oracle": {"name": "Pythia's Ward", "desc": "Failure cannot downgrade or shatter the blade.", "price": 220, "icon": "res://assets/ui/icon_scroll.png"},
}

## Enemy material display name → bag item id.
const MATERIAL_ITEM := {
	"Wolf Pelt": "mat_wolf_pelt",
	"Boar Tusk": "mat_boar_tusk",
	"Satyr Horn": "mat_satyr_horn",
	"Harpy Feather": "mat_harpy_feather",
	"Centaur Hoof": "mat_centaur_hoof",
	"Gorgon Venom": "mat_gorgon_venom",
	"Minotaur Horn": "mat_minotaur_horn",
}

## Weighted ground-gear table. `min_level` gates drops to foe strength (Metin2-ish).
const LOOT_TABLE := [
	{"id": "bronze_knife", "weight": 22, "min_level": 1},
	{"id": "leather_boots", "weight": 18, "min_level": 1},
	{"id": "bronze_earring", "weight": 16, "min_level": 1},
	{"id": "leather_bracelet", "weight": 16, "min_level": 1},
	{"id": "leather_cuirass", "weight": 12, "min_level": 2},
	{"id": "olive_necklace", "weight": 10, "min_level": 2},
	{"id": "aspis", "weight": 12, "min_level": 3},
	{"id": "xiphos", "weight": 10, "min_level": 3},
	{"id": "hunting_bow", "weight": 9, "min_level": 3},
	{"id": "corinthian_helm", "weight": 9, "min_level": 4},
	{"id": "bronze_bracelet", "weight": 8, "min_level": 4},
	{"id": "bronze_greaves", "weight": 8, "min_level": 5},
	{"id": "silver_earring", "weight": 7, "min_level": 5},
	{"id": "kontos", "weight": 6, "min_level": 6},
	{"id": "tower_shield", "weight": 5, "min_level": 7},
	{"id": "bronze_thorax", "weight": 4, "min_level": 8},
	{"id": "gold_torque", "weight": 3, "min_level": 8},
]

# ── Runtime state ────────────────────────────────────────────────────────
var empire: String = "sparta"
var player_class: String = "hoplite"
var player_name: String = "Champion"

var level: int = 1
var xp: int = 0
var gold: int = 50
var weapon_refine: int = 0

var health_potions: int = 3
var mana_potions: int = 2
var scrolls: Dictionary = {"hephaestus": 1, "titan": 0, "oracle": 0}

# Materials looted from monsters (mirrors bag stacks for quest/UI flavor).
var materials: Dictionary = {}

## Bag entries: {id, count, x, y}. Footprints may span multiple cells.
var bag: Array = []

## Equipped gear — Metin2-style paperdoll (helm, armor, weapon, shield,
## boots, necklace, earring, bracelet). Values are item ids or "".
var equipped: Dictionary = {
	"helmet": "",
	"armor": "",
	"weapon": "",
	"shield": "",
	"boots": "",
	"necklace": "",
	"earring": "",
	"bracelet": "",
}

# Quest chain state.
var quest_index: int = 0
var quest_kills: Dictionary = {}
var omphaloi_destroyed: int = 0
var minotaur_slain: bool = false

# Clan.
var clan_name: String = ""
var clan_rank: String = ""

func _ready() -> void:
	_seed_starter_bag()

func xp_needed() -> int:
	return 60 + (level - 1) * 45 + (level - 1) * (level - 1) * 6

func reset_run() -> void:
	level = 1
	xp = 0
	gold = 50
	weapon_refine = 0
	health_potions = 0
	mana_potions = 0
	scrolls = {"hephaestus": 0, "titan": 0, "oracle": 0}
	materials = {}
	bag.clear()
	equipped = {
		"helmet": "", "armor": "", "weapon": "", "shield": "",
		"boots": "", "necklace": "", "earring": "", "bracelet": "",
	}
	quest_index = 0
	quest_kills = {}
	omphaloi_destroyed = 0
	minotaur_slain = false
	clan_name = ""
	clan_rank = ""
	_seed_starter_bag()
	stats_changed.emit()
	inventory_changed.emit()
	potions_changed.emit()


## Serializable run snapshot for local / cloud saves (v1).
func to_save_dict() -> Dictionary:
	var bag_copy: Array = []
	for e in bag:
		if typeof(e) == TYPE_DICTIONARY:
			bag_copy.append({
				"id": String(e.get("id", "")),
				"count": int(e.get("count", 1)),
				"x": int(e.get("x", 0)),
				"y": int(e.get("y", 0)),
			})
	var eq := {}
	for k in equipped:
		eq[String(k)] = String(equipped[k])
	var qk := {}
	for k in quest_kills:
		qk[String(k)] = int(quest_kills[k])
	return {
		"v": 1,
		"empire": empire,
		"player_class": player_class,
		"player_name": player_name,
		"level": level,
		"xp": xp,
		"gold": gold,
		"weapon_refine": weapon_refine,
		"bag": bag_copy,
		"equipped": eq,
		"quest_index": quest_index,
		"quest_kills": qk,
		"omphaloi_destroyed": omphaloi_destroyed,
		"minotaur_slain": minotaur_slain,
		"clan_name": clan_name,
		"clan_rank": clan_rank,
	}


## Apply a save snapshot. Does not seed starter loot.
func apply_save_dict(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	empire = String(data.get("empire", empire))
	player_class = String(data.get("player_class", player_class))
	player_name = String(data.get("player_name", player_name))
	level = maxi(1, int(data.get("level", 1)))
	xp = maxi(0, int(data.get("xp", 0)))
	gold = maxi(0, int(data.get("gold", 0)))
	weapon_refine = maxi(0, int(data.get("weapon_refine", 0)))
	bag.clear()
	var raw_bag = data.get("bag", [])
	if typeof(raw_bag) == TYPE_ARRAY:
		for e in raw_bag:
			if typeof(e) != TYPE_DICTIONARY:
				continue
			var id := String(e.get("id", ""))
			if id == "":
				continue
			bag.append({
				"id": id,
				"count": maxi(1, int(e.get("count", 1))),
				"x": int(e.get("x", 0)),
				"y": int(e.get("y", 0)),
			})
	equipped = {
		"helmet": "", "armor": "", "weapon": "", "shield": "",
		"boots": "", "necklace": "", "earring": "", "bracelet": "",
	}
	var raw_eq = data.get("equipped", {})
	if typeof(raw_eq) == TYPE_DICTIONARY:
		for k in equipped.keys():
			if raw_eq.has(k):
				equipped[k] = String(raw_eq[k])
	quest_index = maxi(0, int(data.get("quest_index", 0)))
	quest_kills = {}
	var raw_qk = data.get("quest_kills", {})
	if typeof(raw_qk) == TYPE_DICTIONARY:
		for k in raw_qk:
			quest_kills[String(k)] = int(raw_qk[k])
	omphaloi_destroyed = maxi(0, int(data.get("omphaloi_destroyed", 0)))
	minotaur_slain = bool(data.get("minotaur_slain", false))
	clan_name = String(data.get("clan_name", ""))
	clan_rank = String(data.get("clan_rank", ""))
	_resync_derived_counts()
	stats_changed.emit()
	inventory_changed.emit()
	potions_changed.emit()
	var q := current_quest()
	quest_advanced.emit(String(q.get("id", "")), quest_index)
	clan_changed.emit()
	return true


func _seed_starter_bag() -> void:
	bag.clear()
	try_add_to_bag("health_potion", 3)
	try_add_to_bag("mana_potion", 2)
	try_add_to_bag("hephaestus", 1)
	## Traveler's sandals — drag onto the Boots panoply slot.
	try_add_to_bag("leather_boots", 1)
	_resync_derived_counts()

func empire_data() -> Dictionary:
	return EMPIRES.get(empire, EMPIRES["sparta"])

func class_data() -> Dictionary:
	return CLASSES.get(player_class, CLASSES["hoplite"])

# ── Combat math ──────────────────────────────────────────────────────────
func attack_damage() -> float:
	var cd := class_data()
	var base: float = cd["base_dmg"] * (1.0 + weapon_refine * REFINE_DMG_BONUS)
	base *= 1.0 + (level - 1) * 0.08
	if cd["ranged"] and player_class == "magos":
		base *= empire_data().get("spell_mult", 1.0)
	else:
		base *= empire_data().get("dmg_mult", 1.0)
	base += _equip_stat("atk")
	return base

func skill_damage() -> float:
	var cd := class_data()
	var d: float = attack_damage() * cd["skill_mult"] * empire_data().get("spell_mult", 1.0)
	return d

func max_hp() -> int:
	return int(class_data()["base_hp"] + (level - 1) * 14 + _equip_stat("hp"))

func max_mp() -> int:
	return int(class_data()["base_mp"] + (level - 1) * 8)

func damage_taken_mult() -> float:
	var def_bonus: float = 1.0 + _equip_stat("def") * 0.01
	return 1.0 / (empire_data().get("def_mult", 1.0) * def_bonus)

func move_speed_mult() -> float:
	return empire_data().get("speed_mult", 1.0)

func mana_regen_mult() -> float:
	return empire_data().get("mana_regen", 1.0)

# ── XP / gold ────────────────────────────────────────────────────────────
func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		level_up.emit(level)
	xp_changed.emit(xp, xp_needed(), level)
	stats_changed.emit()

func add_gold(amount: int) -> void:
	gold += int(amount * empire_data().get("gold_mult", 1.0))
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# ── Inventory / bag grid ─────────────────────────────────────────────────

func item_def(item_id: String) -> Dictionary:
	var d: Dictionary = ITEM_DEFS.get(item_id, {})
	if d.is_empty():
		return {"id": item_id, "name": item_id, "kind": "junk", "w": 1, "h": 1,
			"stackable": true, "price": 0, "sell": 5, "icon": "", "glb": "",
			"color": Color(0.7, 0.7, 0.7)}
	var out := d.duplicate()
	out["id"] = item_id
	return out


func item_name(item_id: String) -> String:
	return String(item_def(item_id).get("name", item_id))


func item_cells(item_id: String) -> Vector2i:
	var d := item_def(item_id)
	return Vector2i(int(d.get("w", 1)), int(d.get("h", 1)))


func item_sell_price(item_id: String) -> int:
	return int(item_def(item_id).get("sell", 5))


func bag_count(item_id: String) -> int:
	var n := 0
	for e in bag:
		if String(e.get("id", "")) == item_id:
			n += int(e.get("count", 1))
	return n


func _resync_derived_counts() -> void:
	health_potions = bag_count("health_potion")
	mana_potions = bag_count("mana_potion")
	for sid in SCROLLS.keys():
		scrolls[sid] = bag_count(String(sid))
	materials.clear()
	for e in bag:
		var id: String = String(e.get("id", ""))
		var def := item_def(id)
		if String(def.get("kind", "")) == "material":
			materials[String(def.get("name", id))] = int(e.get("count", 1))


func _occupancy() -> Array:
	## BAG_H rows of BAG_W ints: -1 empty, else bag index.
	var grid: Array = []
	for _y in BAG_H:
		var row: Array = []
		row.resize(BAG_W)
		row.fill(-1)
		grid.append(row)
	for i in bag.size():
		var e: Dictionary = bag[i]
		var cells := item_cells(String(e.get("id", "")))
		var ox: int = int(e.get("x", 0))
		var oy: int = int(e.get("y", 0))
		for dy in cells.y:
			for dx in cells.x:
				var cx: int = ox + dx
				var cy: int = oy + dy
				if cx >= 0 and cy >= 0 and cx < BAG_W and cy < BAG_H:
					grid[cy][cx] = i
	return grid


func can_fit(item_id: String, count: int = 1) -> bool:
	var def := item_def(item_id)
	if bool(def.get("stackable", false)):
		for e in bag:
			if String(e.get("id", "")) == item_id:
				return true
	return _find_free_origin(item_id) != Vector2i(-1, -1) or count <= 0


func _find_free_origin(item_id: String) -> Vector2i:
	var cells := item_cells(item_id)
	var grid := _occupancy()
	for y in BAG_H - cells.y + 1:
		for x in BAG_W - cells.x + 1:
			var ok := true
			for dy in cells.y:
				for dx in cells.x:
					if int(grid[y + dy][x + dx]) != -1:
						ok = false
						break
				if not ok:
					break
			if ok:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Add to bag. Returns false if there is no space (and nothing was added).
func try_add_to_bag(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return true
	if not ITEM_DEFS.has(item_id) and not item_id.begins_with("mat_"):
		# Unknown ids still get a 1×1 junk stub so drops never vanish.
		pass
	var def := item_def(item_id)
	if bool(def.get("stackable", false)):
		for e in bag:
			if String(e.get("id", "")) == item_id:
				e["count"] = int(e.get("count", 1)) + count
				_resync_derived_counts()
				inventory_changed.emit()
				if item_id == "health_potion" or item_id == "mana_potion":
					potions_changed.emit()
				return true
	var origin := _find_free_origin(item_id)
	if origin.x < 0:
		return false
	bag.append({"id": item_id, "count": count, "x": origin.x, "y": origin.y})
	_resync_derived_counts()
	inventory_changed.emit()
	if item_id == "health_potion" or item_id == "mana_potion":
		potions_changed.emit()
	return true


func remove_bag_entry(index: int, amount: int = -1) -> bool:
	if index < 0 or index >= bag.size():
		return false
	var e: Dictionary = bag[index]
	var have: int = int(e.get("count", 1))
	if amount < 0 or amount >= have:
		bag.remove_at(index)
	else:
		e["count"] = have - amount
	_resync_derived_counts()
	inventory_changed.emit()
	potions_changed.emit()
	return true


func remove_one_from_bag(item_id: String) -> bool:
	for i in bag.size():
		if String(bag[i].get("id", "")) == item_id:
			return remove_bag_entry(i, 1)
	return false


## Sell one bag entry (or `amount` from a stack) to a merchant. Returns gold gained.
func sell_bag_entry(index: int, amount: int = 1) -> int:
	if index < 0 or index >= bag.size():
		return 0
	var e: Dictionary = bag[index]
	var id: String = String(e.get("id", ""))
	var have: int = int(e.get("count", 1))
	var n: int = clampi(amount, 1, have)
	var gained: int = item_sell_price(id) * n
	remove_bag_entry(index, n)
	# add_gold applies empire gold_mult — selling should be flat vendor cash.
	gold += gained
	gold_changed.emit(gold)
	return gained


# ── Equipment (paperdoll panoply) ────────────────────────────────────────

## Hover / detail text: name, description, wear slot, ATK/DEF/HP bonuses, sell.
func item_tooltip_text(item_id: String) -> String:
	if item_id == "":
		return ""
	var def := item_def(item_id)
	var lines: PackedStringArray = []
	lines.append(str(def.get("name", item_id)))
	var desc := str(def.get("desc", "")).strip_edges()
	if desc != "":
		lines.append(desc)
	var kind := str(def.get("kind", ""))
	var slot := slot_for_kind(kind)
	if slot != "":
		lines.append("Slot: %s" % slot.capitalize())
	var bonus := _equip_bonus_for(item_id)
	var bits: PackedStringArray = []
	if float(bonus.get("atk", 0.0)) != 0.0:
		bits.append("ATK +%d" % int(bonus["atk"]))
	if float(bonus.get("def", 0.0)) != 0.0:
		bits.append("DEF +%d" % int(bonus["def"]))
	if float(bonus.get("hp", 0.0)) != 0.0:
		bits.append("HP +%d" % int(bonus["hp"]))
	if not bits.is_empty():
		lines.append(" · ".join(bits))
	var min_lv := int(def.get("min_level", 0))
	if min_lv > 1:
		lines.append("Requires level %d" % min_lv)
	var sell := item_sell_price(item_id)
	if sell > 0:
		lines.append("Sell: %d δ" % sell)
	return "\n".join(lines)


func slot_for_kind(kind: String) -> String:
	match kind:
		"helmet":
			return "helmet"
		"armor":
			return "armor"
		"weapon":
			return "weapon"
		"shield":
			return "shield"
		"boots":
			return "boots"
		"necklace":
			return "necklace"
		"earring":
			return "earring"
		"bracelet":
			return "bracelet"
		_:
			return ""


func _equip_bonus_for(item_id: String) -> Dictionary:
	var def := item_def(item_id)
	var atk := float(def.get("atk", 0))
	var defense := float(def.get("def", 0))
	var hp := float(def.get("hp", 0))
	if atk == 0.0 and defense == 0.0 and hp == 0.0:
		match String(def.get("kind", "")):
			"weapon":
				atk = 4.0 + float(def.get("sell", 40)) * 0.02
			"shield":
				defense = 6.0
			"helmet":
				defense = 3.0
				hp = 8.0
			"armor":
				defense = 5.0
				hp = 16.0
			"boots":
				defense = 2.0
				hp = 6.0
			"necklace":
				hp = 10.0
				atk = 1.0
			"earring":
				atk = 2.0
			"bracelet":
				defense = 2.0
	return {"atk": atk, "def": defense, "hp": hp}


func _equip_stat(stat: String) -> float:
	var total := 0.0
	for slot in equipped.keys():
		var id: String = String(equipped[slot])
		if id == "":
			continue
		total += float(_equip_bonus_for(id).get(stat, 0.0))
	return total


## Equip a bag entry into its natural panoply slot. Returns false if not gear / cannot swap.
func equip_from_bag(index: int) -> bool:
	if index < 0 or index >= bag.size():
		return false
	var e: Dictionary = bag[index]
	var id: String = String(e.get("id", ""))
	var def := item_def(id)
	var slot: String = slot_for_kind(String(def.get("kind", "")))
	if slot == "":
		return false
	return equip_from_bag_to_slot(index, slot)


## Equip into a specific paperdoll slot (drag-and-drop). Slot must match item kind.
func equip_from_bag_to_slot(index: int, slot: String) -> bool:
	if index < 0 or index >= bag.size():
		return false
	if not equipped.has(slot):
		return false
	var e: Dictionary = bag[index]
	var id: String = String(e.get("id", ""))
	var def := item_def(id)
	var want: String = slot_for_kind(String(def.get("kind", "")))
	if want == "" or want != slot:
		return false
	var previous: String = String(equipped.get(slot, ""))
	if not remove_bag_entry(index, 1):
		return false
	if previous != "":
		if not try_add_to_bag(previous, 1):
			try_add_to_bag(id, 1)
			return false
	equipped[slot] = id
	inventory_changed.emit()
	stats_changed.emit()
	return true


func unequip_slot(slot: String) -> bool:
	if not equipped.has(slot):
		return false
	var id: String = String(equipped[slot])
	if id == "":
		return false
	if not try_add_to_bag(id, 1):
		return false
	equipped[slot] = ""
	inventory_changed.emit()
	stats_changed.emit()
	return true


func equipped_name(slot: String) -> String:
	var id: String = String(equipped.get(slot, ""))
	if id == "":
		return "—"
	return item_name(id)


## GLB path for a worn slot (or "" if empty / no mesh). Maps "sidearm" → weapon.
func equipped_glb(slot: String) -> String:
	var key := slot
	if key == "sidearm":
		key = "weapon"
	var id: String = String(equipped.get(key, ""))
	if id == "":
		return ""
	return String(item_def(id).get("glb", ""))


## Icon texture path for an item id (fallback by kind).
func item_icon_path(item_id: String) -> String:
	if item_id == "gold_coin" or item_id.begins_with("gold_"):
		return "res://assets/ui/icon_gold.png"
	var def := item_def(item_id)
	var icon := String(def.get("icon", ""))
	if icon != "" and ResourceLoader.exists(icon):
		return icon
	match String(def.get("kind", "")):
		"weapon":
			return "res://assets/ui/icon_sword.png"
		"shield":
			return "res://assets/ui/icon_shield.png"
		"helmet", "armor", "boots":
			return "res://assets/ui/icon_boot.png"
		"necklace", "earring":
			return "res://assets/ui/icon_gem.png"
		"bracelet":
			return "res://assets/ui/icon_anvil.png"
		"consumable":
			return "res://assets/ui/icon_potion.png"
		"scroll":
			return "res://assets/ui/icon_scroll.png"
		"material":
			return "res://assets/ui/icon_skull.png"
		"gold":
			return "res://assets/ui/icon_gold.png"
		_:
			return "res://assets/ui/icon_laurel.png"


func add_material(mat: String, count: int = 1) -> void:
	var item_id: String = String(MATERIAL_ITEM.get(mat, ""))
	if item_id == "":
		# Fallback synthetic id keeps unknown mats usable.
		item_id = "mat_" + mat.to_lower().replace(" ", "_")
	if not try_add_to_bag(item_id, count):
		# Bag full: keep legacy dict so nothing is lost forever.
		materials[mat] = materials.get(mat, 0) + count
		inventory_changed.emit()


func material_item_id(mat_name: String) -> String:
	return String(MATERIAL_ITEM.get(mat_name, ""))


func buy_item(item_id: String) -> bool:
	var item: Dictionary = SHOP_ITEMS.get(item_id, {})
	if item.is_empty():
		return false
	if not can_fit(item_id):
		return false
	if not spend_gold(item["price"]):
		return false
	if not try_add_to_bag(item_id):
		# Extremely unlikely after can_fit; refund.
		add_gold(item["price"])
		return false
	return true


func use_health_potion() -> bool:
	if not remove_one_from_bag("health_potion"):
		return false
	potions_changed.emit()
	return true


func use_mana_potion() -> bool:
	if not remove_one_from_bag("mana_potion"):
		return false
	potions_changed.emit()
	return true


## Roll a gear drop id for a foe of `enemy_level`, or "" on a miss.
func roll_loot_drop(chance: float = 0.28, boss: bool = false, enemy_level: int = 1) -> String:
	var c := chance * (1.55 if boss else 1.0)
	if randf() > clampf(c, 0.0, 0.92):
		return ""
	var lvl := maxi(enemy_level, 1)
	var pool: Array = []
	var total := 0.0
	for row in LOOT_TABLE:
		var need := int(row.get("min_level", 1))
		# Allow slightly above the foe's level only for bosses.
		if need > lvl + (2 if boss else 0):
			continue
		# Prefer gear near the foe's level (Metin2-ish relevance).
		var w := float(row.get("weight", 1))
		var dist := absf(float(need) - float(lvl))
		w *= clampf(1.35 - dist * 0.18, 0.35, 1.35)
		pool.append({"id": row.get("id", ""), "weight": w})
		total += w
	if total <= 0.0 or pool.is_empty():
		return ""
	var pick := randf() * total
	var acc := 0.0
	for row in pool:
		acc += float(row.get("weight", 1))
		if pick <= acc:
			return String(row.get("id", ""))
	return String(pool.back().get("id", ""))


## Gold amount scaled by foe level (empire gold_mult applied by add_gold).
func roll_gold_drop(base_min: int, base_max: int, enemy_level: int = 1) -> int:
	var lvl := maxi(enemy_level, 1)
	var lo := maxi(1, int(float(base_min) * (1.0 + float(lvl) * 0.1)))
	var hi := maxi(lo, int(float(base_max) * (1.0 + float(lvl) * 0.12)))
	return randi_range(lo, hi)

# ── Tempering (Hephaestus's forge gamble) ───────────────────────────────────────
## Returns a Dictionary: {success, destroyed, downgraded, new_level, message}
func refine_weapon(scroll_id: String) -> Dictionary:
	if weapon_refine >= REFINE_MAX:
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "Already at +%d perfection." % REFINE_MAX}
	if bag_count(scroll_id) <= 0:
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "You lack the required scroll."}
	var cost: int = REFINE_GOLD_COST[weapon_refine]
	if gold < cost:
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "Not enough gold (%d needed)." % cost}

	if not remove_one_from_bag(scroll_id):
		return {"success": false, "destroyed": false, "downgraded": false,
			"new_level": weapon_refine, "message": "You lack the required scroll."}
	spend_gold(cost)

	var rate: float = REFINE_BASE_RATES[weapon_refine]
	var protected := false
	match scroll_id:
		"titan":
			rate = 0.75
		"oracle":
			protected = true

	var roll := randf()
	var result := {"success": false, "destroyed": false, "downgraded": false,
		"new_level": weapon_refine, "message": ""}

	if roll <= rate:
		weapon_refine += 1
		result["success"] = true
		result["new_level"] = weapon_refine
		result["message"] = "Success! Your weapon is now +%d." % weapon_refine
		AudioManager.play_sfx("refine_success")
	else:
		if protected:
			result["message"] = "The forge rejects it — but the Oracle's ward holds. No harm done."
		elif weapon_refine >= 7:
			# High-tier failure can destroy (classic forge-ruin tension).
			if randf() < 0.30:
				weapon_refine = 0
				result["destroyed"] = true
				result["message"] = "The weapon SHATTERS under the hammer! The gods demand a new one."
			else:
				weapon_refine -= 1
				result["downgraded"] = true
				result["message"] = "Failure! The weapon weakens to +%d." % weapon_refine
		elif weapon_refine >= 4:
			weapon_refine -= 1
			result["downgraded"] = true
			result["message"] = "Failure! The weapon slips back to +%d." % weapon_refine
		else:
			result["message"] = "Failure! The weapon holds at +%d." % weapon_refine
		result["new_level"] = weapon_refine
		AudioManager.play_sfx("refine_fail")

	weapon_refined.emit(weapon_refine)
	inventory_changed.emit()
	return result

# ── Quests ───────────────────────────────────────────────────────────────
const QUESTS := [
	{
		"id": "wolves",
		"title": "Beasts at the Border",
		"brief": "Wolves and boars press the farms. Thin them out.",
		"kills": {"wolf_enemy": 4, "boar_enemy": 3},
		"reward_gold": 120, "reward_xp": 90,
		"turn_in": "The farms breathe again. Sparta — no, all Hellas — thanks you.",
	},
	{
		"id": "wilds",
		"title": "Silence the Wilds",
		"brief": "Satyrs raid the vineyards and harpies foul the cliffs.",
		"kills": {"satyr_enemy": 4, "harpy_enemy": 3},
		"reward_gold": 220, "reward_xp": 200,
		"turn_in": "The songs of the wild grow quieter. Well struck.",
	},
	{
		"id": "stones",
		"title": "Shatter the Curse",
		"brief": "Three cursed Omphaloi poison the land. Destroy them all.",
		"stones": 3,
		"reward_gold": 350, "reward_xp": 380,
		"turn_in": "The whispers fade. But something ancient stirs below...",
	},
	{
		"id": "elites",
		"title": "Heroes of Old",
		"brief": "Centaurs and a gorgon guard the path to the Labyrinth.",
		"kills": {"centaur_enemy": 3, "gorgon_enemy": 2},
		"reward_gold": 500, "reward_xp": 600,
		"turn_in": "The way stands open. The Labyrinth awaits, champion.",
	},
	{
		"id": "minotaur",
		"title": "The Labyrinth",
		"brief": "Enter the arena and slay the Minotaur. End the curse at its root.",
		"boss": true,
		"reward_gold": 1000, "reward_xp": 1500,
		"turn_in": "The beast is felled. Olympus itself sings your name!",
	},
]

func current_quest() -> Dictionary:
	if quest_index >= QUESTS.size():
		return {}
	return QUESTS[quest_index]

func quest_progress_text() -> String:
	var q := current_quest()
	if q.is_empty():
		return "All trials complete. Legend achieved."
	var lines: Array[String] = [q["title"]]
	if q.has("kills"):
		for enemy_id in q["kills"]:
			var need: int = q["kills"][enemy_id]
			var have: int = quest_kills.get(enemy_id, 0)
			lines.append("  %s: %d/%d" % [prettify_enemy(enemy_id), mini(have, need), need])
	if q.has("stones"):
		lines.append("  Omphaloi: %d/3" % mini(omphaloi_destroyed, 3))
	if q.has("boss"):
		lines.append("  Minotaur: %s" % ("slain" if minotaur_slain else "alive"))
	return "\n".join(lines)

func prettify_enemy(enemy_id: String) -> String:
	return enemy_id.replace("_enemy", "").capitalize()

func register_kill(enemy_id: String) -> void:
	quest_kills[enemy_id] = quest_kills.get(enemy_id, 0) + 1
	_check_quest_completion()

func register_stone_destroyed() -> void:
	omphaloi_destroyed += 1
	_check_quest_completion()

func register_minotaur_kill() -> void:
	minotaur_slain = true
	_check_quest_completion()

func _check_quest_completion() -> void:
	var q := current_quest()
	if q.is_empty():
		return
	var done := true
	if q.has("kills"):
		for enemy_id in q["kills"]:
			if quest_kills.get(enemy_id, 0) < q["kills"][enemy_id]:
				done = false
	if q.has("stones") and omphaloi_destroyed < q["stones"]:
		done = false
	if q.has("boss") and not minotaur_slain:
		done = false
	if done:
		quest_advanced.emit(q["id"], quest_index)

## Called by the priestess when turning in a finished quest.
func turn_in_quest() -> bool:
	var q := current_quest()
	if q.is_empty():
		return false
	add_gold(q["reward_gold"])
	add_xp(q["reward_xp"])
	quest_index += 1
	quest_kills = {}
	quest_advanced.emit(current_quest().get("id", ""), quest_index)
	stats_changed.emit()
	return true

func is_quest_objective_done() -> bool:
	var q := current_quest()
	if q.is_empty():
		return false
	if q.has("kills"):
		for enemy_id in q["kills"]:
			if quest_kills.get(enemy_id, 0) < q["kills"][enemy_id]:
				return false
	if q.has("stones") and omphaloi_destroyed < q["stones"]:
		return false
	if q.has("boss") and not minotaur_slain:
		return false
	return true
